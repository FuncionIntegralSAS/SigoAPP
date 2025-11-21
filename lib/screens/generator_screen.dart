import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/article_model.dart';
import '../models/warehouse_model.dart';
import '../services/mock_inventory_service.dart';

// El StatefulWidget para la pantalla de Generación de QR
class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  // Instancia única del servicio
  final MockInventoryService _service = MockInventoryService(); 

  // --- Estado de la Pantalla ---
  List<WarehouseModel> _warehouses = [];
  WarehouseModel? _selectedWarehouse; // Bodega seleccionada (Filtro 1)
  
  List<ArticleModel> _articles = [];
  ArticleModel? _selectedArticle; // Artículo seleccionado (Filtro 2)

  String _dataToEncodeForQR = 'Seleccione un Activo para Generar QR';
  bool _isGenerating = false;
  String _message = 'Seleccione el activo y presione "Generar QR".';
  
  final Color primaryColor = Colors.orange.shade700;

  @override
  void initState() {
    super.initState();  
    _loadInitialData();
  }

  // Carga inicial de Bodegas
  void _loadInitialData() {
    _warehouses = _service.getWarehouses();
    if (_warehouses.isNotEmpty) {
      // Inicializar con la primera bodega y cargar sus artículos
      _selectedWarehouse = _warehouses.first;
      _loadArticles(_selectedWarehouse!.id);
    }
  }

  // Carga de artículos basada en la Bodega seleccionada
  void _loadArticles(String costCenterId) {
    setState(() {
      // USANDO EL MÉTODO CORREGIDO del servicio
      _articles = _service.getArticlesByCostCenter(costCenterId); 
      _selectedArticle = null; // Reiniciar selección del artículo
      _dataToEncodeForQR = 'Seleccione un Activo para Generar QR';
    });
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
  
  // Función que se ejecuta SOLO al presionar el botón de generación.
  void _generateQr() async {
    if (_selectedArticle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un activo para generar el QR.')),
      );
      return;
    }

    try {
      // 1. OBTENER LA UBICACIÓN
      final locationData = await _getLocation();
      final lat = locationData['latitude']!;
      final lon = locationData['longitude']!;

      // 2. ACTUALIZAR EL ARTÍCULO SELECCIONADO con la ubicación.
      final updatedArticle = _selectedArticle!.copyWith(
        latitude: lat,
        longitude: lon,
      );
      
      // 3. Reemplazamos la instancia en el estado y en la lista mock
      _service.updateArticle(updatedArticle);
      
      setState(() {
        // Aseguramos que el selectedArticle se actualice
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


  // --- Estructura Visual (build) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generador de Código QR de Activo'),
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Selector de Bodega
            _buildWarehouseSelector(),
            const SizedBox(height: 20),

            // 2. Selector de Artículo
            _buildArticleSelector(),
            const SizedBox(height: 30),

            // 3. Botón de Generación
            _buildGenerateButton(),
            const SizedBox(height: 20),

            // 4. Mensaje de Estado
            Text(_message, 
              textAlign: TextAlign.center, 
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
            const SizedBox(height: 30),

            // 5. Contenedor del QR
            _buildQrDisplay(),
          ],
        ),
      ),
    );
  }

  // Widget de selección de Bodega
  Widget _buildWarehouseSelector() {
    return DropdownButtonFormField<WarehouseModel>(
      decoration: InputDecoration(
        labelText: '1. Seleccione Centro de Costos/Bodega',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.location_city, color: primaryColor),
      ),
      value: _selectedWarehouse,
      items: _warehouses.map((warehouse) {
        return DropdownMenuItem<WarehouseModel>(
          value: warehouse, 
          child: Text('${warehouse.name} (${warehouse.id})'),
        );
      }).toList(),
      onChanged: (WarehouseModel? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedWarehouse = newValue;
            _loadArticles(newValue.id); // Recargar artículos
          });
        }
      },
    );
  }

  // Widget de selección de Artículo
  Widget _buildArticleSelector() {
    return DropdownButtonFormField<ArticleModel>(
      decoration: InputDecoration(
        labelText: '2. Seleccione Activo para QR',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.vpn_key, color: primaryColor),
      ),
      value: _selectedArticle,
      items: _articles.map((article) {
        // Usamos la igualdad sobrecargada (==) para que Dart pueda determinar la selección
        return DropdownMenuItem<ArticleModel>(
          value: article, 
          child: Text('${article.name} (${article.licensePlate})'),
        );
      }).toList(),
      onChanged: _articles.isEmpty ? null : (ArticleModel? newValue) {
        setState(() {
          _selectedArticle = newValue;
          // Si se selecciona un artículo, mostramos sus datos QR actuales
          _dataToEncodeForQR = newValue?.qrData ?? 'Seleccione un Activo para Generar QR';
        });
      },
    );
  }

  // Widget del botón de Generación
  Widget _buildGenerateButton() {
    return ElevatedButton.icon(
      onPressed: _isGenerating || _selectedArticle == null ? null : _generateQr,
      icon: _isGenerating 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const SizedBox.shrink(), 
      label: Text(_isGenerating ? 'Generando QR...' : '3. Generar QR', style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 5,
      ),
    );
  }

  // Widget que muestra el código QR
  Widget _buildQrDisplay() {
    // Si la data es muy corta, indicamos que es un placeholder
    bool isPlaceholder = _dataToEncodeForQR.startsWith('Seleccione');

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Muestra el código QR usando el paquete qr_flutter
            QrImageView(
              data: _dataToEncodeForQR,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
              // Color de los módulos (los cuadraditos)
              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black), 
              dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Text(
              isPlaceholder ? 'Contenido del QR: (Esperando Activo)' : 'Contenido del QR:',
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
            ),
            // Muestra los datos codificados
            SelectableText(
              _dataToEncodeForQR,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: isPlaceholder ? 14 : 12, color: isPlaceholder ? Colors.grey : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}