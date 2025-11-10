import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../models/warehouse_model.dart';
import '../services/mock_inventory_service.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Instancia del servicio mock para obtener todos los artículos.
    final MockInventoryService service = MockInventoryService();
    // En un futuro, podrías combinar esta lista con la información de bodegas.
    final List<ArticleModel> allArticles = service.getWarehouses()
        .map((w) => service.getArticlesByWarehouseId(w.id))
        .expand((list) => list) // Aplanamos la lista de listas en una sola lista
        .toList();

    const Color primaryColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de Activos'),
        backgroundColor: primaryColor,
        // No hay botón de retroceso porque es una pestaña principal
        automaticallyImplyLeading: false, 
      ),
      body: allArticles.isEmpty
          ? const Center(
              child: Text(
                'No hay artículos en el inventario.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: allArticles.length,
              itemBuilder: (context, index) {
                final article = allArticles[index];
                return _buildArticleTile(context, article, primaryColor);
              },
            ),
    );
  }

  // Widget para construir cada elemento de la lista (ListTile)
  Widget _buildArticleTile(BuildContext context, ArticleModel article, Color primaryColor) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Icon(Icons.inventory_2, color: primaryColor),
        ),
        title: Text(
          article.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Placa: ${article.licensePlate}'),
            Text('Código: ${article.code}'),
            Text('Responsable: ${article.responsible}'),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: () {
          // Mostrar un modal con la información completa del activo
          _showArticleDetails(context, article, primaryColor);
        },
      ),
    );
  }
  
  // Función para mostrar los detalles completos del activo en un diálogo
  void _showArticleDetails(BuildContext context, ArticleModel article, Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(article.name, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Placa', article.licensePlate, Icons.confirmation_number),
                _buildDetailRow('Código', article.code, Icons.vpn_key),
                _buildDetailRow('Responsable', article.responsible, Icons.person),
                _buildDetailRow('Centro de Costos (ID)', article.costCenter, Icons.business),
                const Divider(height: 20, color: Colors.grey),
                Text(
                  'Datos QR Codificados:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                ),
                Text(article.qrData, style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar', style: TextStyle(color: primaryColor)),
            ),
          ],
        );
      },
    );
  }
  
  // Helper para crear filas de detalle
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}