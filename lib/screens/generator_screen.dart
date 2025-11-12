import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
// Importamos los modelos y el servicio mock
import '../models/warehouse_model.dart';
import '../models/article_model.dart';
import '../services/mock_inventory_service.dart';
import 'package:geolocator/geolocator.dart';

class GeneratorScreen extends StatefulWidget {
 const GeneratorScreen({super.key});

 @override
 State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {

  bool _isGenerating = false;

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
  
 // ESTADO: Contiene los datos del QR solo después de presionar el botón.
  String? _dataToEncodeForQR; 
  
  // ESTADO: Para mostrar la ubicación en la UI
  String _currentLocationDisplay = 'Ubicación no registrada';

  
 @override
 void initState() {
  super.initState();
  // Cargamos las bodegas al iniciar la pantalla
  _warehouses = _service.getWarehouses();
 }
  
  
  // FUNCIÓN: obtención de la geolocalización.
  Future<Map<String, double>> _getLocation() async {
    
    // Verificar si el servicio de ubicación está habilitado:
       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
       if (!serviceEnabled) { 
          // Mostrar error al usuario
          throw Exception('Servicio de ubicación deshabilitado.');
       }
      
      // Solicitar y verificar permisos de ubicación:
       LocationPermission permission = await Geolocator.checkPermission();
       if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied || 
              permission == LocationPermission.deniedForever) {
              // Mostrar error si el permiso es denegado
              throw Exception('Permisos de ubicación denegados.');
          }
       }

    setState(() {
      _isGenerating = true;
      _message = 'Obteniendo ubicación... (Simulación)';
    });

    final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // Nivel de precisión solicitado
          timeLimit: Duration(seconds: 10), // Tiempo máximo para la lectura
        )
    );

    setState(() {
      _isGenerating = false;
    });
    return {'latitude': position.latitude, 'longitude': position.longitude};
  }

  // Función que se ejecuta al seleccionar una nueva bodega
 void _onWarehouseSelected(WarehouseModel? warehouse) {
  setState(() {
   _selectedWarehouse = warehouse;
   _selectedArticle = null; // Reiniciamos la selección del artículo
      // Reiniciamos el QR al cambiar de bodega
      _dataToEncodeForQR = null; 
      _currentLocationDisplay = 'Ubicación no registrada'; 
   
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
      // Reiniciamos el display de ubicación, pero preservamos si el artículo ya tenía una (en un escenario real)
      _currentLocationDisplay = (article?.latitude != null) 
          ? 'Lat: ${article!.latitude!.toStringAsFixed(4)}, Lon: ${article.longitude!.toStringAsFixed(4)} (Previa)'
          : 'Ubicación no registrada'; 
   
   if (article != null) {
    _message = 'Activo seleccionado: ${article.name}';
   } else {
    _message = _selectedWarehouse != null 
     ? 'Seleccione un activo de ${_selectedWarehouse!.name}' 
     : 'Seleccione una bodega y un activo.';
   }
  });
 }
 
 // Función que se ejecuta SOLO al presionar el botón de generación.
  void _generateQr() async {
    if (_selectedArticle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un activo para generar el QR.')),
      );
      return;
    }

    try {
      // 1. OBTENER LA UBICACIÓN (Simulada o Real)
      final locationData = await _getLocation();
      final lat = locationData['latitude']!;
      final lon = locationData['longitude']!;

      // 2. ACTUALIZAR EL ARTÍCULO SELECCIONADO con la ubicación.
      final updatedArticle = _selectedArticle!.copyWith(
        latitude: lat,
        longitude: lon,
      );
      
      _currentLocationDisplay = 'Lat: ${lat.toStringAsFixed(6)}, Lon: ${lon.toStringAsFixed(6)}';
      
      // 3. Reemplazamos la instancia en el estado y en la lista mock
      _service.updateArticle(updatedArticle);
      
      setState(() {
        _selectedArticle = updatedArticle;
        // 4. Asignamos el dato del QR (que ahora incluye la ubicación)
        _dataToEncodeForQR = _selectedArticle!.qrData; 
        _message = '✅ Ubicación obtenida y registrada en el activo.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR generado con ubicación para ${_selectedArticle!.name}')),
      );

    } catch (e) {
      setState(() {
        _isGenerating = false;
        _message = 'Error de Ubicación: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener ubicación: $e')),
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

            // Display de Ubicación
            Text('3. Ubicación Registrada:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.location_on, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentLocationDisplay,
                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
      
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
          _dataToEncodeForQR == null ? _message : 'Error al generar QR: $err',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
         ),
        ),
       ),
      ),
      
      const SizedBox(height: 20),

      // 5. Muestra los datos codificados
      Text('Datos Codificados (incluye Lat/Lon):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
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
    isArticleSelected ? 'Generar Código QR y Ubicación' : 'Seleccione un Activo',
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