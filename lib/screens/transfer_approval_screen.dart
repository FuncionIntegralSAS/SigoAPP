import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transfer_approval_provider.dart';
import '../widgets/transfer_filter_panel.dart';
import '../models/transfer_request.dart';

class TransferApprovalScreen extends StatefulWidget {
  const TransferApprovalScreen({super.key});

  @override
  State<TransferApprovalScreen> createState() => _TransferApprovalScreenState();
}

class _TransferApprovalScreenState extends State<TransferApprovalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TransferApprovalProvider>();
      if (provider.allTransfers.isEmpty || provider.error != null) {
        provider.loadTransfers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransferApprovalProvider>();
    final transfers = provider.filteredTransfers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprobación de Traspasos'),
      ),
      body: Column(
        children: [
          TransferFilterPanel(
            filter: provider.filter,
            availableWarehouses: provider.availableWarehouses,
            onFilterChanged: provider.updateFilter,
          ),
          Expanded(
            child: transfers.isEmpty
                ? const Center(
                    child: Text(
                      'No hay solicitudes que coincidan con los filtros.',
                    ),
                  )
                : ListView.builder(
                    itemCount: transfers.length,
                    itemBuilder: (context, index) {
                      final request = transfers[index];
                      return _TransferCard(request: request);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final TransferRequest request;

  const _TransferCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final provider =
        context.read<TransferApprovalProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
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
            Text('Responsable actual: ${request.responsableActual}'),
            Text('Responsable propuesto: ${request.responsablePropuesto}'),
            const SizedBox(height: 6),
            Text('Bodega actual: ${request.bodegaActual}'),
            Text('Bodega propuesta: ${request.bodegaPropuesta}'),
            const SizedBox(height: 6),
            Text('Motivo: ${request.motivoSolicitud}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () =>
                      _confirmReject(context, provider, request),
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
                    provider.approveTransfer(request.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Traspaso aprobado correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Aprobar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReject(
    BuildContext context,
    TransferApprovalProvider provider,
    TransferRequest request,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rechazar traspaso'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Motivo del rechazo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;

              provider.rejectTransfer(
                request.id,
                controller.text.trim(),
              );

              Navigator.pop(context);
            },
            child: const Text(
              'Rechazar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
