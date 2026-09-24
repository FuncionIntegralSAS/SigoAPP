import 'dart:convert';
import 'package:sigo_app/modules/inventory/models/transfer_request.dart';
import 'package:sigo_app/modules/inventory/models/transfer_create_request.dart';
import 'package:sigo_app/modules/inventory/models/transfer_delivery_request.dart';
import 'package:sigo_app/modules/inventory/models/transfer_person_model.dart';
import 'package:sigo_app/modules/inventory/models/transfer_asset_model.dart';
import 'package:sigo_app/modules/inventory/repositories/transfer_repository.dart';
import 'package:sigo_app/services/mock_inventory_service.dart';
import 'package:sigo_app/utils/app_logger.dart';

/// Implementación mock del [TransferRepository].
///
/// Utiliza [MockInventoryService] como fuente de datos en memoria
/// para desarrollo y pruebas offline.
class MockTransferRepository implements TransferRepository {
  final MockInventoryService inventoryService;

  MockTransferRepository(this.inventoryService);

  // ============================
  // CREAR SOLICITUD
  // ============================

  @override
  Future<void> create(dynamic request) async {
    if (request is TransferCreateRequest) {
      final prettyPayload =
          const JsonEncoder.withIndent('  ').convert(request.toJson());
      AppLogger.i('MockTransferRepository.create payload:\n$prettyPayload');
    }

    if (request is TransferRequest) {
      inventoryService.createTransferRequest(_sanitizeMockTransfer(request));
    } else if (request is TransferCreateRequest) {
      // Consultar bodegas asociadas a personaFuente y personaDestino
      String resolvedBodegaOrigen = '';
      final fuenteWarehouses =
          inventoryService.getWarehousesForResponsible(request.personaFuente);
      if (fuenteWarehouses.isNotEmpty) {
        final w = fuenteWarehouses.first;
        resolvedBodegaOrigen = w.descripcionBodega.isNotEmpty
            ? '${w.codigoBodega} - ${w.descripcionBodega}'
            : w.codigoBodega;
      } else if (request.articulos.isNotEmpty) {
        try {
          final matchArticle = inventoryService
              .getArticles()
              .firstWhere((a) => a.codigoActivo == request.articulos.first.articulo);
          resolvedBodegaOrigen = matchArticle.bodega;
        } catch (_) {}
      }
      if (resolvedBodegaOrigen.isEmpty) {
        resolvedBodegaOrigen = 'BOG001 - Almacén Central';
      }

      String resolvedBodegaDestino = '';
      final destinoWarehouses =
          inventoryService.getWarehousesForResponsible(request.personaDestino);
      if (destinoWarehouses.isNotEmpty) {
        final w = destinoWarehouses.first;
        resolvedBodegaDestino = w.descripcionBodega.isNotEmpty
            ? '${w.codigoBodega} - ${w.descripcionBodega}'
            : w.codigoBodega;
      }
      if (resolvedBodegaDestino.isEmpty) {
        resolvedBodegaDestino = 'MED002 - Taller de Mantenimiento';
      }

      final transfer = TransferRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        responsableActual: request.personaFuente,
        responsablePropuesto: request.personaDestino,
        motivoSolicitud: request.observacion,
        fechaSolicitud: DateTime.now(),
        bodegaActual: resolvedBodegaOrigen,
        bodegaPropuesta: resolvedBodegaDestino,
        articulos: request.articulos,
        placa: request.articulos.isNotEmpty ? request.articulos.first.placa : null,
      );
      inventoryService.createTransferRequest(transfer);
    }
  }

  // ============================
  // OBTENER TODAS
  // ============================

  @override
  Future<List<TransferRequest>> getAllTransfers({
    String? estado,
    String? empresa,
    String? bodega,
    bool fetchDetails = true,
  }) async {
    var list = inventoryService.transferRequests.map(_sanitizeMockTransfer).toList();
    if (estado != null && estado.isNotEmpty) {
      list = list.where((t) {
        if (estado == 'pe') return t.estado == TransferStatus.pending;
        if (estado == 'ap') return t.estado == TransferStatus.approved;
        if (estado == 'na') return t.estado == TransferStatus.rejected;
        if (estado == 're') return t.estado == TransferStatus.received;
        if (estado == 'pr') return t.estado != TransferStatus.pending;
        if (estado == 'af') return t.estado == TransferStatus.sourceSigned;
        if (estado == 'ad') return t.estado == TransferStatus.targetSigned;
        return true;
      }).toList();
    }
    return list;
  }

  // ============================
  // DETALLE POR ID
  // ============================

  @override
  Future<TransferRequest?> getTransferById(String id) async {
    final list = inventoryService.transferRequests;
    try {
      final item = list.firstWhere((t) => t.id == id);
      return _sanitizeMockTransfer(item);
    } catch (_) {
      return null;
    }
  }

  static const Map<String, String> _mockEmployeeNames = {
    '123': 'Carlos Rodríguez (123)',
    '456': 'María González (456)',
    '789': 'Juan Pérez (789)',
    '101': 'Carlos Gómez (101)',
    '1098765432': 'Juan Camilo Díaz (1098765432)',
    '1012345678': 'Andrés Felipe Restrepo (1012345678)',
  };

  static const Map<String, String> _mockArticleNames = {
    '100450': 'COMPUTADOR PORTATIL LENOVO THINKPAD',
    '100451': 'MONITOR DELL 24 PULGADAS',
    '100452': 'TECLADO Y MOUSE INALAMBRICO LOGITECH',
    '100453': 'IMPRESORA MULTIFUNCIONAL EPSON',
    '100454': 'SILLA ERGONOMICA EJECUTIVA',
    'ELEM-00451': 'COMPUTADOR PORTATIL LENOVO THINKPAD',
    'ELEM-00452': 'MONITOR DELL 24 PULGADAS',
    'PC001': 'Portátil Prueba',
    'A1002': 'Rack de Paletas P-20',
    'A1003': 'Mesa de Trabajo',
    'A2001': 'Compresor Industrial',
    'A2002': 'Herramienta Neumática',
  };

  TransferRequest _sanitizeMockTransfer(TransferRequest t) {
    var updated = t;
    if (updated.bodegaActual == 'BOD-ORIGEN' || updated.bodegaActual.trim().isEmpty) {
      final fuenteWarehouses =
          inventoryService.getWarehousesForResponsible(updated.responsableActual);
      String realBodega = '';
      if (fuenteWarehouses.isNotEmpty) {
        final w = fuenteWarehouses.first;
        realBodega = w.descripcionBodega.isNotEmpty
            ? '${w.codigoBodega} - ${w.descripcionBodega}'
            : w.codigoBodega;
      } else if (updated.articulos.isNotEmpty) {
        try {
          final art = inventoryService
              .getArticles()
              .firstWhere((a) => a.codigoActivo == updated.articulos.first.articulo);
          realBodega = art.bodega;
        } catch (_) {}
      }
      if (realBodega.isEmpty) realBodega = 'BOG001 - Almacén Central';
      updated = updated.copyWith(bodegaActual: realBodega);
    }
    if (updated.bodegaPropuesta == 'BOD-DESTINO' || updated.bodegaPropuesta.trim().isEmpty) {
      final destinoWarehouses =
          inventoryService.getWarehousesForResponsible(updated.responsablePropuesto);
      String realBodega = '';
      if (destinoWarehouses.isNotEmpty) {
        final w = destinoWarehouses.first;
        realBodega = w.descripcionBodega.isNotEmpty
            ? '${w.codigoBodega} - ${w.descripcionBodega}'
            : w.codigoBodega;
      }
      if (realBodega.isEmpty) realBodega = 'MED002 - Taller de Mantenimiento';
      updated = updated.copyWith(bodegaPropuesta: realBodega);
    }

    final sanitizedArticulos = updated.articulos.map((art) {
      if (art.nombre != null && art.nombre!.trim().isNotEmpty) {
        return art;
      }
      String? desc = _mockArticleNames[art.articulo];
      if (desc == null) {
        try {
          final found = inventoryService
              .getArticles()
              .firstWhere((a) => a.codigoActivo == art.articulo);
          desc = found.nombre;
        } catch (_) {}
      }
      if (desc != null && desc.isNotEmpty) {
        return art.copyWith(nombre: desc);
      }
      return art;
    }).toList();

    String respActual = updated.responsableActual;
    if (_mockEmployeeNames.containsKey(respActual.trim())) {
      respActual = _mockEmployeeNames[respActual.trim()]!;
    }
    String respPropuesto = updated.responsablePropuesto;
    if (_mockEmployeeNames.containsKey(respPropuesto.trim())) {
      respPropuesto = _mockEmployeeNames[respPropuesto.trim()]!;
    }

    updated = updated.copyWith(
      responsableActual: respActual,
      responsablePropuesto: respPropuesto,
      articulos: sanitizedArticulos,
    );

    return updated;
  }

  // ============================
  // APROBAR
  // ============================

  @override
  Future<void> approveTransfer(String requestId, {String? observacion}) async {
    inventoryService.approveTransferRequest(requestId);
  }

  // ============================
  // RECHAZAR
  // ============================

  @override
  Future<void> rejectTransfer({
    required String requestId,
    required String motivoRechazo,
  }) async {
    inventoryService.rejectTransferRequest(
      requestId: requestId,
      motivoRechazo: motivoRechazo,
    );
  }

  // ============================
  // REGISTRAR FIRMA INDIVIDUAL
  // ============================

  @override
  Future<void> signTransfer({
    required String transferId,
    required String tipoFirma,
    required String firmaBase64,
  }) async {
    final index = inventoryService.transferRequests.indexWhere((t) => t.id == transferId);
    if (index != -1) {
      final transfer = inventoryService.transferRequests[index];
      final currentFirmas = List<TransferFirmItem>.from(transfer.firmas);
      final int pos = tipoFirma == 'FU' ? 1 : 2;

      // Actualizamos o añadimos la firma correspondiente
      currentFirmas.removeWhere((f) => f.tipo == tipoFirma);
      currentFirmas.add(TransferFirmItem(
        posicion: pos,
        tipo: tipoFirma,
        fechaFirma: DateTime.now(),
        firmada: true,
        firma: firmaBase64,
      ));

      if (tipoFirma == 'FU') {
        inventoryService.transferRequests[index] = transfer.copyWith(
          firmaDespachadorBase64: firmaBase64,
          firmas: currentFirmas,
        );
      } else if (tipoFirma == 'DE') {
        inventoryService.transferRequests[index] = transfer.copyWith(
          firmaReceptorBase64: firmaBase64,
          firmas: currentFirmas,
        );
      }
    }
  }

  // ============================
  // CONCRETAR RECEPCIÓN
  // ============================

  @override
  Future<void> receiveTransfer(String transferId) async {
    final index = inventoryService.transferRequests.indexWhere((t) => t.id == transferId);
    if (index != -1) {
      final transfer = inventoryService.transferRequests[index];
      inventoryService.transferRequests[index] = transfer.copyWith(
        estado: TransferStatus.received,
        fechaRecibe: DateTime.now(),
        fechaAplicacion: DateTime.now(),
      );
    }
  }

  // ============================
  // APLICAR TRASPASO
  // ============================

  @override
  Future<void> applyTransfer(TransferRequest request) async {
    inventoryService.applyApprovedTransfer(request);
  }

  // ============================
  // APLICAR ENTREGA/RECEPCIÓN
  // ============================

  @override
  Future<void> applyTransferDelivery(TransferDeliveryRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (request.firmaDespachadorBase64 != null) {
      await signTransfer(
        transferId: request.transferId,
        tipoFirma: 'FU',
        firmaBase64: request.firmaDespachadorBase64!,
      );
    }
    if (request.firmaReceptorBase64 != null) {
      await signTransfer(
        transferId: request.transferId,
        tipoFirma: 'DE',
        firmaBase64: request.firmaReceptorBase64!,
      );
      await receiveTransfer(request.transferId);
    }
  }

  // ============================
  // OBTENER PERSONAS POR BODEGA (MOCK)
  // ============================

  @override
  Future<List<TransferPersonModel>> getPersonsByWarehouse({
    required String bodega,
    required String empresa,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      const TransferPersonModel(
        cedula: 'PI26055',
        nombre: 'JUAN CAMILO',
        apellido: 'DIAZ GOMEZ',
      ),
      const TransferPersonModel(
        cedula: '1098765432',
        nombre: 'ANDRES FELIPE',
        apellido: 'ARIAS LOPEZ',
      ),
      const TransferPersonModel(
        cedula: '1012345678',
        nombre: 'CARLOS ALBERTO',
        apellido: 'RODRIGUEZ PEREZ',
      ),
      const TransferPersonModel(
        cedula: '1045678901',
        nombre: 'MARIA PAULA',
        apellido: 'GOMEZ SANCHEZ',
      ),
    ];
  }

  // ============================
  // OBTENER ACTIVOS POR RESPONSABLE (MOCK)
  // ============================

  @override
  Future<List<TransferAssetModel>> getAssetsByPerson({
    required String persona,
    required String bodega,
    String? empresa,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      const TransferAssetModel(
        articulo: '100450',
        placa: 'PLA-00981',
        nombre: 'COMPUTADOR PORTATIL LENOVO THINKPAD',
        centroInformacion: 'CI-01',
        tercero: '900123456',
        enTramite: false,
      ),
      const TransferAssetModel(
        articulo: '100451',
        placa: 'PLA-00982',
        nombre: 'MONITOR DELL 24 PULGADAS',
        centroInformacion: 'CI-01',
        tercero: '900123456',
        enTramite: true,
      ),
      const TransferAssetModel(
        articulo: '100452',
        placa: 'PLA-00983',
        nombre: 'TECLADO Y MOUSE INALAMBRICO LOGITECH',
        centroInformacion: 'CI-01',
        tercero: '900123456',
        enTramite: false,
      ),
      const TransferAssetModel(
        articulo: '100453',
        placa: 'PLA-00984',
        nombre: 'IMPRESORA MULTIFUNCIONAL EPSON',
        centroInformacion: 'CI-02',
        tercero: '900654321',
        enTramite: false,
      ),
      const TransferAssetModel(
        articulo: '100454',
        placa: 'PLA-00985',
        nombre: 'SILLA ERGONOMICA EJECUTIVA',
        centroInformacion: 'CI-01',
        tercero: '900123456',
        enTramite: false,
      ),
    ];
  }
}
