import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/requisition_model.dart';
import '../../providers/requisition_approval_provider.dart';
import '../../utils/dialog_utils.dart';
import '../../widgets/requisition_action_card.dart';
import '../../widgets/requisition_filter_header.dart';

class ApprovalTabView extends StatelessWidget {
  const ApprovalTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RequisitionApprovalProvider>(
      builder: (context, provider, child) {
        final approvalList = provider.documents
            .where((doc) => doc.estado.toLowerCase() == 'in')
            .toList();

        return Scaffold(
          body: Column(
            children: [
              // Barra de filtros superior (siempre visible y persistente)
              const RequisitionFilterHeader(status: 'in'),

              // Contenido reactivo
              Expanded(
                child: _buildContent(context, provider, approvalList),
              ),
            ],
          ),
          floatingActionButton: provider.selectedDocumentsCount > 0
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final success = await provider.processBatchSelection('in');
                    if (!context.mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Lote procesado exitosamente',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green.shade700,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    } else if (provider.processErrorMessage != null) {
                      await DialogUtils.showErrorDialog(
                        context,
                        title: 'Error al Aprobar Requisición',
                        message: provider.processErrorMessage!,
                      );
                      provider.clearProcessErrorMessage();
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    'Procesar Selección (${provider.selectedDocumentsCount} ${provider.selectedDocumentsCount == 1 ? 'doc.' : 'docs.'})',
                  ),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    RequisitionApprovalProvider provider,
    List<RequisicionResumen> documents,
  ) {
    // 1. Estado de espera Fail-Fast UI: Fecha 'desde' no seleccionada
    if (provider.getDesdeForStatus('in') == null) {
      return _buildDateRequiredState(context);
    }

    // 2. Estado de carga asíncrona
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 3. Manejo de errores
    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: Colors.red.shade700),
              const SizedBox(height: 12),
              Text(
                'Error al consultar requisiciones',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => provider.loadRequisitions('in'),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Bandeja vacía
    if (documents.isEmpty) {
      return _buildEmptyState(context);
    }

    // 5. Lista Master de Documentos de Requisición
    return Column(
      children: [
        // Franja métrica institucional
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Text(
            'Documentos en lista: ${documents.length}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 8),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final item = documents[index];
              return RequisitionActionCard(
                document: item,
                currentTabStatus: 'in',
              );
            },
          ),
        ),
      ],
    );
  }

  /// Estado institucional de espera: requiere seleccionar fecha en el filtro superior
  Widget _buildDateRequiredState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Consulta de Requisiciones',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Selecciona una fecha en el filtro superior para consultar las requisiciones vigentes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Bandeja al día',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay requisiciones pendientes por aprobar con los filtros seleccionados.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}