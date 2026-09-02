import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import '../providers/transfer_delivery_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transfer_request.dart';

class SignatureCaptureScreen extends StatefulWidget {
  final TransferRequest transfer;

  const SignatureCaptureScreen({super.key, required this.transfer});

  @override
  State<SignatureCaptureScreen> createState() => _SignatureCaptureScreenState();
}

class _SignatureCaptureScreenState extends State<SignatureCaptureScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitSignature(bool isDispatcher) async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La firma es requerida.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Uint8List? bytes = await _controller.toPngBytes();

    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar la firma.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final String base64Signature = base64Encode(bytes);

    if (!mounted) return;

    final provider = context.read<TransferDeliveryProvider>();
    final success = await provider.submitDelivery(
      widget.transfer.id,
      dispatcherBase64: isDispatcher ? base64Signature : null,
      receiverBase64: !isDispatcher ? base64Signature : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firma registrada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Volver a la lista
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(
            'Error',
            style: TextStyle(color: Colors.red),
          ),
          content: Text(provider.error ?? 'Error desconocido'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransferDeliveryProvider>();
    final auth = context.watch<AuthProvider>();
    final userIdentifier =
        (auth.currentUsername ?? auth.currentCedula ?? '').trim().toLowerCase();

    final bool isDispatcher = userIdentifier.isNotEmpty &&
        widget.transfer.responsableActual.toLowerCase().contains(userIdentifier);
    final bool isReceiver = userIdentifier.isNotEmpty &&
        widget.transfer.responsablePropuesto.toLowerCase().contains(userIdentifier);

    // Según la regla del negocio: "el emisor debe firmar antes de hacer el despacho"
    final bool dispatcherHasSigned = widget.transfer.firmaDespachadorBase64 != null;

    bool canSign = false;
    String title = '';
    String instruction = '';

    if (isDispatcher) {
      title = 'Firma del Despachador';
      instruction = 'Por favor, firma para autorizar el despacho del activo.';
      canSign = !dispatcherHasSigned;
      if (dispatcherHasSigned) {
        instruction = 'Ya has firmado el despacho de este activo.';
      }
    } else if (isReceiver) {
      title = 'Firma del Receptor';
      if (!dispatcherHasSigned) {
        instruction = 'El despachador aún no ha firmado la entrega. Debes esperar su firma.';
        canSign = false;
      } else {
        instruction = 'Por favor, firma para confirmar la recepción del activo.';
        canSign = true;
      }
    } else {
      instruction = 'No tienes un rol asignado para firmar este traspaso.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Captura de Firma'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  instruction,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (canSign) ...[
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Signature(
                      controller: _controller,
                      height: 300,
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _controller.clear(),
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpiar firma'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: provider.loading ? null : () => _submitSignature(isDispatcher),
                    child: const Text(
                      'Guardar y Finalizar',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ]
              ],
            ),
          ),
          if (provider.loading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
