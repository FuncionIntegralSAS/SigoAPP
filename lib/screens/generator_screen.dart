import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/article_model.dart';
import '../models/warehouse_model.dart';
import '../services/mock_inventory_service.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../providers/printer_provider.dart';
import '../widgets/printer_connection_dialog.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../utils/dropdown_template.dart';

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

  final TextEditingController _warehouseSearchController = TextEditingController();
  final TextEditingController _articleSearchController = TextEditingController();
  final ValueNotifier<WarehouseModel?> _warehouseNotifier = ValueNotifier(null);
  final ValueNotifier<ArticleModel?> _articleNotifier = ValueNotifier(null);

  String _dataToEncodeForQR = 'Seleccione un Activo para Generar QR';
  bool _isGenerating = false;
  String _message = 'Seleccione el activo y presione "Generar QR".';

  final Color primaryColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _warehouseSearchController.dispose();
    _articleSearchController.dispose();
    _warehouseNotifier.dispose();
    _articleNotifier.dispose();
    super.dispose();
  }

  // Carga inicial de Bodegas
  void _loadInitialData() {
    _warehouses = _service.getWarehouses();
    if (_warehouses.isNotEmpty) {
      // Inicializar con la primera bodega y cargar sus artículos
      _selectedWarehouse = _warehouses.first;
      _warehouseNotifier.value = _selectedWarehouse;
      _loadArticles(_selectedWarehouse!.bodeCodi);
    }
  }

  // Carga de artículos basada en la Bodega seleccionada
  void _loadArticles(String costCenterId) {
    setState(() {
      // USANDO EL MÉTODO CORREGIDO del servicio
      _articles = _service.getArticlesByWarehouseId(costCenterId);
      _selectedArticle = null; // Reiniciar selección del artículo
      _articleNotifier.value = null;
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

    if (!mounted) return {'latitude': 0.0, 'longitude': 0.0};
    setState(() {
      _isGenerating = true;
      _message = 'Obteniendo ubicación... (Simulación)';
    });

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, // Nivel de precisión solicitado
        timeLimit: Duration(seconds: 10), // Tiempo máximo para la lectura
      ),
    );

    if (mounted) {
      setState(() {
        _isGenerating = false;
      });
    }
    return {'latitude': position.latitude, 'longitude': position.longitude};
  }

  // Función que se ejecuta SOLO al presionar el botón de generación.
  void _generateQr() async {
    if (_selectedArticle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un activo para generar el QR.'),
        ),
      );
      return;
    }

    try {
      // 1. OBTENER LA UBICACIÓN
      final locationData = await _getLocation();
      if (!mounted) return;
      final lat = locationData['latitude']!;
      final lon = locationData['longitude']!;

      // 2. ACTUALIZAR EL ARTÍCULO SELECCIONADO con la ubicación.
      final updatedArticle = _selectedArticle!.copyWith(
        latitude: lat,
        longitude: lon,
      );

      // 3. Reemplazamos la instancia en el estado y en la lista mock
      _service.updateArticle(updatedArticle);

      final newQrData = updatedArticle.qrData;

      setState(() {
        _selectedArticle = updatedArticle;
        _dataToEncodeForQR = newQrData;
        _message = 'Generando PDF e imprimiendo...';
      });

      // 4. Generar PDF (en paralelo)
      final pdfFile = await _generatePdfDocument(updatedArticle, newQrData);

      // 5. Enviar a impresión Bluetooth (si hay impresora conectada)
      if (!mounted) return;
      final printerProvider = Provider.of<PrinterProvider>(
        context,
        listen: false,
      );
      if (printerProvider.isConnected) {
        final printSuccess = await printerProvider.printQrTicket(
          newQrData,
          updatedArticle.name,
          updatedArticle.licensePlate,
        );
        if (!printSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error de impresión térmica: ${printerProvider.errorMessage}',
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'PDF generado. No hay impresora conectada para impresión térmica.',
              ),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _message = '✅ QR y PDF generados con éxito.';
        });
      }

      // (Opcional) Abrir el PDF generado
      OpenFilex.open(pdfFile.path);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _message = 'Error: $e';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error en el proceso: $e')));
      }
    }
  }

  // --- Método para generar PDF ---
  Future<File> _generatePdfDocument(ArticleModel article, String qrData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          5 * PdfPageFormat.cm,
          5 * PdfPageFormat.cm,
          marginAll: 0.2 * PdfPageFormat.cm,
        ),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Nombre: ${article.name}',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                  maxLines: 1,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Placa: ${article.licensePlate}',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrData,
                  width: 3.3 * PdfPageFormat.cm,
                  height: 3.3 * PdfPageFormat.cm,
                ),
              ],
            ),
          );
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/qr_${article.licensePlate}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // --- Estructura Visual (build) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generador de Código QR'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Impresora Bluetooth',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const PrinterConnectionDialog(),
              );
            },
          ),
        ],
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
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
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
    return DropdownButtonFormField2<WarehouseModel>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: '1. Seleccione Centro de Costos/Bodega',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.location_city, color: primaryColor),
      ),
      valueListenable: _warehouseNotifier,
      items: _warehouses.map((warehouse) {
        return DropdownItem(
          value: warehouse,
          child: Text(
            '${warehouse.bodeCodi} - ${warehouse.bodeDesc}',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: _isGenerating
          ? null
          : (WarehouseModel? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedWarehouse = newValue;
                  _warehouseNotifier.value = newValue;
                  _loadArticles(newValue.bodeCodi); // Recargar artículos
                });
              }
            },
      dropdownSearchData: DropdownTemplates.searchData(
        controller: _warehouseSearchController,
        hintText: 'Buscar bodega...',
        searchMatchFn: (item, searchValue) {
          final wh = item.value!;
          return wh.bodeDesc.toLowerCase().contains(searchValue.toLowerCase()) ||
              wh.bodeCodi.toLowerCase().contains(searchValue.toLowerCase());
        },
      ),
      onMenuStateChange: (isOpen) {
        if (!isOpen) _warehouseSearchController.clear();
      },
    );
  }

  // Widget de selección de Artículo
  Widget _buildArticleSelector() {
    return DropdownButtonFormField2<ArticleModel>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: '2. Seleccione Activo para QR',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.vpn_key, color: primaryColor),
      ),
      valueListenable: _articleNotifier,
      hint: _articles.isEmpty
          ? const Text('No hay activos disponibles')
          : const Text('Seleccione un activo'),
      items: _articles.map((article) {
        return DropdownItem(
          value: article,
          child: Text(
            '${article.licensePlate} - ${article.name}',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: _isGenerating || _articles.isEmpty
          ? null
          : (ArticleModel? newValue) {
              setState(() {
                _selectedArticle = newValue;
                _articleNotifier.value = newValue;
                _dataToEncodeForQR =
                    newValue?.qrData ?? 'Seleccione un Activo para Generar QR';
              });
            },
      dropdownSearchData: DropdownTemplates.searchData(
        controller: _articleSearchController,
        hintText: 'Buscar activo...',
        searchMatchFn: (item, searchValue) {
          final art = item.value!;
          return art.name.toLowerCase().contains(searchValue.toLowerCase()) ||
              art.licensePlate.toLowerCase().contains(searchValue.toLowerCase());
        },
      ),
      onMenuStateChange: (isOpen) {
        if (!isOpen) _articleSearchController.clear();
      },
    );
  }

  // Widget del botón de Generación
  Widget _buildGenerateButton() {
    return ElevatedButton.icon(
      onPressed: _isGenerating || _selectedArticle == null ? null : _generateQr,
      icon: _isGenerating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const SizedBox.shrink(),
      label: Text(
        _isGenerating ? 'Generando QR...' : '3. Generar QR',
        style: const TextStyle(color: Colors.white),
      ),
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
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isPlaceholder
                  ? 'Contenido del QR: (Esperando Activo)'
                  : 'Contenido del QR:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            // Muestra los datos codificados
            SelectableText(
              _dataToEncodeForQR,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isPlaceholder ? 14 : 12,
                color: isPlaceholder ? Colors.grey : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
