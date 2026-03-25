import 'package:flutter/material.dart';
import 'package:sigo_app/screens/tabs/physical_count_opening_tab.dart';
import 'package:sigo_app/screens/tabs/physical_count_assignment_tab.dart';

class PhysicalCountScreen extends StatelessWidget {
  const PhysicalCountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Conteo Físico'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inventory), text: 'Apertura'),
              Tab(icon: Icon(Icons.group_add), text: 'Asignar Personal'),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
          ),
        ),
        body: const TabBarView(
          children: [
            PhysicalCountOpeningTab(),
            PhysicalCountAssignmentTab(),
          ],
        ),
      ),
    );
  }
}
