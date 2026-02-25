import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/requisition_approval_provider.dart';
import '../../widgets/requisition_action_card.dart';

class ApprovalTabView extends StatelessWidget {
  const ApprovalTabView({Key? key}) : super(key: key);

  // Ya no necesitamos StatefulWidget porque el Provider maneja todo el estado

  @override
  Widget build(BuildContext context) {
    return Consumer<RequisitionApprovalProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(child: Text(provider.errorMessage!));
        }

        final approvalList = provider.pendingRequisitions.where((req) => req.estado == 'in').toList();

        if (approvalList.isEmpty) {
          return _buildEmptyState(context);
        }

        return Scaffold(
          body: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 8),
            itemCount: approvalList.length,
            itemBuilder: (context, index) {
              final item = approvalList[index];
              return RequisitionActionCard(
                id: item.id, // Pasamos el ID
                articulo: item.articulo,
                solicita: item.solicita,
                estado: item.estado,
                empresa: item.empresa,
                tipoDocumento: item.tipoDocumento,
                numero: item.numero,
                fecha: item.fecha,
                bodega: item.bodega,
                unidad: item.unidad,
                observacion: item.observacion,
                cantidadSolicitada: item.cantidadSolicitada,
                cantidadAprobada: item.cantidadAprobada,
                cantidadEntregada: item.cantidadEntregada,
                // Conectamos directamente con el Provider
                onSelectionChanged: (id, isSelected, qty) {
                  provider.toggleSelection(id, isSelected, qty);
                },
              );
            },
          ),
          // El botón reacciona al contador del Provider
          floatingActionButton: provider.selectedCount > 0
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    // Ejecutamos el envío masivo indicando la pestaña actual ('in')
                    final success = await provider.processBatchSelection('in');
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lote procesado exitosamente')),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('Procesar Selección (${provider.selectedCount})'),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Bandeja al día',
            style: Theme.of(context).textTheme.titleLarge?.copyWith( // Ya no dará error
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay requisiciones pendientes por aprobar.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith( // Ya no dará error
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }
}