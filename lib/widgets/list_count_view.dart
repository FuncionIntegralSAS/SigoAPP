import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigo_app/providers/active_count_provider.dart';

class ListCountView extends StatelessWidget {
  final ActiveCountProvider provider;
  const ListCountView({super.key, required this.provider});

  void _showNumericKeyboard(
    BuildContext context,
    String idArticulo,
    String descripcion,
  ) {
    final TextEditingController qtyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cantidad Física: $idArticulo - $descripcion'),
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
                provider.recordCount(idArticulo, val.toDouble());
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
          final idArticulo = entry.key;
          final data = entry.value;
          final descripcion = data['descripcion'] as String;
          final isCounted =
              provider.currentIterationRecords.containsKey(idArticulo);
          final countedQty = provider.currentIterationRecords[idArticulo] ?? 0.0;
          return DataRow(
            cells: [
              DataCell(Text(idArticulo)),
              DataCell(
                isCounted
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Registrado',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(descripcion),
              ),
              DataCell(Text(countedQty.toStringAsFixed(0))),
            ],
            onSelectChanged: (_) =>
                _showNumericKeyboard(context, idArticulo, descripcion),
          );
        }).toList(),
      ),
    );
  }
}
