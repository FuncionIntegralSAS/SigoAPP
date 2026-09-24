import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/modules/inventory/providers/transfer_delivery_provider.dart';
import 'package:sigo_app/modules/auth/providers/auth_provider.dart';
import 'package:sigo_app/modules/inventory/models/transfer_request.dart';
import 'package:sigo_app/utils/dialog_utils.dart';
import 'package:sigo_app/modules/inventory/screens/signature_capture_screen.dart';

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

    final cedula = auth.currentCedula?.trim() ?? '';
    final username = auth.currentUsername?.trim() ?? '';

    final transfers = provider.getAssignedTransfers(cedula, username);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrega / Recepción'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: provider.loading ? null : () => provider.loadTransfers(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadTransfers(),
        child: provider.loading && transfers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : transfers.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                'No tienes traspasos pendientes de firma o recepción.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => provider.loadTransfers(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Actualizar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: transfers.length,
                    itemBuilder: (context, index) {
                      final request = transfers[index];
                      return _DeliveryCard(request: request);
                    },
                  ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final TransferRequest request;

  const _DeliveryCard({required this.request});

  Widget _buildSignatureBadge({
    required String label,
    required bool signed,
  }) {
    final color = signed ? Colors.green : Colors.orange.shade800;
    final bgColor = signed ? Colors.green.shade50 : Colors.orange.shade50;
    final borderColor = signed ? Colors.green.shade200 : Colors.orange.shade200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            signed ? Icons.check_circle : Icons.schedule,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ${signed ? "Firmada" : "Pendiente"}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
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
      request.personaFuente ?? request.codigoFuente,
      request.responsableActual,
    );
    final bool isReceiver = matchesPerson(
      request.personaDestino ?? request.codigoDestino,
      request.responsablePropuesto,
    );

    final bool canUserSign = (isDispatcher && !request.isSourceSigned) ||
        (isReceiver && !request.isTargetSigned);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.articulos.length > 1
                        ? '${request.articulos.length} artículos'
                        : request.nombreArticulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'Trámite #${request.id}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            if (request.articulos.length > 1) ...[
              const SizedBox(height: 6),
              Text(
                'Artículos incluidos: ${request.articulos.map((a) => (a.nombre != null && a.nombre!.trim().isNotEmpty) ? "${a.nombre!.trim()} (${a.articulo})" : a.articulo).join(", ")}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text('Entrega (Fuente): ${request.responsableActual}'),
            Text('Recibe (Destino): ${request.responsablePropuesto}'),
            const SizedBox(height: 6),
            Text('Bodega origen: ${request.bodegaActual}'),
            Text('Bodega destino: ${request.bodegaPropuesta}'),
            const SizedBox(height: 12),

            // Estado de ambas firmas
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildSignatureBadge(
                  label: 'Firma Entrega (FU)',
                  signed: request.isSourceSigned,
                ),
                _buildSignatureBadge(
                  label: 'Firma Recibo (DE)',
                  signed: request.isTargetSigned,
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Si ambas están firmadas, botón destacado para asentar en ERP
                if (request.bothSigned)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmar Recepción ERP'),
                    onPressed: provider.loading
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final success =
                                await provider.confirmReceipt(request.id);
                            if (!context.mounted) return;
                            if (success) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Recepción confirmada e inventario actualizado en ERP'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              DialogUtils.showErrorDialog(
                                context,
                                title: 'Error al Confirmar Recepción',
                                message: provider.error ??
                                    'No fue posible registrar la recepción en el ERP.',
                                technicalDetails: provider.technicalDetails,
                                statusCode: provider.statusCode,
                                buttonText: 'Aceptar',
                              );
                            }
                          },
                  )
                else if (canUserSign)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.draw),
                    label: Text(isDispatcher && !request.isSourceSigned
                        ? 'Firmar Entrega (FU)'
                        : 'Firmar Recepción (DE)'),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SignatureCaptureScreen(transfer: request),
                        ),
                      );
                      if (context.mounted) {
                        provider.loadTransfers();
                      }
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
