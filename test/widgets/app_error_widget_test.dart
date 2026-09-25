import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/shared/widgets/app_error_widget.dart';

void main() {
  group('AppErrorWidget Tests', () {
    testWidgets('AppErrorWidget.inline renderiza texto e icono correctamente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorWidget.inline(
              message: 'Campo requerido',
            ),
          ),
        ),
      );

      expect(find.text('Campo requerido'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('AppErrorWidget.inline con isWarning renderiza icono de advertencia', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorWidget.inline(
              message: 'Advertencia de prueba',
              isWarning: true,
            ),
          ),
        ),
      );

      expect(find.text('Advertencia de prueba'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('AppErrorWidget.banner renderiza título, mensaje, reintento y detalles', (tester) async {
      bool retried = false;
      bool detailsShown = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget.banner(
              title: 'ERROR EN CONSULTA',
              message: 'No fue posible cargar los activos del colaborador.',
              onRetry: () => retried = true,
              onShowDetails: () => detailsShown = true,
            ),
          ),
        ),
      );

      expect(find.text('ERROR EN CONSULTA'), findsOneWidget);
      expect(find.text('No fue posible cargar los activos del colaborador.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Ver detalle'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      expect(retried, isTrue);

      await tester.tap(find.text('Ver detalle'));
      expect(detailsShown, isTrue);
    });

    testWidgets('AppErrorWidget.view renderiza vista completa centrada', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget.view(
              title: 'Error Crítico',
              message: 'Error al conectar con la base de datos.',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Error Crítico'), findsOneWidget);
      expect(find.text('Error al conectar con la base de datos.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      expect(retried, isTrue);
    });
  });
}
