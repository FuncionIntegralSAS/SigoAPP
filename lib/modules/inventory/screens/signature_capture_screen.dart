import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:sigo_app/modules/inventory/providers/transfer_delivery_provider.dart';
import 'package:sigo_app/modules/auth/providers/auth_provider.dart';
import 'package:sigo_app/modules/inventory/models/transfer_request.dart';
import 'package:sigo_app/utils/dialog_utils.dart';

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
      DialogUtils.showErrorDialog(
        context,
        title: 'Firma Requerida',
        message: 'La firma es requerida.',
      );
      return;
    }

    final Uint8List? bytes = await _controller.toPngBytes();

    if (bytes == null) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context,
          title: 'Error de Procesamiento',
          message: 'Error al procesar la firma.',
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
      DialogUtils.showSuccessSnackBar(context, 'Firma registrada correctamente.');
      Navigator.pop(context); // Volver a la lista
    } else {
      DialogUtils.showErrorDialog(
        context,
        title: 'Error al Registrar Firma',
        message: provider.error ?? 'Error desconocido',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransferDeliveryProvider>();
    final auth = context.watch<AuthProvider>();

    final cedula = auth.currentCedula?.trim().toLowerCase() ?? '';
    final username = auth.currentUsername?.trim().toLowerCase() ?? '';

    bool matchesPerson(String? code, String name) {
      final c = code?.trim().toLowerCase() ?? '';
      final n = name.trim().toLowerCase();
      for (final id in [cedula, username]) {
        if (id.isEmpty) continue;
        if (c.isNotEmpty && (c == id || c.contains(id) || id.contains(c))) {
          return true;
        }
        if (n.isNotEmpty && n.contains(id)) {
          return true;
        }
      }
      return false;
    }

    final bool isDispatcher = matchesPerson(
      widget.transfer.personaFuente ?? widget.transfer.codigoFuente,
      widget.transfer.responsableActual,
    );
    final bool isReceiver = matchesPerson(
      widget.transfer.personaDestino ?? widget.transfer.codigoDestino,
      widget.transfer.responsablePropuesto,
    );

    final bool sourceHasSigned = widget.transfer.isSourceSigned;
    final bool targetHasSigned = widget.transfer.isTargetSigned;

    bool canSign = false;
    bool signAsDispatcher = false;
    String title = '';
    String instruction = '';

    if (isDispatcher && !sourceHasSigned) {
      title = 'Firma de Entrega (Fuente)';
      instruction = 'Por favor, firma para autorizar la entrega y salida de los activos.';
      canSign = true;
      signAsDispatcher = true;
    } else if (isReceiver && !targetHasSigned) {
      title = 'Firma de Recepción (Destino)';
      instruction = 'Por favor, firma para confirmar la recepción de los activos.';
      canSign = true;
      signAsDispatcher = false;
    } else if (isDispatcher && sourceHasSigned) {
      title = 'Firma de Entrega (Fuente)';
      instruction = 'Ya has firmado la entrega de este traspaso.';
      canSign = false;
    } else if (isReceiver && targetHasSigned) {
      title = 'Firma de Recepción (Destino)';
      instruction = 'Ya has firmado la recepción de este traspaso.';
      canSign = false;
    } else {
      title = 'Captura de Firma';
      instruction = 'No tienes un rol asignado como fuente o destino para firmar este traspaso.';
      canSign = false;
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
                    onPressed: provider.loading ? null : () => _submitSignature(signAsDispatcher),
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
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
