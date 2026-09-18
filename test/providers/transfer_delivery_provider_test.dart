import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/models/transfer_delivery_request.dart';
import 'package:sigo_app/models/transfer_request.dart';
import 'package:sigo_app/models/transfer_person_model.dart';
import 'package:sigo_app/models/transfer_asset_model.dart';
import 'package:sigo_app/exceptions/transfer_business_exception.dart';
import 'package:sigo_app/providers/transfer_delivery_provider.dart';
import 'package:sigo_app/repositories/transfer_repository.dart';

class FakeTransferRepository implements TransferRepository {
  List<TransferRequest> transfers = [];
  final List<String> calls = [];
  bool shouldThrow = false;
  Exception? exceptionToThrow;

  @override
  Future<void> create(dynamic request) async {
    calls.add('create');
  }

  @override
  Future<List<TransferRequest>> getAllTransfers({
    String? estado,
    String? empresa,
    String? bodega,
    bool fetchDetails = true,
  }) async {
    calls.add('getAllTransfers');
    if (shouldThrow) {
      throw Exception('Fallo de red simulado');
    }
    return transfers;
  }

  @override
  Future<TransferRequest?> getTransferById(String id) async {
    calls.add('getTransferById:$id');
    try {
      return transfers.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> approveTransfer(String requestId, {String? observacion}) async {
    calls.add('approveTransfer:$requestId');
  }

  @override
  Future<void> rejectTransfer({required String requestId, required String motivoRechazo}) async {
    calls.add('rejectTransfer:$requestId');
  }

  @override
  Future<void> signTransfer({
    required String transferId,
    required String tipoFirma,
    required String firmaBase64,
  }) async {
    calls.add('signTransfer:$transferId:$tipoFirma');
    if (shouldThrow) {
      throw Exception('Error al firmar');
    }
  }

  @override
  Future<void> receiveTransfer(String transferId) async {
    calls.add('receiveTransfer:$transferId');
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    if (shouldThrow) {
      throw Exception('Error al recibir');
    }
  }

  @override
  Future<void> applyTransfer(TransferRequest request) async {
    calls.add('applyTransfer');
  }

  @override
  Future<void> applyTransferDelivery(TransferDeliveryRequest request) async {
    calls.add('applyTransferDelivery');
  }

  @override
  Future<List<TransferPersonModel>> getPersonsByWarehouse({
    required String bodega,
    required String empresa,
  }) async {
    calls.add('getPersonsByWarehouse:$bodega:$empresa');
    return [];
  }

  @override
  Future<List<TransferAssetModel>> getAssetsByPerson({
    required String persona,
    String? empresa,
  }) async {
    calls.add('getAssetsByPerson:$persona:$empresa');
    return [];
  }
}

void main() {
  late FakeTransferRepository repository;
  late TransferDeliveryProvider provider;

  setUp(() {
    repository = FakeTransferRepository();
    provider = TransferDeliveryProvider(repository);
  });

  group('TransferDeliveryProvider Tests', () {
    test('Estado inicial es loading false, sin errores y lista vacía', () {
      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
      expect(provider.getAssignedTransfers(), isEmpty);
    });

    test('loadTransfers carga lista de traspasos correctamente', () async {
      repository.transfers = [
        TransferRequest(
          id: '1',
          idArticulo: '501',
          nombreArticulo: 'Monitor',
          responsableActual: '12345',
          responsablePropuesto: '67890',
          motivoSolicitud: 'Traslado',
          fechaSolicitud: DateTime.now(),
          bodegaActual: 'BOD-1',
          bodegaPropuesta: 'BOD-2',
          estado: TransferStatus.approved,
        ),
      ];

      await provider.loadTransfers();

      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
      expect(provider.getAssignedTransfers().length, 1);
    });

    test('getAssignedTransfers filtra por estados aprobados habilitados para firmas', () async {
      repository.transfers = [
        TransferRequest(
          id: '1',
          idArticulo: '501',
          nombreArticulo: 'Monitor A',
          responsableActual: '12345',
          responsablePropuesto: '67890',
          motivoSolicitud: 'Traslado',
          fechaSolicitud: DateTime.now(),
          bodegaActual: 'BOD-1',
          bodegaPropuesta: 'BOD-2',
          estado: TransferStatus.approved,
        ),
        TransferRequest(
          id: '2',
          idArticulo: '502',
          nombreArticulo: 'Monitor B',
          responsableActual: '12345',
          responsablePropuesto: '67890',
          motivoSolicitud: 'Traslado',
          fechaSolicitud: DateTime.now(),
          bodegaActual: 'BOD-1',
          bodegaPropuesta: 'BOD-2',
          estado: TransferStatus.sourceSigned,
        ),
        TransferRequest(
          id: '3',
          idArticulo: '503',
          nombreArticulo: 'Monitor C',
          responsableActual: '12345',
          responsablePropuesto: '67890',
          motivoSolicitud: 'Traslado',
          fechaSolicitud: DateTime.now(),
          bodegaActual: 'BOD-1',
          bodegaPropuesta: 'BOD-2',
          estado: TransferStatus.received,
        ),
      ];

      await provider.loadTransfers();

      final assigned = provider.getAssignedTransfers('12345');
      expect(assigned.length, 2);
      expect(assigned.map((t) => t.id), containsAll(['1', '2']));
    });

    test('submitDelivery como despachador invoca signTransfer con tipoFirma FU', () async {
      final success = await provider.submitDelivery(
        '105',
        dispatcherBase64: 'base64-firma-despachador',
      );

      expect(success, isTrue);
      expect(repository.calls, contains('signTransfer:105:FU'));
    });

    test('submitDelivery como receptor invoca signTransfer DE sin orden requerido', () async {
      final success = await provider.submitDelivery(
        '105',
        receiverBase64: 'base64-firma-receptor',
      );

      expect(success, isTrue);
      expect(repository.calls, contains('signTransfer:105:DE'));
    });

    test('confirmReceipt invoca receiveTransfer en backend y recarga', () async {
      final success = await provider.confirmReceipt('105');

      expect(success, isTrue);
      expect(repository.calls, contains('receiveTransfer:105'));
      expect(repository.calls, contains('getAllTransfers'));
    });

    test('submitDelivery maneja error adecuadamente sin lanzar excepción no controlada', () async {
      repository.shouldThrow = true;

      final success = await provider.submitDelivery(
        '105',
        dispatcherBase64: 'base64',
      );

      expect(success, isFalse);
      expect(provider.error, isNotNull);
      expect(provider.loading, isFalse);
    });

    test('getAssignedTransfers coteja por personaFuente original aun si responsableActual es nombre enriquecido', () async {
      repository.transfers = [
        TransferRequest(
          id: '101',
          responsableActual: 'JUAN PEREZ', // Nombre enriquecido sin cédula
          responsablePropuesto: 'MARIA LOPEZ',
          personaFuente: '29305194', // Cédula original en nómina
          personaDestino: '98765432',
          motivoSolicitud: 'Traslado',
          fechaSolicitud: DateTime.now(),
          estado: TransferStatus.approved,
        ),
      ];

      await provider.loadTransfers();

      // Debe coincidir por la cédula original de quien entrega
      final byCedula = provider.getAssignedTransfers('29305194');
      expect(byCedula.length, 1);
      expect(byCedula.first.id, '101');
      expect(byCedula.first.personaFuente, '29305194');
      expect(byCedula.first.codigoFuente, '29305194');

      // Debe coincidir por la cédula original de quien recibe
      final byDestino = provider.getAssignedTransfers('98765432');
      expect(byDestino.length, 1);
      expect(byDestino.first.id, '101');
      expect(byDestino.first.personaDestino, '98765432');
      expect(byDestino.first.codigoDestino, '98765432');

      // Debe coincidir por el nombre enriquecido
      final byNombre = provider.getAssignedTransfers('JUAN');
      expect(byNombre.length, 1);
    });

    test('getAssignedTransfers funciona con userIdentifier y secondaryIdentifier (cédula y username)', () async {
      repository.transfers = [
        TransferRequest(
          id: '102',
          responsableActual: 'PI26055',
          responsablePropuesto: 'CARLOS GOMEZ',
          personaFuente: 'PI26055',
          personaDestino: '1098765432',
          motivoSolicitud: 'Asignación',
          fechaSolicitud: DateTime.now(),
          estado: TransferStatus.approved,
        ),
      ];

      await provider.loadTransfers();

      // Cédula no coincide pero username sí
      final matched = provider.getAssignedTransfers('55555555', 'PI26055');
      expect(matched.length, 1);
      expect(matched.first.id, '102');
    });

    test('TransferRequest.fromJson extrae fielmente personaFuente y personaDestino', () {
      final json = {
        'id': 1045,
        'estado': 'ap',
        'empresaDocumento': '01',
        'tipoDocumento': 'TRS',
        'numeroDocumento': 85023,
        'personaFuente': 'PI26055',
        'personaDestino': '1098765432',
        'observacion': 'Traspaso de equipos por reubicación',
        'articulos': [
          {'articulo': 'COMP-PORT-DELL', 'placa': 'PL-55421'}
        ],
        'firmas': [
          {'posicion': 1, 'tipo': 'FU', 'firmada': false},
          {'posicion': 2, 'tipo': 'DE', 'firmada': false}
        ]
      };

      final transfer = TransferRequest.fromJson(json);

      expect(transfer.id, '1045');
      expect(transfer.estado, TransferStatus.approved);
      expect(transfer.personaFuente, 'PI26055');
      expect(transfer.codigoFuente, 'PI26055');
      expect(transfer.personaDestino, '1098765432');
      expect(transfer.codigoDestino, '1098765432');
      expect(transfer.articulos.length, 1);
      expect(transfer.articulos.first.articulo, 'COMP-PORT-DELL');
      expect(transfer.isSourceSigned, isFalse);
      expect(transfer.isTargetSigned, isFalse);
    });

    test('confirmReceipt captura TransferBusinessException y desacopla mensaje amigable de detalles técnicos', () async {
      repository.exceptionToThrow = const TransferBusinessException(
        'Bodega Destino [2612] o Bodega Fuente [F571] Deben ser de Tipo Personal',
        technicalDetails: 'Endpoint: PUT /api/v1/traspasos/recibir/1045\nCódigo de negocio: -1\nDetalle del servidor:\nORA-20008...',
        statusCode: 500,
        endpoint: 'PUT /api/v1/traspasos/recibir/1045',
      );

      final success = await provider.confirmReceipt('1045');

      expect(success, isFalse);
      expect(provider.error, 'Bodega Destino [2612] o Bodega Fuente [F571] Deben ser de Tipo Personal');
      expect(provider.technicalDetails, contains('ORA-20008'));
      expect(provider.statusCode, 500);
      expect(provider.loading, isFalse);
    });
  });
}
