import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
// Importamos los modelos y el servicio mock
import '../models/warehouse_model.dart';
import '../models/article_model.dart';
import '../services/mock_inventory_service.dart';

// Importaciones de PDF que mantienes para el futuro 
// import 'package:pdf/pdf.dart'; 
// import 'package:pdf/widgets.dart' as pw; 
// import 'package:path_provider/path_provider.dart'; 
// import 'package:open_filex/open_filex.dart'; 
// import 'dart:io';
// import 'dart:typed_data';


class GeneratorScreen extends StatefulWidget {
 const GeneratorScreen({super.key});

 @override
 State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
 // Instancia del servicio mock
 final MockInventoryService _service = MockInventoryService();
 
 // Estado de la pantalla
 WarehouseModel? _selectedWarehouse;
 ArticleModel? _selectedArticle;
 
 // Lista de bodegas y artículos
 late List<WarehouseModel> _warehouses;
 List<ArticleModel> _articlesInSelectedWarehouse = [];
 
 // Usamos este estado para mostrar los mensajes de guía
 String _message = 'Seleccione una bodega y un activo.';
  
 // NUEVO ESTADO: Contiene los datos del QR solo después de presionar el botón.
  String? _dataToEncodeForQR; 

 @override
 void initState() {
  super.initState();
  // Cargamos las bodegas al iniciar la pantalla
  _warehouses = _service.getWarehouses();
 }
 
 // Función que se ejecuta al seleccionar una nueva bodega
 void _onWarehouseSelected(WarehouseModel? warehouse) {
  setState(() {
   _selectedWarehouse = warehouse;
   _selectedArticle = null; // Reiniciamos la selección del artículo
      // Reiniciamos el QR al cambiar de bodega
      _dataToEncodeForQR = null; 
   
   if (warehouse != null) {
    // Filtramos los artículos de la bodega seleccionada
    _articlesInSelectedWarehouse = _service.getArticlesByWarehouseId(warehouse.id);
    _message = 'Seleccione un activo de ${warehouse.name}';
   } else {
    _articlesInSelectedWarehouse = [];
    _message = 'Seleccione una bodega y un activo.';
   }
  });
 }

 // Función que se ejecuta al seleccionar un artículo
 void _onArticleSelected(ArticleModel? article) {
  setState(() {
   _selectedArticle = article;
      // Reiniciamos el QR al cambiar de artículo
      _dataToEncodeForQR = null; 
   if (article != null) {
    // SOLO actualizamos el mensaje, NO el dato del QR.
    _message = 'Activo seleccionado: ${article.name}';
   } else {
    _message = _selectedWarehouse != null 
     ? 'Seleccione un activo de ${_selectedWarehouse!.name}' 
     : 'Seleccione una bodega y un activo.';
   }
  });
 }
 
 // Función que se ejecuta SOLO al presionar el botón de generación.
 void _generateQr() {
  if (_selectedArticle != null) {
      setState(() {
        // Asignamos el dato del QR AQUÍ
        _dataToEncodeForQR = _selectedArticle!.qrData; 
      });

   ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Generando código QR para ${_selectedArticle!.name}')),
   );
  } else {
   ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Debe seleccionar un activo para generar el QR.')),
   );
  }
 }


 @override
 Widget build(BuildContext context) {
  // Definición de estilos
  final bool isArticleSelected = _selectedArticle != null;
  final Color primaryColor = Colors.teal;

  return Scaffold(
   appBar: AppBar(
    title: const Text('Generador de Código QR por Activo'),
    backgroundColor: primaryColor,
   ),
   body: SingleChildScrollView(
    padding: const EdgeInsets.all(20.0),
    child: Column(
     crossAxisAlignment: CrossAxisAlignment.stretch,
     children: [
      // 1. Selector de Bodega
      Text('1. Seleccionar Bodega:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
      const SizedBox(height: 10),
      _buildWarehouseDropdown(primaryColor),

      const SizedBox(height: 20),

      // 2. Selector de Activo
      Text('2. Seleccionar Activo:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
      const SizedBox(height: 10),
      _buildArticleDropdown(primaryColor),

      const SizedBox(height: 30),

      // 3. Botón para Generar QR
      _buildGenerateButton(isArticleSelected, primaryColor),
      
      const SizedBox(height: 30),
      
      // 4. Visor del Código QR (Usa _dataToEncodeForQR)
      Center(
       child: QrImageView(
        data: _dataToEncodeForQR ?? 'Escanee o genere un código para empezar',
        version: QrVersions.auto,
        size: 200.0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        // Muestra un mensaje guía si no hay datos generados
        errorStateBuilder: (c, err) => Center(
         child: Text(
          _dataToEncodeForQR == null ? 'Seleccione y Genere el QR' : 'Error al generar QR: $err',
          textAlign: TextAlign.center,
         ),
        ),
       ),
      ),
      
      const SizedBox(height: 20),

      // 5. Muestra los datos codificados
      Text('Datos Codificados:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
      const SizedBox(height: 5),
      Text(_dataToEncodeForQR ?? 'Esperando generación...', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
     ],
    ),
   ),
  );
 }

 // Constructor del Dropdown de Bodegas
 Widget _buildWarehouseDropdown(Color primaryColor) {
  return DropdownButtonFormField<WarehouseModel>(
   decoration: InputDecoration(
    border: const OutlineInputBorder(),
    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 1.5)),
    labelText: 'Bodega / Centro de Costos',
   ),
   value: _selectedWarehouse,
   items: _warehouses.map((WarehouseModel warehouse) {
    return DropdownMenuItem<WarehouseModel>(
     value: warehouse,
     child: Text(warehouse.name),
    );
   }).toList(),
   onChanged: _onWarehouseSelected,
   hint: const Text('Seleccione una Bodega'),
  );
 }
 
 // Constructor del Dropdown de Artículos (dependiente de la bodega)
 Widget _buildArticleDropdown(Color primaryColor) {
  return DropdownButtonFormField<ArticleModel>(
   decoration: InputDecoration(
    border: const OutlineInputBorder(),
    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 1.5)),
    labelText: 'Activo / Artículo',
   ),
   value: _selectedArticle,
   // Deshabilitado si no hay bodega seleccionada o no hay artículos
   onChanged: _articlesInSelectedWarehouse.isNotEmpty ? _onArticleSelected : null,
   items: _articlesInSelectedWarehouse.map((ArticleModel article) {
    return DropdownMenuItem<ArticleModel>(
     value: article,
     child: Text('${article.name} (${article.licensePlate})'),
    );
   }).toList(),
   hint: Text(_selectedWarehouse == null ? 'Seleccione primero una Bodega' : 'Seleccione un Activo'),
  );
 }
 
 // Constructor del Botón de Generación
 Widget _buildGenerateButton(bool isArticleSelected, Color primaryColor) {
  return ElevatedButton.icon(
   onPressed: isArticleSelected ? _generateQr : null,
   icon: const Icon(Icons.qr_code, color: Colors.white),
   label: Text(
    isArticleSelected ? 'Generar Código QR' : 'Seleccione un Activo',
    style: const TextStyle(fontSize: 18, color: Colors.white),
   ),
   style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 15),
    backgroundColor: primaryColor,
    // Si está deshabilitado, el color de fondo se atenúa automáticamente
   ),
  );
 }
}