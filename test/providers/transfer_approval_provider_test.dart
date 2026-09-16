import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/exceptions/transfer_business_exception.dart';
import 'package:sigo_app/models/transfer_filter.dart';
import 'package:sigo_app/models/transfer_request.dart';
import 'package:sigo_app/providers/transfer_approval_provider.dart';
import 'package:sigo_app/repositories/mock_catalog_repository.dart';
import 'package:sigo_app/repositories/mock_transfer_repository.dart';
import 'package:sigo_app/services/mock_inventory_service.dart';

class ConfigurableMockTransferRepository extends MockTransferRepository {
  bool shouldFailApprove = false;
  bool shouldFailReject = false;
  String? lastQueriedEstado;
  String? lastQueriedEmpresa;
  String? lastQueriedBodega;

  ConfigurableMockTransferRepository(super.service);

  @override
  Future<List<TransferRequest>> getAllTransfers({
    String? estado,
    String? empresa,
    String? bodega,
    bool fetchDetails = true,
  }) async {
    lastQueriedEstado = estado;
    lastQueriedEmpresa = empresa;
    lastQueriedBodega = bodega;
    return super.getAllTransfers(
      estado: estado,
      empresa: empresa,
      bodega: bodega,
      fetchDetails: fetchDetails,
    );
  }

  @override
  Future<void> approveTransfer(String requestId, {String? observacion}) async {
    if (shouldFailApprove) {
      throw const TransferBusinessException(
        'Fallo interno al aprobar traspaso en PL/SQL',
        statusCode: 500,
        endpoint: 'POST /api/v1/traspasos/process/123',
        technicalDetails: 'POST /api/v1/traspasos/process/123 [HTTP 500]\nORA-20001: Error de validación',
      );
    }
    return super.approveTransfer(requestId, observacion: observacion);
  }

  @override
  Future<void> rejectTransfer({required String requestId, required String motivoRechazo}) async {
    if (shouldFailReject) {
      throw const TransferBusinessException(
        'Fallo al rechazar traspaso',
        statusCode: 400,
        endpoint: 'POST /api/v1/traspasos/process/123',
        technicalDetails: 'POST /api/v1/traspasos/process/123 [HTTP 400]',
      );
    }
    return super.rejectTransfer(requestId: requestId, motivoRechazo: motivoRechazo);
  }
}

