import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/utils/dialog_utils.dart';

void main() {
  group('DialogUtils Error Sanitization & Parsing Tests', () {
    test('extractFriendlyMessage extrae el mensaje de negocio de un ORA con pipe y stack de Spring Boot/Hikari', () {
      const rawError =
          'Error al realizar el proceso:Error ejecutando PKG_FI_MOVITRAS.pro_recibir: '
          'Error calling CallableStatement.getMoreResults [ORA-20008: package body '
          'SRFPNACUA.PKG_FI_MOVITRAS.PRO_RECIBIR.8  121|Bodega Destino [2612] o Bodega Fuente [F571] '
          'Deben ser de Tipo Personal ORA-06512: en "SRFPNACUA.PKG_FI_MOVITRAS", línea 1215 '
          'ORA-06512: en línea 1 https://docs.oracle.com/error-help/db/ora-20008/] '
          '[HikariProxyCallableStatement@735088809 wrapping oracle.jdbc.driver.OracleCallableStatementWrapper@27438a27]';

      final result = DialogUtils.extractFriendlyMessage(rawError);

      expect(result, 'Bodega Destino [2612] o Bodega Fuente [F571] Deben ser de Tipo Personal');
    });

    test('extractFriendlyMessage extrae ORA-20001 estándar sin pipe', () {
      const rawError =
          'ORA-20001: La persona fuente y la persona destino no pueden ser la misma ORA-06512: en linea 1';

      final result = DialogUtils.extractFriendlyMessage(rawError);

      expect(result, 'La persona fuente y la persona destino no pueden ser la misma');
    });

    test('extractFriendlyMessage limpia prefijos de Spring Boot y CallableStatement', () {
      const rawError =
          'Error al realizar el proceso:Error ejecutando PKG_FI_MOVITRAS.pro_crear_solicitud: '
          'No se encontraron artículos autorizados para el colaborador';

      final result = DialogUtils.extractFriendlyMessage(rawError);

      expect(result, 'No se encontraron artículos autorizados para el colaborador');
    });

    test('extractFriendlyMessage mantiene mensaje limpio si no contiene trazas de BD', () {
      const cleanMsg = 'Error de conexión con el servidor. Verifique su red.';

      final result = DialogUtils.extractFriendlyMessage(cleanMsg);

      expect(result, cleanMsg);
    });

    testWidgets('showErrorDialog muestra el mensaje amigable en el cuerpo principal y el error completo en detalles técnicos', (tester) async {
      const rawError =
          'Error al realizar el proceso:Error ejecutando PKG_FI_MOVITRAS.pro_recibir: '
          'Error calling CallableStatement.getMoreResults [ORA-20008: package body '
          'SRFPNACUA.PKG_FI_MOVITRAS.PRO_RECIBIR.8  121|Bodega Destino [2612] o Bodega Fuente [F571] '
          'Deben ser de Tipo Personal ORA-06512: en "SRFPNACUA.PKG_FI_MOVITRAS", línea 1215]';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DialogUtils.showErrorDialog(
                    context,
                    title: 'Error al Confirmar Recepción',
                    message: rawError,
                    endpoint: 'PUT /api/v1/traspasos/recibir/1045',
                  );
                },
                child: const Text('Abrir modal'),
              ),
            ),
          ),
        ),
      );

      // Presionar el botón para abrir el modal
      await tester.tap(find.text('Abrir modal'));
      await tester.pumpAndSettle();

      // 1. Debe mostrar el título
      expect(find.text('Error al Confirmar Recepción'), findsOneWidget);

      // 2. Debe mostrar la descripción amigable limpia en el cuerpo
      expect(
        find.text('Bodega Destino [2612] o Bodega Fuente [F571] Deben ser de Tipo Personal'),
        findsOneWidget,
      );

      // 3. No debe mostrar la traza larga de Spring Boot en el cuerpo inicial
      expect(find.textContaining('CallableStatement.getMoreResults'), findsNothing);

      // 4. Debe existir el botón para ver detalles técnicos
      expect(find.text('Ver detalles técnicos (Desarrollador)'), findsOneWidget);

      // 5. Al presionar "Ver detalles técnicos", debe desplegarse el error completo
      await tester.tap(find.text('Ver detalles técnicos (Desarrollador)'));
      await tester.pumpAndSettle();

      expect(find.text('Ocultar detalles técnicos'), findsOneWidget);
      expect(find.textContaining('CallableStatement.getMoreResults'), findsOneWidget);
      expect(find.textContaining('PUT /api/v1/traspasos/recibir/1045'), findsOneWidget);
      expect(find.text('Copiar detalle'), findsOneWidget);
    });

    testWidgets('showErrorDialog en pantalla estrecha con statusCode no desborda y no muestra badge en fila principal', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DialogUtils.showErrorDialog(
                    context,
                    title: 'Error al Confirmar Recepción',
                    message: 'Bodega Destino [2612] o Bodega Fuente [F571] Deben ser de Tipo Personal',
                    statusCode: 500,
                    endpoint: 'PUT /api/v1/traspasos/recibir/1045',
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // No debe haber badge de HTTP 500 en la fila principal
      expect(find.text('HTTP 500'), findsNothing);

      // No debe haber excepciones de desbordamiento (overflow)
      expect(tester.takeException(), isNull);
    });
  });
}
