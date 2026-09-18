import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/requisition_approval_provider.dart';
import '../../widgets/requisition_action_card.dart';
import '../../widgets/requisition_filter_header.dart';

class ApprovalTabView extends StatelessWidget {
  const ApprovalTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RequisitionApprovalProvider>(
      builder: (context, provider, child) {
        final approvalList = provider.pendingRequisitions.where((req) => req.estado == 'in').toList();

        return Scaffold(
          body: Column(
            children: [
              // Barra de filtros superior (siempre visible para operar)
              const RequisitionFilterHeader(status: 'in'),

              // Contenido reactivo
              Expanded(
                child: _buildContent(context, provider, approvalList),
              ),
            ],
          ),
          floatingActionButton: provider.selectedCount > 0
              ? FloatingActionButton.extended(
                  onPressed: () async {
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

  Widget _buildContent(
    BuildContext context,
    RequisitionApprovalProvider provider,
    List dynamicList,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: Colors.red.shade700),
              const SizedBox(height: 12),
              Text(
                'Error al consultar requisiciones',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => provider.loadRequisitions('in'),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (dynamicList.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 8),
      itemCount: dynamicList.length,
      itemBuilder: (context, index) {
        final item = dynamicList[index];
        return RequisitionActionCard(
          id: item.id,
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
          onSelectionChanged: (id, isSelected, qty) {
            provider.toggleSelection(id, isSelected, qty);
          },
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay requisiciones pendientes por aprobar con los filtros seleccionados.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }
}