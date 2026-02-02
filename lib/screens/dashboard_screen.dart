import 'package:flutter/material.dart';
import 'package:sigo_app/models/home_screen.dart';
import 'package:sigo_app/screens/asset_verification_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/transfer_approval_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SigoAPP - Panel Principal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _DashboardItem(
              icon: Icons.fact_check,
              title: 'Verificación de Activos',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AssetVerificationScreen(),
                  ),
                );
              },
            ),

            // OPCIÓN 2: Solicitud de traspaso de activos
            _DashboardItem(
              icon: Icons.inventory,
              title: 'Solicitud de traspaso de activos',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InventoryScreen(),
                  ),
                );
              },
            ),

            // OPCIÓN 3: Aprobación de trámites
            _DashboardItem(
              icon: Icons.approval,
              title: 'Aprobación de Trámites',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransferApprovalScreen(),
                  ),
                );
              },
            ),

             // NUEVA OPCIÓN: Acceso al módulo principal
            _DashboardItem(
              icon: Icons.apps,
              title: 'Módulo Principal',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DashboardItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
