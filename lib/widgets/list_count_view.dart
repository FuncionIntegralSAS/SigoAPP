import 'package:flutter/material.dart';
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
        title: Text('Inventariar: $articleId - $descripcion'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Cantidad Física Real',
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
              final val = double.tryParse(qtyController.text);
              if (val != null && val >= 0) {
                // Al ingresar manual, sobreescribimos o sumamos? Dependerá de las reglas,
                // Pero asumiendo registro limpio, guardamos lo que digita (como adición).
                // En un app real, podríamos mostrar lo contabilizado y sobreescribir.
                provider.recordCount(articleId, val);
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

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: masterList.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final articleId = masterList[index].key;
        final data = masterList[index].value;
        final name = data['descripcion'] as String;
        final countedQty = provider.currentIterationRecords[articleId] ?? 0.0;

        return ListTile(
          leading: const Icon(Icons.inventory_2, color: Colors.blueGrey),
          title: Text('$articleId - $name'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: countedQty > 0
                  ? Colors.green.shade100
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$countedQty',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: countedQty > 0 ? Colors.green.shade800 : Colors.black54,
              ),
            ),
          ),
          onTap: () => _showNumericKeyboard(context, articleId, name),
        );
      },
    );
  }
}
