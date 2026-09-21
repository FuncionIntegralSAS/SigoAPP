import 'package:flutter/material.dart';

import '../exceptions/transfer_business_exception.dart';
import '../models/employee_result.dart';
import '../models/transfer_asset_model.dart';
import '../models/transfer_request.dart';
import '../models/transfer_filter.dart';
import '../repositories/transfer_repository.dart';
import '../repositories/catalog_repository.dart';

class TransferApprovalProvider extends ChangeNotifier {
  final TransferRepository repository;
  final CatalogRepository? catalogRepository;

  String? _currentEmpresa;
  String? _currentBodega;

  String? get currentEmpresa => _currentEmpresa;
  String? get currentBodega => _currentBodega;

  TransferApprovalProvider(
    this.repository, {
    this.catalogRepository,
    bool autoLoad = true,
  }) {
    if (autoLoad) {
      loadTransfers();
    }
  }

  // ============================
  // FILTROS
  // ============================

  TransferFilter _filter = const TransferFilter();

  TransferFilter get filter => _filter;

  void updateFilter(TransferFilter newFilter) {
    final statusChanged = newFilter.status != _filter.status;
    _filter = newFilter;
    notifyListeners();
    if (statusChanged) {
      loadTransfers();
    }
  }

  // ============================
  // FUENTE DE DATOS
  // ============================

  List<TransferRequest> _transfers = [];
  List<TransferRequest> get allTransfers => _transfers;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;
  String? _technicalDetails;
  String? get technicalDetails => _technicalDetails;
  int? _statusCode;
  int? get statusCode => _statusCode;

  final Set<String> _processingIds = {};
  bool isProcessing(String id) => _processingIds.contains(id);

  void clearError() {
    _error = null;
    _technicalDetails = null;
    _statusCode = null;
    notifyListeners();
  }

  /// Limpia todos los datos en memoria al cerrar sesión
  void reset() {
    _transfers = [];
    _currentEmpresa = null;
    _currentBodega = null;
    _filter = const TransferFilter();
    _loading = false;
    _error = null;
    _technicalDetails = null;
    _statusCode = null;
    _processingIds.clear();
    _personWarehouseCache.clear();
    _personsNameCache.clear();
    _assetsByPersonCache.clear();
    notifyListeners();
  }

  static String _statusToCode(TransferStatus status) {
    switch (status) {
      case TransferStatus.pending:
        return 'pe';
      case TransferStatus.approved:
        return 'ap';
      case TransferStatus.rejected:
        return 'na';
      case TransferStatus.sourceSigned:
        return 'af';
      case TransferStatus.targetSigned:
        return 'ad';
      case TransferStatus.received:
        return 're';
      case TransferStatus.completed:
        return 'pr';
    }
  }

  // Cachés en memoria para optimización por lote
  final Map<String, String> _personWarehouseCache = {};
  final Map<String, String> _personsNameCache = {};
  final Map<String, List<TransferAssetModel>> _assetsByPersonCache = {};

