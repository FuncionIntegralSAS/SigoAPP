import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/models/transfer_delivery_request.dart';
import 'package:sigo_app/models/transfer_request.dart';
import 'package:sigo_app/models/transfer_person_model.dart';
import 'package:sigo_app/models/transfer_asset_model.dart';
import 'package:sigo_app/providers/transfer_delivery_provider.dart';
import 'package:sigo_app/repositories/transfer_repository.dart';

class FakeTransferRepository implements TransferRepository {
  List<TransferRequest> transfers = [];
  final List<String> calls = [];
  bool shouldThrow = false;

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
  });
}
