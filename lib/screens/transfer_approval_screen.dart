import 'package:flutter/material.dart';

import '../models/transfer_request.dart';
import '../services/mock_inventory_service.dart';

class TransferApprovalScreen extends StatefulWidget {
  const TransferApprovalScreen({super.key});

  @override
  State<TransferApprovalScreen> createState() =>
      _TransferApprovalScreenState();
}

class _TransferApprovalScreenState extends State<TransferApprovalScreen> {
  final MockInventoryService _inventoryService =
    MockInventoryService();

  @override
  Widget build(BuildContext context) {
    final pendingTransfers = _inventoryService.transferRequests
        .where((r) => r.status == TransferStatus.pending)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprobación de Traspasos'),
      ),
      body: pendingTransfers.isEmpty
          ? const Center(
              child: Text(
                'No hay solicitudes de traspaso pendientes.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: pendingTransfers.length,
              itemBuilder: (context, index) {
                final request = pendingTransfers[index];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.articleName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          'Responsable actual: ${request.currentResponsible}',
                        ),
                        Text(
                          'Responsable propuesto: ${request.proposedResponsible}',
                        ),
                        const SizedBox(height: 6),

                        Text(
                          'Bodega actual: ${request.currentWarehouse}',
                        ),
                        Text(
                          'Bodega propuesta: ${request.proposedWarehouse}',
                        ),
                        const SizedBox(height: 6),

                        Text(
                          'Motivo: ${request.requestReason}',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _confirmReject(context, request);
                              },
                              child: const Text(
                                'Rechazar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () {
                                _approveTransfer(context, request);
                              },
                              child: const Text('Aprobar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _approveTransfer(
    BuildContext context,
    TransferRequest request,
  ) {
    try {
      _inventoryService.applyApprovedTransfer(request);

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Traspaso aprobado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmReject(
  BuildContext context,
  TransferRequest request,
  ) {
    final TextEditingController reasonController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rechazar traspaso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingrese el motivo del rechazo:',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Motivo del rechazo',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final reason = reasonController.text.trim();

                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Debe ingresar un motivo de rechazo',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                _inventoryService.rejectTransfer(
                  request,
                  reason,
                );

                Navigator.pop(context);
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Solicitud rechazada correctamente'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text(
                'Rechazar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }


}