  /// Carga las solicitudes de traspaso desde el repositorio optimizando por estado.
  /// Soporta opcionalmente filtrar por [empresa] y [bodega] en la consulta al backend.
  Future<void> loadTransfers({String? empresa, String? bodega}) async {
    if (empresa != null) _currentEmpresa = empresa;
    if (bodega != null) _currentBodega = bodega;

    _loading = true;
    _error = null;
    _technicalDetails = null;
    _statusCode = null;
    notifyListeners();

    try {
      final estadoParam = _statusToCode(_filter.status);
      final rawTransfers = await repository.getAllTransfers(
        estado: estadoParam,
        empresa: empresa ?? _currentEmpresa,
        bodega: bodega ?? _currentBodega,
      );
      _transfers = await _enrichTransfers(
        rawTransfers,
        empresa: empresa ?? _currentEmpresa,
      );
    } on TransferBusinessException catch (e) {
      _error = e.message;
      _technicalDetails = e.technicalDetails;
      _statusCode = e.statusCode;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _technicalDetails = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Enriquece concurrentemente las solicitudes con nombres completos de personas,
  /// descripciones oficiales de artículos y bodegas autorizadas.
  Future<List<TransferRequest>> _enrichTransfers(
    List<TransferRequest> list, {
    String? empresa,
  }) async {
    if (list.isEmpty) return list;

    // 1. Extraer identificadores únicos de personas para evitar consultas redundantes
    final uniquePersons = list
        .expand((t) => [t.responsableActual, t.responsablePropuesto])
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty && p != 'Sin responsable')
        .toSet();

    // 2. Pre-cargar en paralelo los datos faltantes en caché para cada persona única
    await Future.wait(uniquePersons.map((person) async {
      await Future.wait([
        _resolvePersonName(person),
        _getWarehouseForPerson(person),
      ]);
    }));

    // 2b. Pre-cargar activos por responsable y bodega para enriquecer artículos
    final pairsToFetch = <(String, String)>{};
    for (final transfer in list) {
      final resp = transfer.responsableActual.trim();
      if (resp.isEmpty || resp == 'Sin responsable') continue;
      String bod = transfer.bodegaActual.trim();
      if (bod.isEmpty || bod == 'BOD-ORIGEN' || bod == 'Sin bodega') {
        bod = _personWarehouseCache[resp] ?? _currentBodega ?? '';
      }
      if (bod.isNotEmpty && bod != 'BOD-ORIGEN' && bod != 'Sin bodega') {
        pairsToFetch.add((resp, bod));
      }
    }

    await Future.wait(pairsToFetch.map((pair) => _resolvePersonAssets(
          pair.$1,
          bodega: pair.$2,
          empresa: empresa ?? _currentEmpresa,
        )));

    // 3. Mapear cada transferencia asociando bodegas, nombres resueltos y artículos enriquecidos
    final enrichedList = <TransferRequest>[];
    for (final transfer in list) {
      String resolvedBodegaOrigen = transfer.bodegaActual;
      String resolvedBodegaDestino = transfer.bodegaPropuesta;

      if (resolvedBodegaOrigen.isEmpty ||
          resolvedBodegaOrigen == 'BOD-ORIGEN' ||
          resolvedBodegaOrigen == 'Sin bodega') {
        final bodega = _personWarehouseCache[transfer.responsableActual.trim()];
        if (bodega != null && bodega.isNotEmpty) {
          resolvedBodegaOrigen = bodega;
        }
      }

      if (resolvedBodegaDestino.isEmpty ||
          resolvedBodegaDestino == 'BOD-DESTINO' ||
          resolvedBodegaDestino == 'Sin bodega') {
        final bodega = _personWarehouseCache[transfer.responsablePropuesto.trim()];
        if (bodega != null && bodega.isNotEmpty) {
          resolvedBodegaDestino = bodega;
        }
      }

      final resolvedNombreFuente =
          _personsNameCache[transfer.responsableActual.trim()] ??
              transfer.responsableActual;
      final resolvedNombreDestino =
          _personsNameCache[transfer.responsablePropuesto.trim()] ??
              transfer.responsablePropuesto;

      // Enriquecer descripción de artículos desde los activos del colaborador fuente
      final cleanResp = transfer.responsableActual.trim();
      final sourceAssets = _assetsByPersonCache['$cleanResp:$resolvedBodegaOrigen'] ??
          _assetsByPersonCache[cleanResp] ??
          [];
      final enrichedArticulos = transfer.articulos.map((art) {
        if (art.nombre != null && art.nombre!.trim().isNotEmpty) {
          return art;
        }
        if (sourceAssets.isNotEmpty) {
          try {
            final match = sourceAssets.firstWhere(
              (a) =>
                  a.articulo.trim().toLowerCase() ==
                  art.articulo.trim().toLowerCase(),
            );
            if (match.nombre.trim().isNotEmpty) {
              return art.copyWith(nombre: match.nombre.trim());
            }
          } catch (_) {}
        }
        return art;
      }).toList();

      enrichedList.add(
        transfer.copyWith(
          bodegaActual: resolvedBodegaOrigen,
          bodegaPropuesta: resolvedBodegaDestino,
          responsableActual: resolvedNombreFuente,
          responsablePropuesto: resolvedNombreDestino,
          articulos: enrichedArticulos,
        ),
      );
    }

    return enrichedList;
  }

  /// Resuelve el nombre completo de una persona formateado como "NOMBRE COMPLETO (CEDULA)".
  Future<String> _resolvePersonName(String personQuery) async {
    final clean = personQuery.trim();
    if (clean.isEmpty || clean == 'Sin responsable') return personQuery;

    if (_personsNameCache.containsKey(clean)) {
      return _personsNameCache[clean]!;
    }
    if (catalogRepository == null) {
      _personsNameCache[clean] = clean;
      return clean;
    }

    try {
      final isNumeric = RegExp(r'^\d+$').hasMatch(clean);
      List<EmployeeResult> candidates = [];
      if (isNumeric) {
        candidates = await catalogRepository!.searchEmployees(cedula: clean);
      } else {
        candidates = await catalogRepository!.searchEmployees(cedula: clean);
        if (candidates.isEmpty) {
          candidates = await catalogRepository!.searchEmployees(nombre: clean);
        }
      }

      if (candidates.isNotEmpty) {
        final emp = candidates.first;
        final fullName = emp.nombre.trim();
        if (fullName.isNotEmpty) {
          final cedula = emp.cedula?.trim() ?? clean;
          final formatted = (cedula.isNotEmpty &&
                  cedula.toLowerCase() != fullName.toLowerCase())
              ? '$fullName ($cedula)'
              : fullName;
          _personsNameCache[clean] = formatted;
          return formatted;
        }
      }
    } catch (_) {
      // Fallback tolerante si falla la red o búsqueda
    }

    _personsNameCache[clean] = clean;
    return clean;
  }

  /// Resuelve la lista de activos fijos asignados al colaborador consultado en la bodega indicada.
  Future<List<TransferAssetModel>> _resolvePersonAssets(
    String personQuery, {
    String? bodega,
    String? empresa,
  }) async {
    final clean = personQuery.trim();
    if (clean.isEmpty || clean == 'Sin responsable') return [];
    if (bodega == null ||
        bodega.trim().isEmpty ||
        bodega == 'BOD-ORIGEN' ||
        bodega == 'Sin bodega') {
      return [];
    }

    final cleanBodega = bodega.trim();
    final cacheKey = '$clean:$cleanBodega';

    if (_assetsByPersonCache.containsKey(cacheKey)) {
      return _assetsByPersonCache[cacheKey]!;
    }

    try {
      final assets = await repository.getAssetsByPerson(
        persona: clean,
        bodega: cleanBodega,
        empresa: empresa,
      );
      _assetsByPersonCache[cacheKey] = assets;
      _assetsByPersonCache[clean] ??= assets;
      return assets;
    } catch (_) {
      _assetsByPersonCache[cacheKey] = [];
      return [];
    }
  }

  Future<String?> _getWarehouseForPerson(String personQuery) async {
    final clean = personQuery.trim();
    if (clean.isEmpty || clean == 'Sin responsable') return null;

    if (_personWarehouseCache.containsKey(clean)) {
      return _personWarehouseCache[clean];
    }

    if (catalogRepository == null) return null;

    try {
      final isNumeric = RegExp(r'^\d+$').hasMatch(clean);
      List<EmployeeResult> candidates = [];
      if (isNumeric) {
        candidates = await catalogRepository!.searchEmployees(cedula: clean);
      } else {
        candidates = await catalogRepository!.searchEmployees(nombre: clean);
      }

      if (candidates.isNotEmpty) {
        final emp = candidates.first;
        if (emp.divisionId != null && emp.divisionId!.isNotEmpty) {
          final warehouses = await catalogRepository!.getWarehousesByDivision(
            emp.divisionId!,
          );
          if (warehouses.isNotEmpty) {
            final wh = warehouses.first;
            final result = wh.descripcionBodega.isNotEmpty
                ? '${wh.codigoBodega} - ${wh.descripcionBodega}'
                : wh.codigoBodega;
            _personWarehouseCache[clean] = result;
            return result;
          }
        }
      }
    } catch (_) {
      // Ignorar fallos de red puntuales para mantener resiliencia
    }
    return null;
  }

  // ============================
  // LISTA FILTRADA PARA LA UI
  // ============================

  List<TransferRequest> get filteredTransfers {
    return allTransfers.where(_applyFilter).toList();
  }

  bool _applyFilter(TransferRequest request) {
    if (_filter.status != TransferStatus.completed &&
        request.estado != _filter.status) {
      return false;
    }

    if (_filter.bodegaPropuesta != null &&
        request.bodegaPropuesta != _filter.bodegaPropuesta) {
      return false;
    }

    if (_filter.responsibleQuery != null &&
        _filter.responsibleQuery!.trim().isNotEmpty) {
      final query = _filter.responsibleQuery!.trim().toLowerCase();
      final matchesPropuesto = request.responsablePropuesto
          .toLowerCase()
          .contains(query);
      final matchesActual = request.responsableActual.toLowerCase().contains(
        query,
      );
      if (!matchesPropuesto && !matchesActual) {
        return false;
      }
    }

    if (_filter.fromDate != null) {
      final from = DateTime(
        _filter.fromDate!.year,
        _filter.fromDate!.month,
        _filter.fromDate!.day,
      );
      final reqDate = DateTime(
        request.fechaSolicitud.year,
        request.fechaSolicitud.month,
        request.fechaSolicitud.day,
      );
      if (reqDate.isBefore(from)) {
        return false;
      }
    }

    if (_filter.toDate != null) {
      final to = DateTime(
        _filter.toDate!.year,
        _filter.toDate!.month,
        _filter.toDate!.day,
        23,
        59,
        59,
      );
      if (request.fechaSolicitud.isAfter(to)) {
        return false;
      }
    }

    return true;
  }

  // ============================
  // BODEGAS DISPONIBLES
  // ============================

  List<String> get availableWarehouses {
    return allTransfers.map((r) => r.bodegaPropuesta).toSet().toList()..sort();
  }

  // ============================
  // APROBAR SOLICITUD
  // ============================

  Future<bool> approveTransfer(String requestId) async {
    _processingIds.add(requestId);
    _error = null;
    _technicalDetails = null;
    _statusCode = null;
    notifyListeners();

    try {
      await repository.approveTransfer(requestId);
      await loadTransfers();
      return true;
    } on TransferBusinessException catch (e) {
      _error = e.message;
      _technicalDetails = e.technicalDetails;
      _statusCode = e.statusCode;
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _technicalDetails = e.toString();
      return false;
    } finally {
      _processingIds.remove(requestId);
      notifyListeners();
    }
  }

  // ============================
  // RECHAZAR SOLICITUD
  // ============================

  Future<bool> rejectTransfer(String requestId, String reason) async {
    _processingIds.add(requestId);
    _error = null;
    _technicalDetails = null;
    _statusCode = null;
    notifyListeners();

    try {
      await repository.rejectTransfer(
        requestId: requestId,
        motivoRechazo: reason,
      );
      await loadTransfers();
      return true;
    } on TransferBusinessException catch (e) {
      _error = e.message;
      _technicalDetails = e.technicalDetails;
      _statusCode = e.statusCode;
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _technicalDetails = e.toString();
      return false;
    } finally {
      _processingIds.remove(requestId);
      notifyListeners();
    }
  }

  // ============================
  // APLICAR TRASPASO
  // ============================

  Future<void> applyTransfer(TransferRequest request) async {
    try {
      await repository.applyTransfer(request);
      await loadTransfers();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ============================
  // UTILIDAD
  // ============================

  void refresh() {
    loadTransfers();
  }
}
