import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/requisition_approval_provider.dart';
import '../../widgets/requisition_action_card.dart';

class DeliveryTabView extends StatelessWidget {
  const DeliveryTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RequisitionApprovalProvider>(
      builder: (context, provider, child) {
        
        final deliveryList = provider.pendingRequisitions.where((req) => req.estado == 'ap').toList();

        if (deliveryList.isEmpty) {
          return const Center(child: Text('No hay requisiciones listas para entrega.'));
        }

        return Scaffold(
          body: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 8),
            itemCount: deliveryList.length,
            itemBuilder: (context, index) {
              final item = deliveryList[index];
              return RequisitionActionCard(
                id: item.compositeId, 
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
                // 2. Conectamos directamente con el Provider
                onSelectionChanged: (id, isSelected, qty) {
                  provider.toggleSelection(id, isSelected, qty);
                },
              );
            },
          ),
          floatingActionButton: provider.selectedCount > 0
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final success = await provider.processBatchSelection('ap');
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Entregas registradas exitosamente')),
                      );
                    }
                  },
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: Text('Registrar Entrega (${provider.selectedCount})'),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }
}