import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  // Controlador para el MobileScanner
  final MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lector de Códigos QR/Barras'),
        backgroundColor: Colors.deepPurple,
      ),
      // Usamos un Stack para apilar el escáner y la vista de superposición (overlay)
      body: Stack( 
        children: [
          // 1. El MobileScanner cubre toda la pantalla
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String code = barcodes.first.rawValue ?? 'Código no válido';
                cameraController.stop(); 
                _showResultDialog(context, code);
              }
            },
          ),
          
          // 2. La capa de superposición (el marco rojo) se dibuja encima
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 3),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código Escaneado'),
        content: SelectableText(code), // SelectableText permite copiar el texto
        actions: [
          TextButton(
            onPressed: () {
              // Cerramos la alerta y luego reiniciamos el escaneo
              Navigator.of(context).pop(); 
              cameraController.start();
            },
            child: const Text('Escanear de Nuevo'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Solo cierra la alerta
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}