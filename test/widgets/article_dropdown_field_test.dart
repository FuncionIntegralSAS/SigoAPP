import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo_app/modules/inventory/models/article_model.dart';
import 'package:sigo_app/shared/widgets/article_dropdown_field.dart';

void main() {
  group('ArticleDropdownField Tests', () {
    const art1 = ArticleModel(
      id: 101,
      codigoActivo: 'ACT001',
      nombre: 'Computador Portatil HP',
      placa: 'PLA-991',
      bodega: 'B01',
    );

    const art2 = ArticleModel(
      id: 102,
      codigoActivo: 'ACT002',
      nombre: 'Monitor LG 27 Pulgadas',
      placa: '',
      bodega: 'B01',
    );

    Widget createTestWidget({
      ArticleModel? value,
      List<ArticleModel> articles = const [],
      ValueChanged<ArticleModel?>? onChanged,
      bool isLoading = false,
      bool allowClear = false,
      String labelText = 'Activo / Artículo',
      bool isRequired = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ArticleDropdownField(
              value: value,
              articles: articles,
              onChanged: onChanged ?? (_) {},
              isLoading: isLoading,
              allowClear: allowClear,
              labelText: labelText,
              isRequired: isRequired,
            ),
          ),
        ),
      );
    }

    testWidgets('Renderiza etiqueta con formato estandarizado "código - placa - descripción"', (tester) async {
      await tester.pumpWidget(createTestWidget(
        articles: [art1, art2],
        value: art1,
      ));
      await tester.pumpAndSettle();

      // Debe mostrar el formato exacto código - placa - descripción
      expect(find.text('ACT001 - PLA-991 - Computador Portatil HP'), findsOneWidget);
    });

    testWidgets('Muestra N/A cuando la placa está vacía', (tester) async {
      await tester.pumpWidget(createTestWidget(
        articles: [art1, art2],
        value: art2,
      ));
      await tester.pumpAndSettle();

      // Al no tener placa, debe mostrar N/A en esa posición
      expect(find.text('ACT002 - N/A - Monitor LG 27 Pulgadas'), findsOneWidget);
    });

    testWidgets('Muestra texto instructivo de carga cuando isLoading es true', (tester) async {
      await tester.pumpWidget(createTestWidget(
        articles: const [],
        isLoading: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cargando activos...'), findsOneWidget);
    });

    testWidgets('Muestra "No hay activos disponibles" cuando la lista está vacía', (tester) async {
      await tester.pumpWidget(createTestWidget(
        articles: const [],
        isLoading: false,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No hay activos disponibles'), findsOneWidget);
    });

    testWidgets('Desduplica automáticamente artículos con mismos datos para evitar aserciones en DropdownButton2', (tester) async {
      // Pasamos dos artículos idénticos
      final duplicateArticles = <ArticleModel>[art1, art1, art2];

      await tester.pumpWidget(createTestWidget(
        articles: duplicateArticles,
        value: art1,
      ));
      await tester.pumpAndSettle();

      // No debe lanzar AssertionError de items duplicados
      expect(find.text('ACT001 - PLA-991 - Computador Portatil HP'), findsOneWidget);
    });

    testWidgets('Permite seleccionar un elemento y dispara onChanged', (tester) async {
      ArticleModel? selected;

      await tester.pumpWidget(createTestWidget(
        articles: [art1, art2],
        onChanged: (val) => selected = val,
      ));
      await tester.pumpAndSettle();

      // Tocar el dropdown para desplegarlo
      await tester.tap(find.byType(ArticleDropdownField));
      await tester.pumpAndSettle();

      // Seleccionar el segundo item en el menú
      await tester.tap(find.text('ACT002 - N/A - Monitor LG 27 Pulgadas').last);
      await tester.pumpAndSettle();

      expect(selected, art2);
    });

    testWidgets('Permite limpiar la selección si allowClear es true', (tester) async {
      ArticleModel? selected = art1;

      await tester.pumpWidget(createTestWidget(
        articles: [art1, art2],
        value: art1,
        allowClear: true,
        onChanged: (val) => selected = val,
      ));
      await tester.pumpAndSettle();

      // Tocar el botón de limpiar
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(selected, isNull);
    });
  });
}
