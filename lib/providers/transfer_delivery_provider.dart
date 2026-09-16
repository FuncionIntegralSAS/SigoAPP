import 'package:flutter/material.dart';
import '../models/employee_result.dart';
import '../models/transfer_asset_model.dart';
import '../models/transfer_request.dart';
import '../repositories/transfer_repository.dart';
import '../repositories/catalog_repository.dart';

class TransferDeliveryProvider extends ChangeNotifier {
  final TransferRepository repository;
  final CatalogRepository? catalogRepository;

  TransferDeliveryProvider(
    this.repository, {
    this.catalogRepository,
  });

  List<TransferRequest> _transfers = [];
  bool _loading = false;
  String? _error;
  String? _technicalDetails;
  int? _statusCode;

  final Map<String, String> _personsNameCache = {};
  final Map<String, List<TransferAssetModel>> _assetsByPersonCache = {};

  bool get loading => _loading;
  String? get error => _error;
  String? get technicalDetails => _technicalDetails;
  int? get statusCode => _statusCode;
  List<TransferRequest> get allTransfers => _transfers;

  Future<void> loadTransfers() async {
    _loading = true;
    _error = null;
    _technicalDetails = null;
    _statusCode = null;
    notifyListeners();

    try {
      // Consultamos trámites aprobados habilitados para firmas
      final rawTransfers = await repository.getAllTransfers(estado: 'ap');
      _transfers = await _enrichTransfers(rawTransfers);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _technicalDetails = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Enriquece concurrentemente las solicitudes con nombres completos de personas
  /// y descripciones de artículos.
  Future<List<TransferRequest>> _enrichTransfers(List<TransferRequest> list) async {
    if (list.isEmpty) return list;

    final uniquePersons = list
        .expand((t) => [t.responsableActual, t.responsablePropuesto])
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty && p != 'Sin responsable')
        .toSet();

    await Future.wait(uniquePersons.map((person) async {
      await Future.wait([
        _resolvePersonName(person),
        _resolvePersonAssets(person),
      ]);
    }));

    final enrichedList = <TransferRequest>[];
    for (final transfer in list) {
      final resolvedFuente =
          _personsNameCache[transfer.responsableActual.trim()] ??
              transfer.responsableActual;
      final resolvedDestino =
          _personsNameCache[transfer.responsablePropuesto.trim()] ??
              transfer.responsablePropuesto;

      final sourceAssets =
          _assetsByPersonCache[transfer.responsableActual.trim()] ?? [];
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
          responsableActual: resolvedFuente,
          responsablePropuesto: resolvedDestino,
          articulos: enrichedArticulos,
        ),
      );
    }

    return enrichedList;
  }

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
    } catch (_) {}

    _personsNameCache[clean] = clean;
    return clean;
  }

  Future<List<TransferAssetModel>> _resolvePersonAssets(String personQuery) async {
    final clean = personQuery.trim();
    if (clean.isEmpty || clean == 'Sin responsable') return [];

    if (_assetsByPersonCache.containsKey(clean)) {
      return _assetsByPersonCache[clean]!;
    }

    try {
      final assets = await repository.getAssetsByPerson(persona: clean);
      _assetsByPersonCache[clean] = assets;
      return assets;
    } catch (_) {
      _assetsByPersonCache[clean] = [];
      return [];
    }
  }

  /// Retorna los traspasos asignados al usuario (como fuente o destino)
  List<TransferRequest> getAssignedTransfers([String? userIdentifier]) {
    return _transfers.where((t) {
      // Mostramos los que están en estado aprobado ('ap')
      if (t.estado != TransferStatus.approved &&
          t.estado != TransferStatus.sourceSigned &&
          t.estado != TransferStatus.targetSigned) {
        return false;
      }

      // Si no se especifica identificador o viene vacío, mostramos todos
      if (userIdentifier == null || userIdentifier.trim().isEmpty) {
        return true;
      }

      final query = userIdentifier.trim().toLowerCase();
      return t.responsableActual.toLowerCase().contains(query) ||
          t.responsablePropuesto.toLowerCase().contains(query);
    }).toList();
  }

  /// Registra la firma manuscrita de cualquiera de las partes (sin orden requerido).
  ///
  /// Si ambas partes ya han firmado, intenta automáticamente concretar la recepción
  /// en el ERP vía [receiveTransfer].
  Future<bool> submitDelivery(
    String transferId, {
    String? dispatcherBase64,
    String? receiverBase64,
  }) async {
    _loading = true;
    _error = null;
    _technicalDetails = null;
    _statusCode = null;
    notifyListeners();

    try {
      if (dispatcherBase64 != null && dispatcherBase64.isNotEmpty) {
        await repository.signTransfer(
          transferId: transferId,
          tipoFirma: 'FU',
          firmaBase64: dispatcherBase64,
        );
      }

      if (receiverBase64 != null && receiverBase64.isNotEmpty) {
        await repository.signTransfer(
          transferId: transferId,
          tipoFirma: 'DE',
          firmaBase64: receiverBase64,
        );
      }

      // Consultamos el estado actualizado del trámite para verificar si ambas partes ya firmaron
      final updatedTransfer = await repository.getTransferById(transferId);
      if (updatedTransfer != null && updatedTransfer.bothSigned) {
        try {
          await repository.receiveTransfer(transferId);
        } catch (_) {
          // Si la recepción automática no se concreta, se deja lista para confirmar manualmente
        }
      }

      await loadTransfers();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _technicalDetails = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Concreta formalmente la recepción final del trámite en el ERP (`PUT /recibir/{id}`)
  Future<bool> confirmReceipt(String transferId) async {
    _loading = true;
    _error = null;
    _technicalDetails = null;
    _statusCode = null;
    notifyListeners();

    try {
      await repository.receiveTransfer(transferId);
      await loadTransfers();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _technicalDetails = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Limpia los datos de traspasos en memoria al cerrar sesión
  void reset() {
    _transfers = [];
    _loading = false;
    _error = null;
    _technicalDetails = null;
    _statusCode = null;
    _personsNameCache.clear();
    _assetsByPersonCache.clear();
    notifyListeners();
  }
}
