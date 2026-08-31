import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/article_model.dart';
import '../utils/article_qr_parser.dart';

class ScannerScreen extends StatefulWidget {
  final String? expectedResponsible;

  const ScannerScreen({
    super.key,
    this.expectedResponsible,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController cameraController =
      MobileScannerController();

  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Activo'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_processing) return;

              final barcode = capture.barcodes.first;
              final raw = barcode.rawValue;

              if (raw != null) {
                _processing = true;
                cameraController.stop();

                final article = ArticleQrParser.fromQr(raw);
                final isValid = _validateResponsible(article);

                _showResultDialog(context, article, isValid);
              }
            },
          ),

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

  bool _validateResponsible(ArticleModel article) {
    if (widget.expectedResponsible == null) return true;

    return article.responsable == widget.expectedResponsible;
  }

  void _showResultDialog(
    BuildContext context,
    ArticleModel article,
    bool isValid,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verificación de Activo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${article.nombre}'),
            Text('Placa: ${article.placa}'),
            Text('Responsable: ${article.responsable ?? "No asignado"}'),
            const SizedBox(height: 12),
            Text(
              isValid
                  ? '✅ Responsable coincide'
                  : '❌ Responsable NO coincide',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isValid ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop({
                'article': article,
                'isValid': isValid,
              });
            },
            child: const Text('Confirmar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processing = false;
              cameraController.start();
            },
            child: const Text('Escanear de nuevo'),
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
