import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/article_model.dart';
import '../models/warehouse_model.dart';
import '../models/company_model.dart';
import '../providers/inventory_provider.dart';
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
import '../providers/geolocation_provider.dart';

// El StatefulWidget para la pantalla de Generación de QR
class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  // --- Estado de la Pantalla ---
  ArticleModel? _selectedArticle; // Artículo seleccionado (Filtro 2)

  final TextEditingController _companySearchController = TextEditingController();
  final TextEditingController _warehouseSearchController = TextEditingController();
  final TextEditingController _articleSearchController = TextEditingController();
  final ValueNotifier<CompanyModel?> _companyNotifier = ValueNotifier(null);
  final ValueNotifier<WarehouseModel?> _warehouseNotifier = ValueNotifier(null);
  final ValueNotifier<ArticleModel?> _articleNotifier = ValueNotifier(null);

  String _dataToEncodeForQR = 'Seleccione un Activo para Generar QR';
  bool _isGenerating = false;
  String _message = 'Seleccione el activo y presione "Generar QR".';

  final Color primaryColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<InventoryProvider>();
      if (provider.companies.isEmpty && provider.state != InventoryState.loading) {
        provider.loadCompanies();
      }
    });
  }

  @override
  void dispose() {
    _companySearchController.dispose();
    _warehouseSearchController.dispose();
    _articleSearchController.dispose();
    _companyNotifier.dispose();
    _warehouseNotifier.dispose();
    _articleNotifier.dispose();
    super.dispose();
  }

  // Sync notifiers with provider
  void _syncNotifiers(InventoryProvider provider) {
    if (_companyNotifier.value != provider.selectedCompany) {
      _companyNotifier.value = provider.selectedCompany;
    }
    if (_warehouseNotifier.value != provider.selectedWarehouse) {
      _warehouseNotifier.value = provider.selectedWarehouse;
      // Reset article if warehouse changed globally
      if (_selectedArticle != null && provider.articles.every((a) => a.id != _selectedArticle!.id)) {
        _selectedArticle = null;
        _articleNotifier.value = null;
        _dataToEncodeForQR = 'Seleccione un Activo para Generar QR';
      }
    }
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
        latitud: lat,
        longitud: lon,
      );

      final geoProvider = context.read<GeolocationProvider>();
      if (updatedArticle.id != null) {
        final synced =
            await geoProvider.syncGeolocation(updatedArticle.id!, lat, lon);
        if (!synced && mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Aviso de Sincronización'),
              content: Text(
                'No se pudo registrar la ubicación en el servidor:\n${geoProvider.errorMessage ?? "Error de red"}\n\nEl proceso local continuará con normalidad.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          );
        }
      }

      if (!mounted) return;

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
          updatedArticle.nombre,
          updatedArticle.placa,
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
                  'Nombre: ${article.nombre}',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                  maxLines: 1,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Placa: ${article.placa}',
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
    final file = File('${output.path}/qr_${article.placa}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // --- Estructura Visual (build) ---
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    _syncNotifiers(provider);

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
      body: provider.state == InventoryState.loading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (provider.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade100,
                child: Text(
                  provider.errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),

            // 1. Selector de Empresa
            _buildCompanySelector(provider),
            const SizedBox(height: 20),

            // 2. Selector de Bodega
            _buildWarehouseSelector(provider),
            const SizedBox(height: 20),

            // 3. Selector de Artículo
            _buildArticleSelector(provider),
            const SizedBox(height: 30),

            // 4. Botón de Generación
            _buildGenerateButton(provider),
            const SizedBox(height: 20),

            // 5. Mensaje de Estado
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),

            // 6. Contenedor del QR
            _buildQrDisplay(),
          ],
        ),
      ),
    );
  }

  // Widget de selección de Empresa
  Widget _buildCompanySelector(InventoryProvider provider) {
    return DropdownButtonFormField2<CompanyModel>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: '1. Seleccione Empresa',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.business, color: primaryColor),
      ),
      valueListenable: _companyNotifier,
      items: provider.companies.map((company) {
        return DropdownItem(
          value: company,
          child: Text(
            '${company.codigo} - ${company.descripcion}',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: _isGenerating
          ? null
          : (CompanyModel? newValue) {
              if (newValue != null) {
                provider.selectCompany(newValue);
              }
            },
      dropdownSearchData: DropdownTemplates.searchData(
        controller: _companySearchController,
        hintText: 'Buscar empresa...',
        searchMatchFn: (item, searchValue) {
          final comp = item.value!;
          return comp.descripcion.toLowerCase().contains(searchValue.toLowerCase()) ||
              comp.codigo.toLowerCase().contains(searchValue.toLowerCase());
        },
      ),
      onMenuStateChange: (isOpen) {
        if (!isOpen) _companySearchController.clear();
      },
    );
  }

  // Widget de selección de Bodega
  Widget _buildWarehouseSelector(InventoryProvider provider) {
    return DropdownButtonFormField2<WarehouseModel>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: '2. Seleccione Centro de Costos/Bodega',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.location_city, color: primaryColor),
      ),
      valueListenable: _warehouseNotifier,
      items: provider.warehouses.map((bodega) {
        return DropdownItem(
          value: bodega,
          child: Text(
            '${bodega.codigoBodega} - ${bodega.descripcionBodega}',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: _isGenerating
          ? null
          : (WarehouseModel? newValue) {
              if (newValue != null) {
                provider.selectWarehouse(newValue);
              }
            },
      dropdownSearchData: DropdownTemplates.searchData(
        controller: _warehouseSearchController,
        hintText: 'Buscar bodega...',
        searchMatchFn: (item, searchValue) {
          final wh = item.value!;
          return wh.descripcionBodega.toLowerCase().contains(searchValue.toLowerCase()) ||
              wh.codigoBodega.toLowerCase().contains(searchValue.toLowerCase());
        },
      ),
      onMenuStateChange: (isOpen) {
        if (!isOpen) _warehouseSearchController.clear();
      },
    );
  }

  // Widget de selección de Artículo
  Widget _buildArticleSelector(InventoryProvider provider) {
    return DropdownButtonFormField2<ArticleModel>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: '3. Seleccione Activo para QR',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.vpn_key, color: primaryColor),
      ),
      valueListenable: _articleNotifier,
      hint: provider.articles.isEmpty
          ? const Text('No hay activos disponibles')
          : const Text('Seleccione un activo'),
      items: provider.articles.map((article) {
        return DropdownItem(
          value: article,
          child: Text(
            '${article.placa} - ${article.nombre}',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: _isGenerating || provider.articles.isEmpty
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
          return art.nombre.toLowerCase().contains(searchValue.toLowerCase()) ||
              art.placa.toLowerCase().contains(searchValue.toLowerCase());
        },
      ),
      onMenuStateChange: (isOpen) {
        if (!isOpen) _articleSearchController.clear();
      },
    );
  }

  // Widget del botón de Generación
  Widget _buildGenerateButton(InventoryProvider provider) {
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
        _isGenerating ? 'Generando QR...' : '4. Generar QR',
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
