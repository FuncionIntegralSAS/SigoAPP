import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/modules/inventory/models/transfer_create_request.dart';
import 'package:sigo_app/modules/inventory/models/transfer_request.dart';

void main() {
  group('TransferArticleItem and TransferFirmItem Tests', () {
    test('TransferArticleItem serializa y deserializa correctamente', () {
      final item = const TransferArticleItem(
        articulo: 'ELEM-001',
        placa: 'PLA-99',
      );

      final json = item.toJson();
      expect(json['articulo'], 'ELEM-001');
      expect(json['placa'], 'PLA-99');

      final fromJson = TransferArticleItem.fromJson(json);
      expect(fromJson.articulo, 'ELEM-001');
      expect(fromJson.placa, 'PLA-99');
    });

    test('TransferFirmItem detecta firmada: true cuando hay firma en base64', () {
      final firm = TransferFirmItem.fromJson({
        'posicion': 1,
        'tipo': 'FU',
        'firmada': false,
        'firma': 'base64-content',
        'fechaFirma': '2026-09-09T10:00:00',
      });

      expect(firm.posicion, 1);
      expect(firm.tipo, 'FU');
      expect(firm.firmada, isTrue);
      expect(firm.firma, 'base64-content');
      expect(firm.fechaFirma, isNotNull);
    });
  });

  group('TransferCreateRequest Multi-Artículo Tests', () {
    test('toJson produce payload multi-artículo según especificación backend', () {
      final request = TransferCreateRequest(
        empresa: '01',
        personaFuente: '1098765432',
        personaDestino: '1012345678',
        articulos: [
          const TransferArticleItem(articulo: 'ELEM-00451', placa: 'PLA-998822'),
          const TransferArticleItem(articulo: 'ELEM-00452', placa: 'PLA-998823'),
        ],
        observacion: 'Renovación de sede',
        tipoMovimiento: null,
      );

      final json = request.toJson();
      expect(json['empresa'], '01');
      expect(json['personaFuente'], '1098765432');
      expect(json['personaDestino'], '1012345678');
      expect(json['articulos'], isA<List>());
      expect((json['articulos'] as List).length, 2);
      expect(json['observacion'], 'Renovación de sede');
      expect(json.containsKey('tipoMovimiento'), isFalse);
    });

    test('fromJson soporta payload multi-artículo y legacy elemento único', () {
      final legacy = TransferCreateRequest.fromJson({
        'empresa': '01',
        'personaFuente': '101',
        'personaDestino': '202',
        'elemento': 'ART-99',
        'placa': 'PLA-01',
        'observacion': 'Traslado',
      });

      expect(legacy.articulos.length, 1);
      expect(legacy.articulos.first.articulo, 'ART-99');
      expect(legacy.articulos.first.placa, 'PLA-01');
    });
  });

  group('TransferRequest 4-Estados y Firmas Desacopladas Tests', () {
    test('bothSigned es true solo cuando ambas firmas están registradas', () {
      final transferSinFirmas = TransferRequest(
        id: '1045',
        fechaSolicitud: DateTime.now(),
        estado: TransferStatus.approved,
        articulos: [const TransferArticleItem(articulo: 'ELEM-1')],
        firmas: [
          const TransferFirmItem(posicion: 1, tipo: 'FU', firmada: false),
          const TransferFirmItem(posicion: 2, tipo: 'DE', firmada: false),
        ],
      );

      expect(transferSinFirmas.isSourceSigned, isFalse);
      expect(transferSinFirmas.isTargetSigned, isFalse);
      expect(transferSinFirmas.bothSigned, isFalse);

      final transferFirmaFuente = transferSinFirmas.copyWith(
        firmas: [
          const TransferFirmItem(posicion: 1, tipo: 'FU', firmada: true, firma: 'b64fu'),
          const TransferFirmItem(posicion: 2, tipo: 'DE', firmada: false),
        ],
      );

      expect(transferFirmaFuente.isSourceSigned, isTrue);
      expect(transferFirmaFuente.isTargetSigned, isFalse);
      expect(transferFirmaFuente.bothSigned, isFalse);

      final transferAmbas = transferSinFirmas.copyWith(
        firmas: [
          const TransferFirmItem(posicion: 1, tipo: 'FU', firmada: true, firma: 'b64fu'),
          const TransferFirmItem(posicion: 2, tipo: 'DE', firmada: true, firma: 'b64de'),
        ],
      );

      expect(transferAmbas.isSourceSigned, isTrue);
      expect(transferAmbas.isTargetSigned, isTrue);
      expect(transferAmbas.bothSigned, isTrue);
    });

    test('nombreArticulo resume múltiples artículos correctamente', () {
      final transferMulti = TransferRequest(
        id: '1045',
        fechaSolicitud: DateTime.now(),
        articulos: [
          const TransferArticleItem(articulo: 'ELEM-1'),
          const TransferArticleItem(articulo: 'ELEM-2'),
          const TransferArticleItem(articulo: 'ELEM-3'),
        ],
      );

      expect(transferMulti.nombreArticulo, 'ELEM-1 (+2 artículos más)');
    });
  });
}
