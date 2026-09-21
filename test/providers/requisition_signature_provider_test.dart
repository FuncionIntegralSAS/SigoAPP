import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/exceptions/requisition_business_exception.dart';
import 'package:sigo_app/models/company_model.dart';
import 'package:sigo_app/models/requisition_model.dart';
import 'package:sigo_app/providers/requisition_signature_provider.dart';
import 'package:sigo_app/repositories/requisition_repository.dart';

class MockRequisitionRepository implements RequisitionRepository {
  int getRequisitionsCallCount = 0;
  String? lastEstado;
  String? lastEmpresa;
  String? lastDesde;

  int getDetailCallCount = 0;
  String? lastDetailEmpresa;
  String? lastDetailTipo;
  String? lastDetailNumero;

  int signRequisitionCallCount = 0;
  RequisicionFirmaRequest? lastFirmaRequest;

  int registerExitCallCount = 0;

  bool shouldThrowOnSign = false;
  bool shouldThrowOnRegisterExit = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<CompanyModel>> getCompanies() async {
    return const [
      CompanyModel(codigo: '01', descripcion: 'EMPRESA 01', nit: '900000001', estado: 'A'),
      CompanyModel(codigo: '02', descripcion: 'EMPRESA 02', nit: '900000002', estado: 'A'),
    ];
  }

  @override
  Future<List<RequisicionResumen>> getRequisitions({
    String? estado,
    String? empresa,
    String? tipoDocumento,
    String? bodega,
    String? desde,
  }) async {
    getRequisitionsCallCount++;
    lastEstado = estado;
    lastEmpresa = empresa;
    lastDesde = desde;

    return [
      RequisicionResumen(
        empresa: empresa ?? '01',
        tipoDocumento: 'RS',
        numero: '10543',
        estado: 'en',
        fecha: '2026-09-18',
        bodega: 'BOD-CENTRAL',
        lineas: 2,
      ),
    ];
  }

  @override
  Future<RequisicionDetalle> getRequisitionDetail(
    String empresa,
    String tipoDocumento,
    String numero,
  ) async {
    getDetailCallCount++;
    lastDetailEmpresa = empresa;
    lastDetailTipo = tipoDocumento;
    lastDetailNumero = numero;

    return RequisicionDetalle(
      empresa: empresa,
      tipoDocumento: tipoDocumento,
      numero: numero,
      estado: 'en',
      fecha: '2026-09-18',
      bodega: 'BOD-CENTRAL',
      tercero: '1098765432',
      lineas: const [
        RequisicionDetalleLinea(
          secuencia: 1,
          articulo: 'ART-01',
          descripcion: 'Papel Bond',
          unidad: 'RES',
          bodega: 'BOD-CENTRAL',
          estado: 'en',
          solicitada: 5,
          aprobada: 5,
          entregada: 5,
          anulada: 0,
          recibida: 0,
          pendiente: 0,
        ),
      ],
      firmas: const [
        RequisicionFirma(
          posicion: 1,
          tipo: 'SA',
          firmada: false,
        ),
        RequisicionFirma(
          posicion: 2,
          tipo: 'RE',
          firmada: false,
        ),
      ],
    );
  }

