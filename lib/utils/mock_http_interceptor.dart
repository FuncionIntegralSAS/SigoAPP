import 'package:dio/dio.dart';
import 'app_logger.dart';

/// Interceptor de `Dio` para simulación local cuando la sesión activa
/// pertenece al "Entorno de Pruebas (MOCK)".
///
/// Si la cabecera `Authorization` contiene el token mock (`mock-token`),
/// intercepta la petición antes de enviarla a la red y resuelve inmediatamente
/// un [Response] con código HTTP 200 y datos simulados acordes a los contratos
/// esperados por los repositorios de SigoAPP.
class MockHttpInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final authHeader = options.headers['Authorization']?.toString() ?? '';
    final isMock = authHeader.contains('mock-token');

    if (!isMock) {
      // Sesión real: continuar flujo normal hacia Spring Boot
      return handler.next(options);
    }

    AppLogger.d('MockHttpInterceptor: Interceptando [${options.method}] ${options.path} (Modo Mock)');

    final dynamic mockData = _resolveMockData(options);

    return handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: mockData,
      ),
    );
  }

  /// Genera los payloads simulados según la ruta y método HTTP consultado
  dynamic _resolveMockData(RequestOptions options) {
    final path = options.path;
    final method = options.method.toUpperCase();

    // 1. Operaciones transaccionales (POST, PUT, DELETE)
    // Retornan la envoltura estándar ObjectResponse esperada por los repositorios
    if (method == 'POST' || method == 'PUT' || method == 'DELETE') {
      return {
        'code': 0,
        'msg': 'Operación simulada con éxito (Entorno Mock)',
        'object': null,
      };
    }

    // 2. Empresas
    if (path.contains('/api/v1/empresas/getAll')) {
      return [
        {
          'codigo': '01',
          'nombre': 'EMPRESA PRUEBA S.A.',
          'identificacion': '900123456',
        },
      ];
    }

    // 3. Bodegas por empresa
    if (path.contains('/api/v1/bodegas/empresa/')) {
      return [
        {
          'codigoBodega': 'BOG001',
          'descripcionBodega': 'Almacén Central (Mock)',
          'estadoBodega': 'ac',
        },
        {
          'codigoBodega': 'MED002',
          'descripcionBodega': 'Taller de Mantenimiento (Mock)',
          'estadoBodega': 'ac',
        },
        {
          'codigoBodega': 'CC003',
          'descripcionBodega': 'Oficinas Administrativas (Mock)',
          'estadoBodega': 'ia',
        },
      ];
    }

    // 4. Artículos asignados a bodega
    if (path.contains('/api/v1/articulos/asignados/')) {
      return [
        {
          'id': 1,
          'codigoActivo': 'PC001',
          'nombre': 'Portátil Mock i7 16GB',
          'placa': 'MOCK-001',
          'bodega': 'BOG001',
          'responsable': 'operador',
          'estado': 'Operativo',
        },
        {
          'id': 2,
          'codigoActivo': 'IM002',
          'nombre': 'Impresora Láser Mock',
          'placa': 'MOCK-002',
          'bodega': 'BOG001',
          'responsable': 'operador',
          'estado': 'Operativo',
        },
        {
          'id': 3,
          'codigoActivo': 'SC003',
          'nombre': 'Lector Scanner Barcode',
          'placa': 'MOCK-003',
          'bodega': 'MED002',
          'responsable': 'destinatario',
          'estado': 'Operativo',
        },
      ];
    }

    // 5. Bandeja de Traspasos (listado)
    if (path.contains('/api/v1/traspasos/list')) {
      return [
        {
          'id': 'TR-MOCK-101',
          'numeroDocumento': 101,
          'tipoDocumento': 'TS',
          'fecha': '2026-09-17',
          'estado': 'ap',
          'personaFuente': 'operador',
          'personaDestino': 'destinatario',
          'responsableActual': 'Operador Mock (123456)',
          'responsablePropuesto': 'Destinatario Mock (654321)',
          'bodegaActual': 'Almacén Central (Mock)',
          'bodegaPropuesta': 'Taller de Mantenimiento (Mock)',
          'motivoSolicitud': 'Trámite aprobado para pruebas de firmas/entrega',
          'articulos': [
            {
              'articulo': 'PC001',
              'nombre': 'Portátil Mock i7 16GB',
              'cantidad': 1.0,
              'placa': 'MOCK-001',
            },
          ],
        },
        {
          'id': 'TR-MOCK-102',
          'numeroDocumento': 102,
          'tipoDocumento': 'TS',
          'fecha': '2026-09-17',
          'estado': 'pe',
          'personaFuente': 'operador',
          'personaDestino': 'destinatario',
          'responsableActual': 'Operador Mock (123456)',
          'responsablePropuesto': 'Destinatario Mock (654321)',
          'bodegaActual': 'Almacén Central (Mock)',
          'bodegaPropuesta': 'Taller de Mantenimiento (Mock)',
          'motivoSolicitud': 'Trámite pendiente para pruebas de aprobación',
          'articulos': [
            {
              'articulo': 'IM002',
              'nombre': 'Impresora Láser Mock',
              'cantidad': 1.0,
              'placa': 'MOCK-002',
            },
          ],
        },
      ];
    }

    // 6. Detalle individual de un traspaso
    if (path.contains('/api/v1/traspasos/get/')) {
      final id = path.split('/').last;
      return {
        'id': id,
        'numeroDocumento': 101,
        'tipoDocumento': 'TS',
        'fecha': '2026-09-17',
        'estado': 'ap',
        'personaFuente': 'operador',
        'personaDestino': 'destinatario',
        'responsableActual': 'Operador Mock (123456)',
        'responsablePropuesto': 'Destinatario Mock (654321)',
        'bodegaActual': 'Almacén Central (Mock)',
        'bodegaPropuesta': 'Taller de Mantenimiento (Mock)',
        'motivoSolicitud': 'Detalle simulado de traspaso en entorno Mock',
        'articulos': [
          {
            'articulo': 'PC001',
            'nombre': 'Portátil Mock i7 16GB',
            'cantidad': 1.0,
            'placa': 'MOCK-001',
          },
        ],
      };
    }

    // 7. Búsqueda de empleados y colaboradores
    if (path.contains('/api/v1/personal/buscar')) {
      return [
        {
          'cedula': '123456',
          'nombre': 'Operador Mock',
          'codigoBodega': 'BOG001',
        },
        {
          'cedula': '654321',
          'nombre': 'Destinatario Mock',
          'codigoBodega': 'MED002',
        },
      ];
    }

    // 8. Personas / Colaboradores por bodega en traspasos
    if (path.contains('/api/v1/traspasos/personas')) {
      return [
        {
          'codigo': 'operador',
          'nombre': 'Operador Mock',
          'cedula': '123456',
          'bodega': 'BOG001',
        },
        {
          'codigo': 'destinatario',
          'nombre': 'Destinatario Mock',
          'cedula': '654321',
          'bodega': 'MED002',
        },
      ];
    }

    // 9. Activos fijos por responsable en traspasos
    if (path.contains('/api/v1/traspasos/activos')) {
      return [
        {
          'articulo': 'PC001',
          'nombre': 'Portátil Mock i7 16GB',
          'placa': 'MOCK-001',
          'responsable': 'operador',
          'bodega': 'BOG001',
        },
        {
          'articulo': 'IM002',
          'nombre': 'Impresora Láser Mock',
          'placa': 'MOCK-002',
          'responsable': 'operador',
          'bodega': 'BOG001',
        },
      ];
    }

    // 10. Requisiciones
    if (path.contains('/api/v1/requisiciones')) {
      return [
        {
          'id': 'REQ-MOCK-001',
          'numeroDocumento': 501,
          'tipoDocumento': 'RQ',
          'fecha': '2026-09-17',
          'estado': 'in',
          'observacion': 'Requisición de prueba en entorno Mock',
          'solicitante': 'Operador Mock',
          'bodega': 'BOG001',
          'articulos': [
            {
              'articulo': 'PC001',
              'descripcion': 'Portátil Mock i7 16GB',
              'cantidad': 1,
            },
          ],
        },
      ];
    }

    // 11. Conteo físico (pendientes)
    if (path.contains('/api/v1/conteo-fisico/pendientes') ||
        path.contains('/api/v1/bodegas/conteo-pendientes/')) {
      return [];
    }

    // 12. Geolocalización de activos
    if (path.contains('/api/v1/geolocalizacion-activos/buscar/')) {
      return {
        'idRegistro': 1,
        'latitud': 4.7110,
        'longitud': -74.0721,
      };
    }
    if (path.contains('/api/v1/geolocalizacion-activos/listar')) {
      return [];
    }

    // 13. Health check
    if (path.contains('/api/v1/health')) {
      return {'status': 'UP', 'mock': true};
    }

    // Fallback por defecto para cualquier otro GET
    return [];
  }
}
