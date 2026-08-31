import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transfer_delivery_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transfer_request.dart';
import 'signature_capture_screen.dart';

class TransferDeliveryScreen extends StatefulWidget {
  const TransferDeliveryScreen({super.key});

  @override
  State<TransferDeliveryScreen> createState() => _TransferDeliveryScreenState();
}

class _TransferDeliveryScreenState extends State<TransferDeliveryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TransferDeliveryProvider>();
      provider.loadTransfers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransferDeliveryProvider>();
    final auth = context.watch<AuthProvider>();
    
    // Usar la cédula como identificador principal
    final userIdentifier = auth.currentCedula ?? ''; 

    final transfers = provider.getAssignedTransfers(userIdentifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrega / Recepción'),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : transfers.isEmpty
              ? const Center(
                  child: Text('No tienes entregas o recepciones pendientes asignadas a tu usuario.'),
                )
              : ListView.builder(
                  itemCount: transfers.length,
                  itemBuilder: (context, index) {
                    final request = transfers[index];
                    return _DeliveryCard(request: request);
                  },
                ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final TransferRequest request;

  const _DeliveryCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.nombreArticulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('ID Traspaso: ${request.id}'),
            const SizedBox(height: 8),
            Text('Responsable actual: ${request.responsableActual}'),
            Text('Responsable propuesto: ${request.responsablePropuesto}'),
            const SizedBox(height: 6),
            Text('Bodega actual: ${request.bodegaActual}'),
            Text('Bodega propuesta: ${request.bodegaPropuesta}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.draw),
                  label: const Text('Registrar Firmas'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SignatureCaptureScreen(transfer: request),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
