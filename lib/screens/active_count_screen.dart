import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/providers/active_count_provider.dart';
import 'package:sigo_app/widgets/continuous_scan_view.dart';
import 'package:sigo_app/widgets/list_count_view.dart';
import 'package:sigo_app/providers/auth_provider.dart';

class ActiveCountScreen extends StatefulWidget {
  const ActiveCountScreen({super.key});

  @override
  State<ActiveCountScreen> createState() => _ActiveCountScreenState();
}

class _ActiveCountScreenState extends State<ActiveCountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //context.read<ActiveCountProvider>().loadLocalActiveCount('USER-MOBILE');
      // Obtenemos el usuario autenticado desde AuthProvider
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentCedula ?? 'UNKNOWN';
      context.read<ActiveCountProvider>().loadLocalActiveCount(userId);
    });
  }

  void _showFinishDialog(BuildContext context, ActiveCountProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Finalizar Conteo ${provider.currentIteration}'),
        content: const Text(
          '¿Estás seguro de finalizar esta iteración? Si existen diferencias, se habilitará el siguiente conteo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final authProvider = context.read<AuthProvider>();
              provider.completeCurrentIteration(
                authProvider.currentToken ?? '',
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ejecución de Conteo Físico')),
      body: Consumer<ActiveCountProvider>(
        builder: (context, provider, child) {
          if (provider.state == ActiveCountState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
              provider.clearError();
            });
          }

          if (!provider.hasActiveCount) {
            return const Center(
              child: Text(
                'No tienes ningún formulario de conteo descargado y activo.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              // Header de Progreso
              Container(
                color: Colors.blue.shade50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ITERACIÓN: Conteo ${provider.currentIteration}/3',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Activos contados: ${provider.countedArticlesCount} de ${provider.totalArticlesCount}',
                          style: TextStyle(color: Colors.blue.shade800),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showFinishDialog(context, provider),
                      child: const Text('Finalizar'),
                    ),
                  ],
                ),
              ),
              const LinearProgressIndicator(value: 0.5), // Placeholder visual
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Colors.blue,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.blue,
                        tabs: [
                          Tab(
                            icon: Icon(Icons.qr_code_scanner),
                            text: 'Escaneo Continuo',
                          ),
                          Tab(
                            icon: Icon(Icons.list_alt),
                            text: 'Conteos por Lista',
                          ),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            const ContinuousScanView(),
                            ListCountView(provider: provider),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
