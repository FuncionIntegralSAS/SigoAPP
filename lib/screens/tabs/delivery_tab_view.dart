import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/requisition_approval_provider.dart';
import '../../widgets/requisition_action_card.dart';

class DeliveryTabView extends StatefulWidget {
  const DeliveryTabView({Key? key}) : super(key: key);

  @override
  State<DeliveryTabView> createState() => _DeliveryTabViewState();
}

class _DeliveryTabViewState extends State<DeliveryTabView> {
  int _selectedCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Solicita explícitamente el estado 'ap'
      context.read<RequisitionApprovalProvider>().loadRequisitions('ap');
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
                onSelectionChanged: _updateSelectionCount,
              );
            },
          ),
          floatingActionButton: _selectedCount > 0
              ? FloatingActionButton.extended(
                  onPressed: () {},
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: Text('Registrar Entrega ($_selectedCount)'),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }
}