import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/auth_model.dart';
import 'package:sigo_app/screens/tabs/physical_count_opening_tab.dart';
import 'package:sigo_app/screens/tabs/physical_count_assignment_tab.dart';
import 'package:sigo_app/screens/tabs/physical_count_closing_tab.dart';
import '../utils/permission_utils.dart';

class PhysicalCountScreen extends StatelessWidget {
  const PhysicalCountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final List<Widget> tabs = [];
    final List<Widget> views = [];

    if (auth.permisos.hasPermission(AppPermission.asignacionConteo)) {
      tabs.add(const Tab(icon: Icon(Icons.group_add), text: 'Asignar Personal'));
      views.add(const PhysicalCountAssignmentTab());
    }

    if (auth.permisos.hasPermission(AppPermission.aperturaConteo)) {
      tabs.add(const Tab(icon: Icon(Icons.inventory), text: 'Apertura'));
      views.add(const PhysicalCountOpeningTab());
    }

    if (auth.permisos.hasPermission(AppPermission.cerrarConteo)) {
      tabs.add(const Tab(icon: Icon(Icons.lock), text: 'Cierre'));
      views.add(const PhysicalCountClosingTab());
    }

    if (tabs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conteo Físico')),
        body: const Center(child: Text('No tienes permisos para este módulo.')),
      );
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Conteo Físico'),
          bottom: TabBar(
            tabs: tabs,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            isScrollable: tabs.length > 3,
          ),
        ),
        body: TabBarView(
          children: views,
        ),
      ),
    );
  }
}