  @override
  Future<void> signRequisition(
    String empresa,
    String tipoDocumento,
    String numero,
    RequisicionFirmaRequest request,
  ) async {
    signRequisitionCallCount++;
    lastFirmaRequest = request;

    if (shouldThrowOnSign) {
      throw const RequisitionBusinessException(
        'ORA-20001|Firma inválida o corrupta',
        statusCode: 400,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> registerExit(
    String empresa,
    String tipoDocumento,
    String numero, {
    RequisicionRegistrarRequest? request,
  }) async {
    registerExitCallCount++;

    if (shouldThrowOnRegisterExit) {
      throw const RequisitionBusinessException(
        'ORA-20002|La requisición no cuenta con ambas firmas',
        statusCode: 400,
      );
    }

    return {'code': 0, 'msg': 'Salida registrada con éxito'};
  }
}

void main() {
  group('RequisitionSignatureProvider Tests', () {
    late RequisitionSignatureProvider provider;
    late MockRequisitionRepository repository;

    setUp(() {
      repository = MockRequisitionRepository();
      provider = RequisitionSignatureProvider(repository);
    });

    test('Regla Lazy Fetch: No debe consultar backend si la fecha "desde" es nula', () async {
      expect(provider.selectedDesde, isNull);
      expect(provider.documents, isEmpty);

      await provider.loadDeliveredRequisitions();

      expect(repository.getRequisitionsCallCount, 0);
      expect(provider.documents, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('Consulta backend correctamente cuando se asigna la fecha inicial "desde"', () async {
      provider.setDesde(DateTime(2026, 9, 18));
      await Future<void>.delayed(Duration.zero);

      expect(repository.getRequisitionsCallCount, 1);
      expect(repository.lastEstado, 'en');
      expect(repository.lastDesde, '2026-09-18');
      expect(provider.documents.length, 1);
      expect(provider.documents.first.numero, '10543');
    });

    test('Filtrado por empresa actualiza parámetro y consulta el backend', () async {
      provider.setDesde(DateTime(2026, 9, 18));
      provider.setEmpresa('02');
      await Future<void>.delayed(Duration.zero);

      expect(repository.lastEmpresa, '02');
      expect(provider.selectedEmpresa, '02');
    });

    test('Carga de catálogo maestro de empresas', () async {
      await provider.loadCompanies();
      expect(provider.companies.length, 2);
      expect(provider.companies.first.codigo, '01');

      provider.setEmpresa('01');
      expect(provider.selectedCompanyModel?.descripcion, 'EMPRESA 01');
    });

    test('Caché y carga de detalle por terna identificadora (loadDetail)', () async {
      await provider.loadDetail('01', 'RS', '10543');

      expect(repository.getDetailCallCount, 1);
      expect(repository.lastDetailEmpresa, '01');
      expect(repository.lastDetailTipo, 'RS');
      expect(repository.lastDetailNumero, '10543');

      final detail = provider.getDetail('01', 'RS', '10543');
      expect(detail, isNotNull);
      expect(detail!.lineas.length, 1);
      expect(detail.firmas.length, 2);
      expect(detail.tercero, '1098765432');

      // Segunda llamada sin force: true no debe incrementar getDetailCallCount
      await provider.loadDetail('01', 'RS', '10543');
      expect(repository.getDetailCallCount, 1);

      // Llamada con force: true debe forzar recarga
      await provider.loadDetail('01', 'RS', '10543', force: true);
      expect(repository.getDetailCallCount, 2);
    });

    test('submitSignature envía request de salida SA con prefijo data:image y refresca el detalle', () async {
      final success = await provider.submitSignature(
        empresa: '01',
        tipoDocumento: 'RS',
        numero: '10543',
        tipo: 'SA',
        persona: '987654321',
        firmaBase64: 'iVBORw0KGgoAAAANSUhEUgAA...',
      );

      expect(success, isTrue);
      expect(repository.signRequisitionCallCount, 1);
      expect(repository.lastFirmaRequest?.tipo, 'SA');
      expect(repository.lastFirmaRequest?.persona, '987654321');
      expect(
        repository.lastFirmaRequest?.firma,
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...',
      );
      // Debe haber refrescado el detalle
      expect(repository.getDetailCallCount, 1);
    });

    test('submitSignature para recibo RE precarga y envía la cédula del solicitante tercero', () async {
      await provider.loadDetail('01', 'RS', '10543');
      final detail = provider.getDetail('01', 'RS', '10543');
      expect(detail?.tercero, '1098765432');

      final success = await provider.submitSignature(
        empresa: '01',
        tipoDocumento: 'RS',
        numero: '10543',
        tipo: 'RE',
        persona: detail!.tercero!,
        firmaBase64: 'data:image/png;base64,re_signature_bytes',
      );

      expect(success, isTrue);
      expect(repository.signRequisitionCallCount, 1);
      expect(repository.lastFirmaRequest?.tipo, 'RE');
      expect(repository.lastFirmaRequest?.persona, '1098765432');
      expect(
        repository.lastFirmaRequest?.firma,
        'data:image/png;base64,re_signature_bytes',
      );
    });

    test('submitSignature maneja errores sanitizando mensaje tras el pipe', () async {
      repository.shouldThrowOnSign = true;

      final success = await provider.submitSignature(
        empresa: '01',
        tipoDocumento: 'RS',
        numero: '10543',
        tipo: 'SA',
        persona: '1098765432',
        firmaBase64: 'raw_bytes',
      );

      expect(success, isFalse);
      expect(provider.actionError, 'Firma inválida o corrupta');
      expect(provider.statusCode, 400);
    });

    test('registerExit ejecuta salida definitiva y refresca bandeja de entregadas', () async {
      provider.setDesde(DateTime(2026, 9, 18));
      repository.getRequisitionsCallCount = 0;

      final success = await provider.registerExit(
        empresa: '01',
        tipoDocumento: 'RS',
        numero: '10543',
      );

      expect(success, isTrue);
      expect(repository.registerExitCallCount, 1);
      // Verifica que recargó la bandeja
      expect(repository.getRequisitionsCallCount, 1);
    });

    test('registerExit maneja fallos de negocio sanitizando pipes', () async {
      repository.shouldThrowOnRegisterExit = true;

      final success = await provider.registerExit(
        empresa: '01',
        tipoDocumento: 'RS',
        numero: '10543',
      );

      expect(success, isFalse);
      expect(
        provider.actionError,
        'La requisición no cuenta con ambas firmas',
      );
    });

    test('reset limpia todos los estados y filtros en memoria', () async {
      provider.setDesde(DateTime(2026, 9, 18));
      provider.setEmpresa('01');
      await provider.loadCompanies();

      expect(provider.selectedDesde, isNotNull);
      expect(provider.selectedEmpresa, isNotNull);
      expect(provider.companies, isNotEmpty);

      provider.reset();

      expect(provider.selectedDesde, isNull);
      expect(provider.selectedEmpresa, isNull);
      expect(provider.companies, isEmpty);
      expect(provider.documents, isEmpty);
    });
  });
}
