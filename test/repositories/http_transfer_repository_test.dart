import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/exceptions/transfer_business_exception.dart';
import 'package:sigo_app/models/transfer_create_request.dart';
import 'package:sigo_app/models/transfer_request.dart';
import 'package:sigo_app/repositories/http_transfer_repository.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    throw UnimplementedError();
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late MockHttpClientAdapter adapter;
  late HttpTransferRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    adapter = MockHttpClientAdapter();
    dio.httpClientAdapter = adapter;
    repository = HttpTransferRepository(dio);
  });

  group('HttpTransferRepository Tests', () {
    test('create envía POST a /api/v1/traspasos/crear con payload multi-artículo correcto', () async {
      RequestOptions? capturedOptions;
      adapter.handler = (options) {
        capturedOptions = options;
        return ResponseBody.fromString(
          '{"code": 0, "msg": "El traspaso fue creado correctamente", "object": {"id": 1045}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final createRequest = TransferCreateRequest(
        empresa: '01',
        personaFuente: '1098765432',
        personaDestino: '1012345678',
        articulos: [
          const TransferArticleItem(articulo: 'ELEM-00451', placa: 'PLA-998822'),
          const TransferArticleItem(articulo: 'ELEM-00452', placa: 'PLA-998823'),
        ],
        observacion: 'Traspaso de computadores por renovación de sede',
        tipoMovimiento: null,
      );

      await repository.create(createRequest);

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.path, '/api/v1/traspasos/crear');
      expect(capturedOptions!.method, 'POST');
      expect(capturedOptions!.data['empresa'], '01');
      expect(capturedOptions!.data['personaFuente'], '1098765432');
      expect(capturedOptions!.data['personaDestino'], '1012345678');
      expect(capturedOptions!.data['articulos'], isA<List>());
      expect((capturedOptions!.data['articulos'] as List).length, 2);
    });

    test('getAllTransfers sin fetchDetails parsea cabeceras ligeras', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          '''
          {
            "code": 0,
            "msg": "Consulta exitosa",
            "list": [
              {
                "id": 1045,
                "tipoDocumento": "REQU",
                "numeroDocumento": 85023,
                "fechaCreacion": "2026-09-09T09:30:00"
              }
            ]
          }
          ''',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final transfers = await repository.getAllTransfers(estado: 'pe', fetchDetails: false);

      expect(transfers.length, 1);
      expect(transfers.first.id, '1045');
      expect(transfers.first.numeroDocumento, 85023);
      expect(transfers.first.tipoDocumento, 'REQU');
    });

    test('getTransferById desempaqueta detalle completo con artículos y firmas', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          '''
          {
            "code": 0,
            "msg": "Consulta exitosa",
            "object": {
              "id": 1045,
              "estado": "ap",
              "empresaDocumento": "01",
              "tipoDocumento": "REQU",
              "numeroDocumento": 85023,
              "personaFuente": "1098765432",
              "personaDestino": "1012345678",
              "observacion": "Traspaso de computadores",
              "articulos": [
                {
                  "articulo": "ELEM-00451",
                  "placa": "PLA-998822"
                }
              ],
              "firmas": [
                {
                  "posicion": 1,
                  "tipo": "FU",
                  "fechaFirma": "2026-09-09T10:15:00",
                  "firmada": true,
                  "firma": "iVBORw0KGgoAAAANSUhEUgAA..."
                },
                {
                  "posicion": 2,
                  "tipo": "DE",
                  "fechaFirma": null,
                  "firmada": false,
                  "firma": null
                }
              ]
            }
          }
          ''',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final transfer = await repository.getTransferById('1045');

      expect(transfer, isNotNull);
      expect(transfer!.id, '1045');
      expect(transfer.estado, TransferStatus.approved);
      expect(transfer.responsableActual, '1098765432');
      expect(transfer.responsablePropuesto, '1012345678');
      expect(transfer.articulos.length, 1);
      expect(transfer.articulos.first.articulo, 'ELEM-00451');
      expect(transfer.isSourceSigned, isTrue);
      expect(transfer.isTargetSigned, isFalse);
      expect(transfer.bothSigned, isFalse);
    });

    test('approveTransfer envía POST a /api/v1/traspasos/process/{id} con estado="ap"', () async {
      RequestOptions? capturedOptions;
      adapter.handler = (options) {
        capturedOptions = options;
        return ResponseBody.fromString(
          '{"code": 0, "msg": "El trámite fue procesado correctamente"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      await repository.approveTransfer('1045');

      expect(capturedOptions!.path, '/api/v1/traspasos/process/1045');
      expect(capturedOptions!.method, 'POST');
      expect(capturedOptions!.data['estado'], 'ap');
    });

    test('signTransfer envía PUT a /api/v1/traspasos/sign/{id} con tipoFirma y firma', () async {
      RequestOptions? capturedOptions;
      adapter.handler = (options) {
        capturedOptions = options;
        return ResponseBody.fromString(
          '{"code": 0, "msg": "La firma fue registrada correctamente"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      await repository.signTransfer(
        transferId: '1045',
        tipoFirma: 'DE',
        firmaBase64: 'data:image/png;base64,...',
      );

      expect(capturedOptions!.path, '/api/v1/traspasos/sign/1045');
      expect(capturedOptions!.method, 'PUT');
      expect(capturedOptions!.data['tipoFirma'], 'DE');
    });

    test('receiveTransfer envía PUT a /api/v1/traspasos/recibir/{id}', () async {
      RequestOptions? capturedOptions;
      adapter.handler = (options) {
        capturedOptions = options;
        return ResponseBody.fromString(
          '{"code": 0, "msg": "La recepción fue registrada correctamente"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      await repository.receiveTransfer('1045');

      expect(capturedOptions!.path, '/api/v1/traspasos/recibir/1045');
      expect(capturedOptions!.method, 'PUT');
    });

    test('Respuesta con code != 0 lanza TransferBusinessException con el mensaje del backend', () async {
      adapter.handler = (options) {
        return ResponseBody.fromString(
          '{"code": -1, "msg": "El trámite no se encuentra en estado pendiente"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      expect(
        () => repository.approveTransfer('1045'),
        throwsA(
          isA<TransferBusinessException>().having(
            (e) => e.message,
            'message',
            contains('El trámite no se encuentra en estado pendiente'),
          ),
        ),
      );
    });

    test('getPersonsByWarehouse envía GET a /api/v1/traspasos/personas con query params correctos', () async {
      RequestOptions? capturedOptions;
      adapter.handler = (options) {
        capturedOptions = options;
        return ResponseBody.fromString(
          '''
          {
            "code": 0,
            "msg": "Consulta exitosa",
            "list": [
              { "cedula": "PI26055", "nombre": "JUAN CAMILO", "apellido": "DIAZ GOMEZ" },
              { "cedula": "1098765432", "nombre": "ANDRES FELIPE", "apellido": "ARIAS LOPEZ" }
            ]
          }
          ''',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final persons = await repository.getPersonsByWarehouse(
        bodega: 'BOD01',
        empresa: '01',
      );

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.path, '/api/v1/traspasos/personas');
      expect(capturedOptions!.method, 'GET');
      expect(capturedOptions!.queryParameters['bodega'], 'BOD01');
      expect(capturedOptions!.queryParameters['empresa'], '01');

      expect(persons.length, 2);
      expect(persons[0].cedula, 'PI26055');
      expect(persons[0].nombre, 'JUAN CAMILO');
      expect(persons[0].apellido, 'DIAZ GOMEZ');
      expect(persons[0].nombreCompleto, 'JUAN CAMILO DIAZ GOMEZ');
      expect(persons[1].cedula, '1098765432');
    });

    test('getAssetsByPerson envía GET a /api/v1/traspasos/activos y deserializa modelos correctamente', () async {
      RequestOptions? capturedOptions;
      adapter.handler = (options) {
        capturedOptions = options;
        return ResponseBody.fromString(
          '''
          {
            "code": 0,
            "msg": "Consulta exitosa",
            "list": [
              {
                "articulo": "100450",
                "placa": "PLA-00981",
                "nombre": "COMPUTADOR PORTATIL LENOVO THINKPAD",
                "centroInformacion": "CI-01",
                "tercero": "900123456",
                "enTramite": false
              },
              {
                "articulo": "100451",
                "placa": "PLA-00982",
                "nombre": "MONITOR DELL 24 PULGADAS",
                "centroInformacion": "CI-01",
                "tercero": "900123456",
                "enTramite": true
              }
            ]
          }
          ''',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final assets = await repository.getAssetsByPerson(
        persona: 'PI26055',
        empresa: '01',
      );

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.path, '/api/v1/traspasos/activos');
      expect(capturedOptions!.method, 'GET');
      expect(capturedOptions!.queryParameters['persona'], 'PI26055');
      expect(capturedOptions!.queryParameters['empresa'], '01');

      expect(assets.length, 2);
      expect(assets[0].articulo, '100450');
      expect(assets[0].placa, 'PLA-00981');
      expect(assets[0].nombre, 'COMPUTADOR PORTATIL LENOVO THINKPAD');
      expect(assets[0].centroInformacion, 'CI-01');
      expect(assets[0].tercero, '900123456');
      expect(assets[0].enTramite, isFalse);

      expect(assets[1].articulo, '100451');
      expect(assets[1].enTramite, isTrue);

      final transferItem = assets[0].toTransferArticleItem();
      expect(transferItem.articulo, '100450');
      expect(transferItem.placa, 'PLA-00981');
      expect(transferItem.nombre, 'COMPUTADOR PORTATIL LENOVO THINKPAD');
    });

    test('TransferArticleItem deserializa nombre y TransferRequest.nombreArticulo lo prioriza', () {
      final jsonItem = {
        'articulo': 'ELEM-001',
        'placa': 'PLA-001',
        'nombre': 'PORTATIL HP ELITEBOOK',
      };
      final item = TransferArticleItem.fromJson(jsonItem);
      expect(item.nombre, 'PORTATIL HP ELITEBOOK');
      expect(item.toJson()['nombre'], 'PORTATIL HP ELITEBOOK');

      final cloned = item.copyWith(nombre: 'PORTATIL HP RENOVADO');
      expect(cloned.nombre, 'PORTATIL HP RENOVADO');

      final reqSingle = TransferRequest(
        id: '1',
        fechaSolicitud: DateTime.now(),
        articulos: [cloned],
      );
      expect(reqSingle.nombreArticulo, 'PORTATIL HP RENOVADO');

      final reqMulti = TransferRequest(
        id: '2',
        fechaSolicitud: DateTime.now(),
        articulos: [
          cloned,
          const TransferArticleItem(articulo: 'ELEM-002', nombre: 'MONITOR LG'),
        ],
      );
      expect(reqMulti.nombreArticulo, 'PORTATIL HP RENOVADO (+1 artículos más)');
    });
  });
}
