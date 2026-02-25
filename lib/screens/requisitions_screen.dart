import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/requisition_approval_provider.dart';
import 'tabs/approval_tab_view.dart';
import 'tabs/delivery_tab_view.dart';

class RequisitionsScreen extends StatefulWidget {
  const RequisitionsScreen({Key? key}) : super(key: key);

  @override
  State<RequisitionsScreen> createState() => _RequisitionsScreenState();
}

class _RequisitionsScreenState extends State<RequisitionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inicializamos el controlador para 3 pestañas
    _tabController = TabController(length: 3, vsync: this);
    
    // Añadimos el listener para detectar cuando el usuario cambia de tab
    _tabController.addListener(_handleTabSelection);

    // Carga inicial para la primera pestaña al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequisitionApprovalProvider>().loadRequisitions('in');
    });
  }

  void _handleTabSelection() {
    // Evitamos peticiones dobles mientras ocurre la animación de transición
    if (_tabController.indexIsChanging) return;

    final provider = context.read<RequisitionApprovalProvider>();

    // Consultamos al backend dependiendo del índice seleccionado
    switch (_tabController.index) {
      case 0: // Pestaña: Aprobación
        provider.loadRequisitions('in');
        break;
      case 1: // Pestaña: Entrega
        provider.loadRequisitions('ap');
        break;
      case 2: // Pestaña: Salida de Inv.
        // Utiliza el estado que corresponda para esta etapa (ej. 'en' o 'entregado')
        provider.loadRequisitions('en'); 
        break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Requisiciones'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController, // Asignamos el controlador explícito
          isScrollable: true,
          tabs: const [
            Tab(text: 'Aprobación'),
            Tab(text: 'Entrega'),
            Tab(text: 'Salida de Inv.'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController, // Asignamos el controlador explícito
        children: const [
          ApprovalTabView(),
          DeliveryTabView(),
          Center(child: Text('En desarrollo...')),
        ],
      ),
    );
  }
}