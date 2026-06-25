import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/providers/active_count_provider.dart';

class ContinuousScanView extends StatefulWidget {
  const ContinuousScanView({super.key});

  @override
  State<ContinuousScanView> createState() => _ContinuousScanViewState();
}

class _ContinuousScanViewState extends State<ContinuousScanView> {
  final TextEditingController _barcodeController = TextEditingController();

  void _simulateScan(BuildContext context) {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;

    final provider = context.read<ActiveCountProvider>();
    // Simula cámara: Al detectar código asume cantidad 1.0 (incremento natural)
    provider.recordCount(barcode, 1.0);
    
    _barcodeController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Artículo $barcode registrado exitosamente.'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dummy Camera Viewport
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.black87,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.qr_code_scanner, size: 100, color: Colors.white24),
                Positioned(
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.black54,
                    child: const Text(
                      'Cámara Activa (Modo Continuo)',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Simulador Textual para PC o tests
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Simulador de Escáner Láser/Teclado:'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          hintText: 'Ingrese ID o Código de Barras...',
                          border: OutlineInputBorder(),
                        ),
                        // Al dar "Enter" en un lector láser físico
                        onSubmitted: (_) => _simulateScan(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _simulateScan(context),
                      child: const Text('Simular'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
