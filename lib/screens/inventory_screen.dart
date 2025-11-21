import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../models/warehouse_model.dart';
import '../services/mock_inventory_service.dart';

// Definición de un modelo especial para la opción "Todas las Bodegas"
const WarehouseModel _allWarehousesFilter = WarehouseModel(
  id: 'ALL',
  name: 'Todas las Bodegas (Inventario Total)'
);

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final MockInventoryService _service = MockInventoryService();
  final Color primaryColor = Colors.orange.shade700;

  // --- Estado para Artículos ---
  List<ArticleModel> _allArticles = [];
  
  // --- Estado para Bodegas (Filtro) ---
  List<WarehouseModel> _warehouses = [];
  WarehouseModel? _selectedWarehouse; // Bodega seleccionada para filtrar

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Carga inicial de todos los artículos y bodegas
  void _loadData() {
    _allArticles = _service.getArticles();
    
    // Obtenemos la lista de bodegas, y añadimos la opción "Todas" al inicio
    List<WarehouseModel> loadedWarehouses = _service.getWarehouses();
    _warehouses = [_allWarehousesFilter, ...loadedWarehouses];
    
    // Inicializamos con la opción "Todas las Bodegas"
    _selectedWarehouse = _allWarehousesFilter;
    
    // No necesitamos setState aquí porque initState ya lo llama implícitamente
  }

  // Propiedad calculada para obtener la lista de artículos filtrada
  List<ArticleModel> get _filteredArticles {
    if (_selectedWarehouse == null || _selectedWarehouse!.id == _allWarehousesFilter.id) {
      return _allArticles; // Mostrar todos si no hay filtro o se selecciona 'Todas'
    }
    // Filtrar por el ID del centro de costos (Bodega)
    return _allArticles
        .where((article) => article.warehouse == _selectedWarehouse!.id)
        .toList();
  }

  // Widget para construir la tarjeta de un solo artículo
  Widget _buildArticleTile(ArticleModel article) {
    final warehouseName = _warehouses.firstWhere(
      (w) => w.id == article.warehouse,
      orElse: () => const WarehouseModel(id: '?', name: 'Desconocida')
    ).name;

    final String responsibleText = article.responsible != null && article.responsible!.isNotEmpty
      ? 'Responsable: ${article.responsible!}'
      : 'Responsable: No asignado'; 

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(Icons.qr_code_2, color: primaryColor, size: 40),
        title: Text(
          article.name, 
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Placa: ${article.licensePlate}'),
            Text(responsibleText), 
            Text('Centro de Costos: $warehouseName (${article.warehouse})'), 
            if (article.latitude != null) 
              Text('Ubicación: Lat ${article.latitude!.toStringAsFixed(4)}, Lon ${article.longitude!.toStringAsFixed(4)}'),
            if (article.latitude == null) 
              const Text('Ubicación: Sin registro GPS', style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          _showArticleDetailsDialog(article); 
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de Activos'),
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false, 
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Selector de Bodega ---
            _buildWarehouseSelector(),
            const SizedBox(height: 20),
            
            // --- Encabezado de la lista ---
            Text(
              'Activos mostrados: ${_filteredArticles.length}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const Divider(height: 20),
            
            // --- Lista de Artículos (Filtrada) ---
            Expanded(
              child: ListView.builder(
                itemCount: _filteredArticles.length,
                itemBuilder: (context, index) {
                  final article = _filteredArticles[index];
                  // El usuario pidió que _buildArticleTile se muestre después de la lista de bodegas,
                  // y lo hemos implementado en este ListView.builder
                  return _buildArticleTile(article);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para el DropdownButtonFormField de la Bodega
  Widget _buildWarehouseSelector() {
    return DropdownButtonFormField<WarehouseModel>(
      decoration: InputDecoration(
        labelText: 'Filtrar por Bodega',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.location_on, color: primaryColor),
      ),
      value: _selectedWarehouse,
      items: _warehouses.map((warehouse) {
        return DropdownMenuItem<WarehouseModel>(
          value: warehouse, 
          child: Text(warehouse.name),
        );
      }).toList(),
      onChanged: (WarehouseModel? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedWarehouse = newValue;
          });
        }
      },
    );
  }

  // Función para mostrar los detalles completos del activo en un diálogo
  void _showArticleDetailsDialog(ArticleModel article) {
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
                // Detalle del activo usando el helper (corregidos a 'id' y 'costCenterId')
                _buildDetailRow('Placa', article.licensePlate, Icons.confirmation_number),
                _buildDetailRow('ID del Activo', article.id, Icons.vpn_key), 
                _buildDetailRow('Responsable', article.responsible, Icons.person_pin),
                _buildDetailRow('Centro de Costos (ID)', article.warehouse, Icons.business),
                
                const Divider(height: 20, color: Colors.grey),

                // Información de Ubicación (Manteniendo datos críticos de GPS)
                Text(
                  'Ubicación GPS Actual:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14),
                ),
                const SizedBox(height: 5),
                if (article.latitude != null) ...[
                  Text('Latitud: ${article.latitude!.toStringAsFixed(6)}'),
                  Text('Longitud: ${article.longitude!.toStringAsFixed(6)}'),
                ] else
                  const Text('Sin ubicación registrada.', style: TextStyle(fontStyle: FontStyle.italic)),
                
                const Divider(height: 20, color: Colors.grey),
                
                // Datos QR Codificados
                Text(
                  'Datos QR Codificados:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14),
                ),
                // Usamos un tamaño de fuente pequeño para la cadena JSON
                Text(article.qrData, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar', style: TextStyle(color: primaryColor)),
            ),
            TextButton.icon(
              icon: Icon(Icons.gps_fixed, color: primaryColor),
              label: Text('Actualizar Ubicación', style: TextStyle(color: primaryColor)),
              onPressed: () {
                Navigator.of(context).pop(); 
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Simulando escaneo para actualizar GPS...')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Helper widget para construir una fila de detalle con ícono y título/valor
  Widget _buildDetailRow(String title, String? value, IconData icon) {
    // Si el valor es nulo o vacío, usamos 'No asignado' y cambiamos el estilo
    final displayValue = value != null && value.isNotEmpty ? value : 'No asignado';
    final isNotAssigned = value == null || value.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono del detalle
          Icon(icon, size: 20, color: isNotAssigned ? Colors.grey.shade400 : primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título del campo
                Text(
                  '$title:',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                ),
                // Valor del campo
                Text(
                  displayValue,
                  style: TextStyle(
                    fontStyle: isNotAssigned ? FontStyle.italic : FontStyle.normal,
                    color: isNotAssigned ? Colors.grey.shade600 : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}