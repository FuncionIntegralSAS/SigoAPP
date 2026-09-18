import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/requisition_approval_provider.dart';
import 'tabs/approval_tab_view.dart';
import 'tabs/delivery_tab_view.dart';

class RequisitionsScreen extends StatefulWidget {
  const RequisitionsScreen({super.key});

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

    // Carga inicial: únicamente catálogo maestro de empresas (Lazy Fetch / Bloqueo sin fecha)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RequisitionApprovalProvider>();
      provider.loadCompanies();
    });

    // Recarga al cambiar de pestaña si ya existe una fecha 'desde' configurada
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final status = _tabController.index == 0 ? 'in' : 'ap';
        final provider = context.read<RequisitionApprovalProvider>();
        if (provider.getDesdeForStatus(status) != null) {
          provider.loadRequisitions(status);
        }
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
