import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/requisition_approval_provider.dart';
import 'tabs/approval_tab_view.dart';

class RequisitionsScreen extends StatefulWidget {
  const RequisitionsScreen({Key? key}) : super(key: key);

  @override
  State<RequisitionsScreen> createState() => _RequisitionsScreenState();
}

class _RequisitionsScreenState extends State<RequisitionsScreen> {

  @override
  void initState() {
    super.initState();
    
    // Carga inicial 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequisitionApprovalProvider>().loadRequisitions('in');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Requisiciones'),
        centerTitle: true,
        elevation: 0,
      ),
      body: const ApprovalTabView(),
    );
  }
}
