import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/modules/requisitions/models/requisition_model.dart';

void main() {
  group('RequisicionDetalle Model Tests', () {
    test('fromJson y toJson procesan responsableBodega y responsableBodegaDestino correctamente', () {
      final json = {
        'empresa': '01',
        'tipoDocumento': 'RS',
        'numero': 10543,
        'estado': 'en',
        'fecha': '2026-09-21',
        'fechaRequerida': '2026-09-22',
        'observacion': 'Traspaso de suministros',
        'bodega': 'BOD-ORIGEN',
        'bodegaDestino': 'BOD-DESTINO',
        'centroInformacion': 'CC-01',
        'tercero': '1098765432',
        'responsableBodega': '80123456',
        'responsableBodegaDestino': '79654321',
        'lineas': [
          {
            'secuencia': 1,
            'articulo': 'ART-01',
            'descripcion': 'Resma Papel',
            'unidad': 'UND',
            'bodega': 'BOD-ORIGEN',
            'estado': 'en',
            'solicitada': 2.0,
            'aprobada': 2.0,
            'entregada': 2.0,
            'anulada': 0.0,
            'recibida': 0.0,
            'pendiente': 0.0,
          }
        ],
        'firmas': [
          {
            'tipo': 'SA',
            'persona': '80123456',
            'fechaFirma': '2026-09-21 10:00:00',
            'firmada': true,
            'firma': 'data:image/png;base64,...',
          }
        ],
      };

      final detalle = RequisicionDetalle.fromJson(json);

      expect(detalle.empresa, '01');
      expect(detalle.tipoDocumento, 'RS');
      expect(detalle.numero, 10543);
      expect(detalle.bodega, 'BOD-ORIGEN');
      expect(detalle.bodegaDestino, 'BOD-DESTINO');
      expect(detalle.tercero, '1098765432');
      expect(detalle.responsableBodega, '80123456');
      expect(detalle.responsableBodegaDestino, '79654321');
      expect(detalle.lineas.length, 1);
      expect(detalle.firmas.length, 1);

      final serialized = detalle.toJson();
      expect(serialized['responsableBodega'], '80123456');
      expect(serialized['responsableBodegaDestino'], '79654321');
    });

    test('fromJson maneja campos nulos para responsables de bodega', () {
      final json = {
        'empresa': '01',
        'tipoDocumento': 'RS',
        'numero': 10544,
        'estado': 'en',
        'fecha': '2026-09-21',
        'bodega': 'BOD-ORIGEN',
        'tercero': '1098765432',
      };

      final detalle = RequisicionDetalle.fromJson(json);

      expect(detalle.responsableBodega, isNull);
      expect(detalle.responsableBodegaDestino, isNull);

      final serialized = detalle.toJson();
      expect(serialized['responsableBodega'], isNull);
      expect(serialized['responsableBodegaDestino'], isNull);
    });
  });

  group('RequisicionFirma Model Tests', () {
    test('fromJson mapea tipo, persona, nombre y fecha, y deriva firmada = true cuando hay fecha', () {
      final json = {
        'tipo': 'SA',
        'persona': '1098765432',
        'nombre': 'JUAN CAMILO DIAZ',
        'fecha': '2026-09-24T15:30:00',
        'firmada': false, // Aunque venga false, al haber fecha debe derivar true
      };

      final firma = RequisicionFirma.fromJson(json);

      expect(firma.tipo, 'SA');
      expect(firma.persona, '1098765432');
      expect(firma.nombre, 'JUAN CAMILO DIAZ');
      expect(firma.fecha, '2026-09-24T15:30:00');
      expect(firma.fechaFirma, '2026-09-24T15:30:00');
      expect(firma.firmada, isTrue);

      final serialized = firma.toJson();
      expect(serialized['nombre'], 'JUAN CAMILO DIAZ');
      expect(serialized['fecha'], '2026-09-24T15:30:00');
      expect(serialized['firmada'], isTrue);
    });

    test('fromJson mantiene firmada = false cuando fecha es null o vacía', () {
      final json = {
        'tipo': 'RE',
        'persona': null,
        'nombre': null,
        'fecha': null,
        'firmada': false,
      };

      final firma = RequisicionFirma.fromJson(json);

      expect(firma.tipo, 'RE');
      expect(firma.persona, isNull);
      expect(firma.nombre, isNull);
      expect(firma.fecha, isNull);
      expect(firma.firmada, isFalse);
    });
  });
}
