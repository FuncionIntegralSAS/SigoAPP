import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/auth_model.dart';
import 'package:sigo_app/screens/home_screen.dart';
import 'package:sigo_app/screens/asset_verification_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/transfer_approval_screen.dart';
import '../screens/requisitions_screen.dart';
import '../screens/physical_count_screen.dart';
import '../screens/active_count_screen.dart';
import '../utils/permission_utils.dart';
import '../screens/transfer_delivery_screen.dart' as transfer_delivery;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Salir de la aplicación?'),
            content: const Text(
              '¿Estás seguro de que deseas salir de SigoAPP?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Salir'),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SigoAPP - Panel Principal'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar Sesión',
              onPressed: () {
                context.read<AuthProvider>().logout();
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              if (auth.permisos.hasPermission(
                AppPermission.verificacionActivos,
              ))
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

              if (auth.permisos.hasPermission(AppPermission.generarTraspaso))
                _DashboardItem(
                  icon: Icons.inventory,
                  title: 'Generar solicitud de traspaso',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InventoryScreen(),
                      ),
                    );
                  },
                ),

              if (auth.permisos.hasPermission(AppPermission.aprobacionTraspaso))
                _DashboardItem(
                  icon: Icons.approval,
                  title: 'Aprobación de Traspasos',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransferApprovalScreen(),
                      ),
                    );
                  },
                ),
              _DashboardItem(
                icon: Icons.handshake,
                title: 'Entrega / Recepción',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const transfer_delivery.TransferDeliveryScreen(),
                    ),
                  );
                },
              ),

              if (!kReleaseMode)
                _DashboardItem(
                  icon: Icons.apps,
                  title: 'Módulo Principal',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                ),

              if (auth.permisos.hasPermission(AppPermission.requisiciones))
                _DashboardItem(
                  icon: Icons.apps,
                  title: 'Requisiciones',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RequisitionsScreen(),
                      ),
                    );
                  },
                ),

              if (auth.permisos.hasAnyPermission([
                AppPermission.aperturaConteo,
                AppPermission.asignacionConteo,
                AppPermission.cerrarConteo,
              ]))
                _DashboardItem(
                  icon: Icons.playlist_add_check_circle,
                  title: 'Conteo Físico',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PhysicalCountScreen(),
                      ),
                    );
                  },
                ),

              if (auth.permisos.hasPermission(AppPermission.realizarConteo))
                _DashboardItem(
                  icon: Icons.qr_code_scanner,
                  title: 'Ejecutar Conteo',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ActiveCountScreen(),
                      ),
                    );
                  },
                ),
            ],
          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
