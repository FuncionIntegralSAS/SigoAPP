import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sigo_app/services/mock_domain_service.dart';
import 'package:sigo_app/utils/app_config.dart';

class DomainScannerScreen extends StatefulWidget {
  const DomainScannerScreen({super.key});

  @override
  State<DomainScannerScreen> createState() => _DomainScannerScreenState();
}

class _DomainScannerScreenState extends State<DomainScannerScreen> {
  final TextEditingController _manualKeyController = TextEditingController();
  final MockDomainService _domainService = MockDomainService();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  
  bool _isLoading = false;

  @override
  void dispose() {
    _manualKeyController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processClientKey(String key) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final baseUrl = await _domainService.getBaseUrlFromKey(key);
      await AppConfig.updateBaseUrl(baseUrl);
      // Tras actualizar AppConfig, el ValueListenableBuilder en main.dart 
      // detectará el cambio y navegará automáticamente a la pantalla de Auth.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al validar la llave: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        _processClientKey(barcode.rawValue!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Dominio'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Escanea el código QR de tu empresa para configurar la conexión.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  
                  // Lector QR
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) {
                        return Center(
                          child: Text(
                            'Error al iniciar la cámara:\n$error',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('O ingreso manual (Pruebas)'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Fallback Manual
                  TextField(
                    controller: _manualKeyController,
                    decoration: InputDecoration(
                      labelText: 'Llave de cliente',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.key),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final text = _manualKeyController.text.trim();
                      if (text.isNotEmpty) {
                        _processClientKey(text);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor, ingresa una llave.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Validar Llave'),
                  ),
                ],
              ),
            ),
          ),
          
          // Indicador de Carga
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
