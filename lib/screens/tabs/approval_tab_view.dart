import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/requisition_approval_provider.dart';
import '../../widgets/requisition_action_card.dart';

class ApprovalTabView extends StatefulWidget {
  const ApprovalTabView({Key? key}) : super(key: key);

  @override
  State<ApprovalTabView> createState() => _ApprovalTabViewState();
}

class _ApprovalTabViewState extends State<ApprovalTabView> {
  int _selectedCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Solicita explícitamente el estado 'in'
      context.read<RequisitionApprovalProvider>().loadRequisitions('in');
    });
  }

  void _updateSelectionCount(bool isSelected, int amount) {
    setState(() {
      isSelected ? _selectedCount++ : _selectedCount--;
    });
  }

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

        // Aplicamos el filtro estricto por el estado 'in'
        final approvalList = provider.pendingRequisitions.where((req) => req.estado == 'in').toList();

        if (approvalList.isEmpty) {
          return _buildEmptyState();
        }

        return Scaffold(
          body: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 8),
            itemCount: approvalList.length,
            itemBuilder: (context, index) {
              final item = approvalList[index];
              return RequisitionActionCard(
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
                // Pasamos los 3 campos fijos del modelo
                cantidadSolicitada: item.cantidadSolicitada,
                cantidadAprobada: item.cantidadAprobada,
                cantidadEntregada: item.cantidadEntregada,
                onSelectionChanged: _updateSelectionCount,
              );
            },
          ),
          floatingActionButton: _selectedCount > 0
              ? FloatingActionButton.extended(
                  onPressed: () {
                    // Acción pendiente de conectar con el Provider
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Procesando $_selectedCount requisiciones...')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('Procesar Selección ($_selectedCount)'),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
            'No hay requisiciones pendientes por aprobar.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }
}