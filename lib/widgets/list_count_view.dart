import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigo_app/providers/active_count_provider.dart';

class ListCountView extends StatelessWidget {
  final ActiveCountProvider provider;
  const ListCountView({super.key, required this.provider});

  void _showNumericKeyboard(
    BuildContext context,
    String articleId,
    String descripcion,
  ) {
    final TextEditingController qtyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cantidad Física: $articleId - $descripcion'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Cantidad Física',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(qtyController.text);
              if (val != null && val >= 0) {
                provider.recordCount(articleId, val.toDouble());
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final masterList = provider.masterItems.entries.toList();

    if (masterList.isEmpty) {
      return const Center(child: Text('El maestro de artículos está vacío.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: DataTable(
        showCheckboxColumn: false,
        columnSpacing: 24,
        headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
        columns: const [
          DataColumn(label: Text('Código')),
          DataColumn(label: Text('Descripción')),
          DataColumn(label: Text('Cantidad')),
        ],
        rows: masterList.map((entry) {
          final articleId = entry.key;
          final data = entry.value;
          final descripcion = data['descripcion'] as String;
          final countedQty = provider.currentIterationRecords[articleId] ?? 0.0;
          return DataRow(
            cells: [
              DataCell(Text(articleId)),
              DataCell(Text(descripcion)),
              DataCell(Text(countedQty.toStringAsFixed(0))),
            ],
            onSelectChanged: (_) =>
                _showNumericKeyboard(context, articleId, descripcion),
          );
        }).toList(),
      ),
    );
  }
}
