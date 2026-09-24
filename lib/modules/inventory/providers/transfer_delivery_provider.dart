import 'package:flutter/material.dart';
import 'package:sigo_app/modules/inventory/models/employee_result.dart';
import 'package:sigo_app/modules/inventory/models/transfer_asset_model.dart';
import 'package:sigo_app/modules/inventory/models/transfer_request.dart';
import 'package:sigo_app/exceptions/transfer_business_exception.dart';
import 'package:sigo_app/modules/inventory/repositories/transfer_repository.dart';
import 'package:sigo_app/modules/inventory/repositories/catalog_repository.dart';
import 'package:sigo_app/utils/dialog_utils.dart';

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
    } on TransferBusinessException catch (e) {
      _error = e.message;
      _technicalDetails = e.technicalDetails;
      _statusCode = e.statusCode;
    } catch (e) {
      _error = DialogUtils.extractFriendlyMessage(e.toString().replaceAll('Exception: ', ''));
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
        .expand((t) => [t.codigoFuente, t.codigoDestino])
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty && p != 'Sin responsable')
        .toSet();

    final pairsToFetch = <(String, String, String?)>{};
    for (final t in list) {
      final src = t.codigoFuente.trim();
      final bod = t.bodegaActual.trim();
      final emp = t.empresaDocumento;
      if (src.isNotEmpty &&
          src != 'Sin responsable' &&
          bod.isNotEmpty &&
          bod != 'BOD-ORIGEN' &&
          bod != 'Sin bodega') {
        pairsToFetch.add((src, bod, emp));
      }
    }

    await Future.wait([
      ...uniquePersons.map((person) => _resolvePersonName(person)),
      ...pairsToFetch.map((pair) => _resolvePersonAssets(
            pair.$1,
            bodega: pair.$2,
            empresa: pair.$3,
          )),
    ]);

    final enrichedList = <TransferRequest>[];
    for (final transfer in list) {
      final srcCode = transfer.codigoFuente;
      final destCode = transfer.codigoDestino;

      final resolvedFuente =
          _personsNameCache[srcCode] ?? transfer.responsableActual;
      final resolvedDestino =
          _personsNameCache[destCode] ?? transfer.responsablePropuesto;

      final sourceAssets = _assetsByPersonCache['$srcCode:${transfer.bodegaActual.trim()}'] ??
          _assetsByPersonCache[srcCode] ??
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
          responsableActual: resolvedFuente,
          responsablePropuesto: resolvedDestino,
          personaFuente: transfer.personaFuente,
          personaDestino: transfer.personaDestino,
          articulos: enrichedArticulos,
        ),
      );
    }

    return enrichedList;
  }

  Future<String?> _resolvePersonName(String personQuery) async {
    final clean = personQuery.trim();
    if (clean.isEmpty || clean == 'Sin responsable') return null;

    if (_personsNameCache.containsKey(clean)) {
      return _personsNameCache[clean];
    }
    if (catalogRepository == null) {
      return null;
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

    return null;
  }

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

  /// Retorna los traspasos asignados al usuario (como fuente o destino)
  ///
  /// Permite filtrar por [userIdentifier] (ej. cédula) y opcionalmente
  /// un [secondaryIdentifier] (ej. username de red).
  List<TransferRequest> getAssignedTransfers([
    String? userIdentifier,
    String? secondaryIdentifier,
  ]) {
    final identifiers = <String>[
      if (userIdentifier != null && userIdentifier.trim().isNotEmpty)
        userIdentifier.trim().toLowerCase(),
      if (secondaryIdentifier != null && secondaryIdentifier.trim().isNotEmpty)
        secondaryIdentifier.trim().toLowerCase(),
    ];

    return _transfers.where((t) {
      // Mostramos los que están en estado aprobado ('ap')
      if (t.estado != TransferStatus.approved &&
          t.estado != TransferStatus.sourceSigned &&
          t.estado != TransferStatus.targetSigned) {
        return false;
      }

      // Si no se especifica ningún identificador, mostramos todos
      if (identifiers.isEmpty) {
        return true;
      }

      for (final query in identifiers) {
        // Cotejar contra código original o cédula
        final matchFuenteCode = t.codigoFuente.toLowerCase().contains(query) ||
            (t.personaFuente != null &&
                t.personaFuente!.toLowerCase().contains(query));
        final matchDestinoCode = t.codigoDestino.toLowerCase().contains(query) ||
            (t.personaDestino != null &&
                t.personaDestino!.toLowerCase().contains(query));

        // Cotejar contra nombre completo enriquecido
        final matchFuenteText =
            t.responsableActual.toLowerCase().contains(query);
        final matchDestinoText =
            t.responsablePropuesto.toLowerCase().contains(query);

        if (matchFuenteCode ||
            matchDestinoCode ||
            matchFuenteText ||
            matchDestinoText) {
          return true;
        }
      }

      return false;
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
    } on TransferBusinessException catch (e) {
      _error = e.message;
      _technicalDetails = e.technicalDetails ?? e.toString();
      _statusCode = e.statusCode;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = DialogUtils.extractFriendlyMessage(e.toString().replaceAll('Exception: ', ''));
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
    } on TransferBusinessException catch (e) {
      _error = e.message;
      _technicalDetails = e.technicalDetails ?? e.toString();
      _statusCode = e.statusCode;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = DialogUtils.extractFriendlyMessage(e.toString().replaceAll('Exception: ', ''));
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
