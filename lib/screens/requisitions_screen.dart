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

class _RequisitionsScreenState extends State<RequisitionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Carga inicial: pestaña 0 → aprobación pendiente ('in')
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequisitionApprovalProvider>().loadRequisitions('in');
    });

    // Recarga al cambiar de pestaña con el estado correspondiente
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final status = _tabController.index == 0 ? 'in' : 'ap';
        context.read<RequisitionApprovalProvider>().loadRequisitions(status);
      }
    });
  }

  @override
  void dispose() {
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
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.check_circle_outline),
              text: 'Aprobación',
            ),
            Tab(
              icon: Icon(Icons.local_shipping_outlined),
              text: 'Entrega',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ApprovalTabView(),
          DeliveryTabView(),
        ],
      ),
    );
  }
}