void main() {
  late MockInventoryService service;
  late ConfigurableMockTransferRepository repository;
  late TransferApprovalProvider provider;

  setUp(() {
    service = MockInventoryService();
    repository = ConfigurableMockTransferRepository(service);
    provider = TransferApprovalProvider(repository);
  });

  group('TransferApprovalProvider Tests', () {
    test('Inicialización consulta por defecto con estado="pe" (pendientes)', () async {
      await Future.delayed(const Duration(milliseconds: 50));
      expect(repository.lastQueriedEstado, equals('pe'));
      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
    });

    test('updateFilter con nuevo estado recarga traspasos desde servidor con dicho estado', () async {
      provider.updateFilter(const TransferFilter(status: TransferStatus.approved));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(repository.lastQueriedEstado, equals('ap'));
      expect(provider.filter.status, equals(TransferStatus.approved));
    });

    test('approveTransfer exitoso retorna true y recarga la lista', () async {
      // Crear solicitud en memoria
      final req = TransferRequest(
        id: 'REQ-100',
        idArticulo: '1',
        nombreArticulo: 'Laptop HP',
        responsableActual: '101',
        responsablePropuesto: '202',
        motivoSolicitud: 'Reubicación',
        fechaSolicitud: DateTime.now(),
        bodegaActual: 'B01',
        bodegaPropuesta: 'B02',
        estado: TransferStatus.pending,
      );
      service.createTransferRequest(req);
      await provider.loadTransfers();

      final success = await provider.approveTransfer('REQ-100');

      expect(success, isTrue);
      expect(provider.error, isNull);
    });

    test('approveTransfer fallido captura TransferBusinessException, guarda detalles y retorna false', () async {
      repository.shouldFailApprove = true;

      final success = await provider.approveTransfer('REQ-999');

      expect(success, isFalse);
      expect(provider.error, contains('Fallo interno al aprobar traspaso'));
      expect(provider.statusCode, equals(500));
      expect(provider.technicalDetails, contains('ORA-20001'));
      expect(provider.isProcessing('REQ-999'), isFalse);
    });

    test('rejectTransfer fallido captura error y retorna false', () async {
      repository.shouldFailReject = true;

      final success = await provider.rejectTransfer('REQ-999', 'Motivo de prueba');

      expect(success, isFalse);
      expect(provider.error, contains('Fallo al rechazar traspaso'));
      expect(provider.statusCode, equals(400));
    });

    test('filteredTransfers filtra correctamente por bodegaPropuesta, responsibleQuery y fechas', () async {
      final now = DateTime(2026, 3, 10, 10, 0);
      final req1 = TransferRequest(
        id: 'REQ-1',
        idArticulo: 'A1',
        responsableActual: 'Juan Pérez',
        responsablePropuesto: 'Carlos Gómez',
        bodegaActual: 'B01',
        bodegaPropuesta: 'B02',
        fechaSolicitud: now,
        estado: TransferStatus.pending,
      );
      final req2 = TransferRequest(
        id: 'REQ-2',
        idArticulo: 'A2',
        responsableActual: 'Ana López',
        responsablePropuesto: 'María Díaz',
        bodegaActual: 'B01',
        bodegaPropuesta: 'B03',
        fechaSolicitud: now.subtract(const Duration(days: 5)),
        estado: TransferStatus.pending,
      );

      service.createTransferRequest(req1);
      service.createTransferRequest(req2);
      await provider.loadTransfers();

      expect(provider.filteredTransfers.length, equals(2));

      // Filtro por bodega
      provider.updateFilter(const TransferFilter(bodegaPropuesta: 'B02'));
      expect(provider.filteredTransfers.length, equals(1));
      expect(provider.filteredTransfers.first.id, equals('REQ-1'));

      // Filtro por responsable query
      provider.updateFilter(const TransferFilter(responsibleQuery: 'Díaz'));
      expect(provider.filteredTransfers.length, equals(1));
      expect(provider.filteredTransfers.first.id, equals('REQ-2'));

      // Filtro por fechas
      provider.updateFilter(TransferFilter(
        fromDate: DateTime(2026, 3, 9),
        toDate: DateTime(2026, 3, 11),
      ));
      expect(provider.filteredTransfers.length, equals(1));
      expect(provider.filteredTransfers.first.id, equals('REQ-1'));
    });

    test('loadTransfers con parámetros empresa y bodega transmite query params y los preserva', () async {
      await provider.loadTransfers(empresa: '01', bodega: 'BOD_01');

      expect(repository.lastQueriedEstado, equals('pe'));
      expect(repository.lastQueriedEmpresa, equals('01'));
      expect(repository.lastQueriedBodega, equals('BOD_01'));
      expect(provider.currentEmpresa, equals('01'));
      expect(provider.currentBodega, equals('BOD_01'));

      // Siguiente recarga sin argumentos conserva los parámetros previos
      await provider.loadTransfers();
      expect(repository.lastQueriedEmpresa, equals('01'));
      expect(repository.lastQueriedBodega, equals('BOD_01'));
    });

    test('TransferApprovalProvider con autoLoad=false no realiza peticiones al instanciarse', () async {
      final uninitializedRepo = ConfigurableMockTransferRepository(service);
      final lazyProvider = TransferApprovalProvider(uninitializedRepo, autoLoad: false);

      expect(uninitializedRepo.lastQueriedEstado, isNull);
      expect(lazyProvider.allTransfers, isEmpty);
      expect(lazyProvider.loading, isFalse);

      await lazyProvider.loadTransfers();
      expect(uninitializedRepo.lastQueriedEstado, equals('pe'));
    });

    test('loadTransfers enriquece concurrentemente nombres y descripciones de artículos con CatalogRepository', () async {
      final mockCatalog = MockCatalogRepository();
      final enrichedProvider = TransferApprovalProvider(
        repository,
        catalogRepository: mockCatalog,
        autoLoad: false,
      );

      final transfer = TransferRequest(
        id: 'ENRICH-01',
        responsableActual: '123',
        responsablePropuesto: '456',
        fechaSolicitud: DateTime.now(),
        bodegaActual: 'B01',
        bodegaPropuesta: 'B02',
        articulos: [
          const TransferArticleItem(articulo: '100450'),
        ],
      );
      service.createTransferRequest(transfer);

      await enrichedProvider.loadTransfers();

      expect(enrichedProvider.allTransfers.any((t) => t.id == 'ENRICH-01'), isTrue);
      final resolved = enrichedProvider.allTransfers.firstWhere((t) => t.id == 'ENRICH-01');

      // Nombres resueltos
      expect(resolved.responsableActual, contains('Carlos Rodríguez'));
      expect(resolved.responsablePropuesto, contains('María González'));

      // Artículo enriquecido con descripción
      expect(resolved.articulos.length, 1);
      expect(resolved.articulos.first.nombre, equals('COMPUTADOR PORTATIL LENOVO THINKPAD'));
      expect(resolved.nombreArticulo, equals('COMPUTADOR PORTATIL LENOVO THINKPAD'));
    });

    test('reset limpia cachés de datos y personas en TransferApprovalProvider', () async {
      final mockCatalog = MockCatalogRepository();
      final enrichedProvider = TransferApprovalProvider(
        repository,
        catalogRepository: mockCatalog,
        autoLoad: false,
      );

      service.createTransferRequest(
        TransferRequest(
          id: 'REQ-RESET',
          responsableActual: '123',
          responsablePropuesto: '456',
          fechaSolicitud: DateTime.now(),
          bodegaActual: 'B01',
          bodegaPropuesta: 'B02',
        ),
      );

      await enrichedProvider.loadTransfers();
      expect(enrichedProvider.allTransfers.isNotEmpty, isTrue);

      enrichedProvider.reset();
      expect(enrichedProvider.allTransfers, isEmpty);
      expect(enrichedProvider.loading, isFalse);
    });
  });
}
