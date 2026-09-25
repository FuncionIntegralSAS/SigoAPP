import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/exceptions/transfer_business_exception.dart';
import 'package:sigo_app/modules/physical_count/providers/physical_count_provider.dart';
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

    test('extractFriendlyMessage extrae mensaje de negocio tras pipe en package body sin prefijo ORA', () {
      const rawError =
          'Error al realizar el proceso:package body SRFPNA CUA.PKG_FI_REQUISICION.PRO_ENTREGAR_LINEA. 0 70 |Usuario no autorizado Para realizar el Tramite';

      final result = DialogUtils.extractFriendlyMessage(rawError);

      expect(result, 'Usuario no autorizado Para realizar el Tramite');
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

    testWidgets('showInferredErrorDialog infiere correctamente los datos desde TransferBusinessException', (tester) async {
      const exception = TransferBusinessException(
        'La bodega origen no permite traspasos',
        technicalDetails: 'Code: -1 | Bodega FI no permitida',
        statusCode: 400,
        endpoint: 'POST /api/v1/traspasos/crear',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DialogUtils.showInferredErrorDialog(
                    context,
                    title: 'Error de Traspaso',
                    error: exception,
                  );
                },
                child: const Text('Abrir Inferido'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Inferido'));
      await tester.pumpAndSettle();

      expect(find.text('Error de Traspaso'), findsOneWidget);
      expect(find.text('La bodega origen no permite traspasos'), findsOneWidget);

      await tester.tap(find.text('Ver detalles técnicos (Desarrollador)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Code: -1 | Bodega FI no permitida'), findsOneWidget);
    });

    testWidgets('showInferredErrorDialog maneja strings directos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DialogUtils.showInferredErrorDialog(
                    context,
                    title: 'Error Simple',
                    error: 'Error de validación manual',
                  );
                },
                child: const Text('Abrir String'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir String'));
      await tester.pumpAndSettle();

      expect(find.text('Error Simple'), findsOneWidget);
      expect(find.text('Error de validación manual'), findsOneWidget);
    });

    testWidgets('showPendingWarehousesErrorDialog muestra modal estandarizado y limpia error al aceptar', (tester) async {
      final fakeProvider = _FakePhysicalCountProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DialogUtils.showPendingWarehousesErrorDialog(context, fakeProvider);
                },
                child: const Text('Abrir Error Bodegas'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Error Bodegas'));
      await tester.pumpAndSettle();

      expect(find.text('Error en Bodegas Pendientes'), findsOneWidget);
      expect(find.text('No fue posible cargar las bodegas pendientes.'), findsOneWidget);
      expect(find.text('Aceptar'), findsOneWidget);

      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      // Debe haber cerrado el diálogo y limpiado el error en el provider
      expect(find.text('Error en Bodegas Pendientes'), findsNothing);
      expect(fakeProvider.pendingWarehousesErrorMessage, isNull);
    });
  });

  group('DialogUtils Feedback, SnackBars & Modals Tests', () {
    testWidgets('showSuccessSnackBar muestra SnackBar con verde institucional e icono check', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DialogUtils.showSuccessSnackBar(
                    context,
                    'Operación realizada con éxito',
                  );
                },
                child: const Text('Mostrar Éxito'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mostrar Éxito'));
      await tester.pump();

      expect(find.text('Operación realizada con éxito'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.green.shade700);
      expect(snackBar.behavior, SnackBarBehavior.floating);

      await tester.pumpAndSettle();
    });

    testWidgets('showInfoSnackBar muestra SnackBar con azul institucional e icono de info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DialogUtils.showInfoSnackBar(
                    context,
                    'Información de proceso',
                  );
                },
                child: const Text('Mostrar Info'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mostrar Info'));
      await tester.pump();

      expect(find.text('Información de proceso'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.blue.shade800);
      expect(snackBar.behavior, SnackBarBehavior.floating);

      await tester.pumpAndSettle();
    });

    testWidgets('showWarningSnackBar muestra SnackBar con ámbar institucional e icono de advertencia', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DialogUtils.showWarningSnackBar(
                    context,
                    'Advertencia de límite de negocio',
                  );
                },
                child: const Text('Mostrar Advertencia'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mostrar Advertencia'));
      await tester.pump();

      expect(find.text('Advertencia de límite de negocio'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.amber.shade800);
      expect(snackBar.behavior, SnackBarBehavior.floating);

      await tester.pumpAndSettle();
    });

    testWidgets('showConfirmationDialog retorna true al confirmar, false al cancelar y aplica color destructivo', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await DialogUtils.showConfirmationDialog(
                    context,
                    title: '¿Confirmar Acción?',
                    message: 'Esta acción no se puede deshacer.',
                    confirmText: 'Eliminar',
                    cancelText: 'Cancelar',
                    isDestructive: true,
                    icon: Icons.delete_outline,
                  );
                },
                child: const Text('Abrir Confirmación'),
              ),
            ),
          ),
        ),
      );

      // 1. Abrir diálogo y cancelar
      await tester.tap(find.text('Abrir Confirmación'));
      await tester.pumpAndSettle();

      expect(find.text('¿Confirmar Acción?'), findsOneWidget);
      expect(find.text('Esta acción no se puede deshacer.'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Eliminar'),
      );
      expect(confirmBtn.style?.backgroundColor?.resolve({}), Colors.red.shade700);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(dialogResult, isFalse);

      // 2. Abrir diálogo y confirmar
      await tester.tap(find.text('Abrir Confirmación'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      expect(dialogResult, isTrue);
    });

    testWidgets('showSuccessDialog despliega modal con icono verde y ejecuta onAccept al presionar el botón', (tester) async {
      bool accepted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DialogUtils.showSuccessDialog(
                    context,
                    title: 'Proceso Exitoso',
                    message: 'La operación finalizó correctamente.',
                    buttonText: 'Aceptar',
                    onAccept: () {
                      accepted = true;
                    },
                  );
                },
                child: const Text('Abrir Modal Éxito'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Modal Éxito'));
      await tester.pumpAndSettle();

      expect(find.text('Proceso Exitoso'), findsOneWidget);
      expect(find.text('La operación finalizó correctamente.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('Aceptar'), findsOneWidget);

      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(find.text('Proceso Exitoso'), findsNothing);
      expect(accepted, isTrue);
    });
  });
}

class _FakePhysicalCountProvider extends Fake implements PhysicalCountProvider {
  String? _error = 'No fue posible cargar las bodegas pendientes.';

  @override
  String? get pendingWarehousesErrorMessage => _error;

  @override
  void clearPendingWarehousesError() {
    _error = null;
  }
}
