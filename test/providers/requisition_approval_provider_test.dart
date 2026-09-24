import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/shared/models/company_model.dart';
import 'package:sigo_app/modules/requisitions/models/requisition_model.dart';
import 'package:sigo_app/modules/requisitions/providers/requisition_approval_provider.dart';
import 'package:sigo_app/modules/requisitions/repositories/requisition_repository.dart';

class MockRequisitionRepository implements RequisitionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<CompanyModel>> getCompanies() async => [];

  @override
  Future<List<RequisicionResumen>> getRequisitions({
    String? estado,
    String? empresa,
    String? tipoDocumento,
    String? bodega,
    String? desde,
  }) async => [];

  @override
  Future<RequisicionDetalle> getRequisitionDetail(
    String empresa,
    String tipoDocumento,
    String numero,
  ) async {
    return RequisicionDetalle(
      empresa: empresa,
      tipoDocumento: tipoDocumento,
      numero: numero,
      estado: 'in',
      fecha: '2026-09-18',
      bodega: 'BOD01',
      lineas: [
        RequisicionDetalleLinea(
          secuencia: 1,
          articulo: 'ART-001',
          descripcion: 'Artículo 1',
          unidad: 'UND',
          bodega: 'BOD01',
          estado: 'in',
          solicitada: 10,
          aprobada: 8,
          entregada: 0,
          anulada: 0,
          recibida: 0,
          pendiente: 10,
        ),
        RequisicionDetalleLinea(
          secuencia: 2,
          articulo: 'ART-002',
          descripcion: 'Artículo 2',
          unidad: 'UND',
          bodega: 'BOD01',
          estado: 'in',
          solicitada: 5,
          aprobada: 5,
          entregada: 0,
          anulada: 0,
          recibida: 0,
          pendiente: 5,
        ),
      ],
    );
  }

  @override
  Future<bool> processBatch(
    Map<String, int> selections,
    String targetStatus, {
    List<RequisitionModel>? requisitions,
  }) async => true;
}

void main() {
  group('RequisitionApprovalProvider - Document and Line Selection Tests', () {
    late RequisitionApprovalProvider provider;
    late MockRequisitionRepository repository;

    setUp(() {
      repository = MockRequisitionRepository();
      provider = RequisitionApprovalProvider(repository);
    });

    test('isDocumentModified debe reflejar reactivamente si alguna línea fue modificada', () {
      expect(provider.isDocumentModified('01', 'RQ', '1001'), isFalse);
      expect(provider.countSelectedLinesForDocument('01', 'RQ', '1001'), 0);

      // Modificar / seleccionar una línea del documento 1001
      const lineId1 = '01_RQ_1001_BOD01_ART-001_1';
      provider.toggleSelection(lineId1, true, 4);

      expect(provider.isDocumentModified('01', 'RQ', '1001'), isTrue);
      expect(provider.countSelectedLinesForDocument('01', 'RQ', '1001'), 1);

      // Otro documento no debe verse afectado
      expect(provider.isDocumentModified('01', 'RQ', '1002'), isFalse);
      expect(provider.countSelectedLinesForDocument('01', 'RQ', '1002'), 0);

      // Quitar la selección
      provider.toggleSelection(lineId1, false, 0);
      expect(provider.isDocumentModified('01', 'RQ', '1001'), isFalse);
      expect(provider.countSelectedLinesForDocument('01', 'RQ', '1001'), 0);
    });

    test('selectAllForDocument y deselectDocumentByTerna operan correctamente sobre el documento', () {
      final detail = RequisicionDetalle(
        empresa: '01',
        tipoDocumento: 'RQ',
        numero: '1001',
        estado: 'in',
        fecha: '2026-09-18',
        bodega: 'B1',
        lineas: [
          RequisicionDetalleLinea(
            secuencia: 1,
            articulo: 'A1',
            descripcion: 'Desc 1',
            unidad: 'UND',
            bodega: 'B1',
            estado: 'in',
            solicitada: 12,
            aprobada: 10,
            entregada: 0,
            anulada: 0,
            recibida: 0,
            pendiente: 12,
          ),
          RequisicionDetalleLinea(
            secuencia: 2,
            articulo: 'A2',
            descripcion: 'Desc 2',
            unidad: 'UND',
            bodega: 'B1',
            estado: 'in',
            solicitada: 7,
            aprobada: 5,
            entregada: 0,
            anulada: 0,
            recibida: 0,
            pendiente: 7,
          ),
        ],
      );

      // Seleccionar todo en pestaña 'in' (solicitada)
      provider.selectAllForDocument(detail, 'in');

      expect(provider.isDocumentModified('01', 'RQ', '1001'), isTrue);
      expect(provider.countSelectedLinesForDocument('01', 'RQ', '1001'), 2);
      expect(provider.getSelectedItemQuantity('01_RQ_1001_B1_A1_1'), 12);
      expect(provider.getSelectedItemQuantity('01_RQ_1001_B1_A2_2'), 7);

      // Deseleccionar documento por terna
      provider.deselectDocumentByTerna('01', 'RQ', '1001');

      expect(provider.isDocumentModified('01', 'RQ', '1001'), isFalse);
      expect(provider.countSelectedLinesForDocument('01', 'RQ', '1001'), 0);
      expect(provider.getSelectedItemQuantity('01_RQ_1001_B1_A1_1'), 0);
    });

    test('deselectDocumentByTerna solo limpia las líneas del documento específico', () {
      // Líneas de dos documentos diferentes
      provider.toggleSelection('01_RQ_1001_BOD_ART_1', true, 5);
      provider.toggleSelection('01_RQ_1002_BOD_ART_1', true, 3);

      expect(provider.countSelectedLinesForDocument('01', 'RQ', '1001'), 1);
      expect(provider.countSelectedLinesForDocument('01', 'RQ', '1002'), 1);

      // Deseleccionar únicamente 1001
      provider.deselectDocumentByTerna('01', 'RQ', '1001');

      expect(provider.isDocumentModified('01', 'RQ', '1001'), isFalse);
      expect(provider.countSelectedLinesForDocument('01', 'RQ', '1001'), 0);

      // El documento 1002 permanece intacto
      expect(provider.isDocumentModified('01', 'RQ', '1002'), isTrue);
      expect(provider.countSelectedLinesForDocument('01', 'RQ', '1002'), 1);
      expect(provider.getSelectedItemQuantity('01_RQ_1002_BOD_ART_1'), 3);
    });

    test('selectedDocumentsCount cuenta documentos únicos y no cantidad de movimientos', () {
      expect(provider.selectedDocumentsCount, 0);

      // Agregar dos líneas para el mismo documento 1001
      provider.toggleSelection('01_RQ_1001_BOD_ART1_1', true, 5);
      provider.toggleSelection('01_RQ_1001_BOD_ART2_2', true, 10);

      // selectedCount son las líneas (2), pero selectedDocumentsCount debe ser 1 documento
      expect(provider.selectedCount, 2);
      expect(provider.selectedDocumentsCount, 1);

      // Agregar una línea de otro documento 1002
      provider.toggleSelection('01_RQ_1002_BOD_ART1_1', true, 4);
      expect(provider.selectedCount, 3);
      expect(provider.selectedDocumentsCount, 2);

      // Limpiar documento 1001
      provider.deselectDocumentByTerna('01', 'RQ', '1001');
      expect(provider.selectedCount, 1);
      expect(provider.selectedDocumentsCount, 1);

      // Limpiar documento 1002
      provider.deselectDocumentByTerna('01', 'RQ', '1002');
      expect(provider.selectedCount, 0);
      expect(provider.selectedDocumentsCount, 0);
    });
  });
}
