import 'package:flutter/material.dart';
import 'tabs/approval_tab_view.dart';
import 'tabs/delivery_tab_view.dart';

class RequisitionsScreen extends StatelessWidget {
  const RequisitionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Requisiciones'),
          centerTitle: true,
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Aprobación'),
              Tab(text: 'Entrega'),
              Tab(text: 'Salida de Inv.'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ApprovalTabView(), 
            DeliveryTabView(), 
            Center(child: Text('Sin registros pendientes')),
          ],
        ),
      ),
    );
  }
}