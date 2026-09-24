import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/modules/auth/models/auth_model.dart';
import 'package:sigo_app/modules/requisitions/models/requisition_model.dart';
import 'package:sigo_app/modules/auth/providers/auth_provider.dart';
import 'package:sigo_app/modules/requisitions/providers/requisition_signature_provider.dart';
import 'package:sigo_app/utils/dialog_utils.dart';
import 'package:sigo_app/utils/permission_utils.dart';
import 'package:sigo_app/modules/requisitions/widgets/requisition_filter_header.dart';
import 'package:sigo_app/modules/requisitions/screens/requisition_signature_capture_screen.dart';

/// Pantalla institucional para la Firma de Requisiciones Entregadas y
/// Cierre definitivo en el inventario ERP (DOCUINVE / MOVIINVE).
class RequisitionSignatureScreen extends StatefulWidget {
  const RequisitionSignatureScreen({super.key});

  @override
  State<RequisitionSignatureScreen> createState() =>
      _RequisitionSignatureScreenState();
}

class _RequisitionSignatureScreenState
    extends State<RequisitionSignatureScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<RequisitionSignatureProvider>();

    // Control de Acceso: El usuario debe poseer el permiso AREQ (AppPermission.requisiciones)
    if (!auth.permisos.hasPermission(AppPermission.requisiciones)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Firma de Requisiciones')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Acceso Restringido',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No cuenta con el permiso requerido (AREQ) para consultar o gestionar la firma de requisiciones.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firma de Requisiciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar lista',
            onPressed: provider.isLoading
                ? null
                : () => provider.loadDeliveredRequisitions(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cabecera institucional de filtrado (Empresa y Fecha 'desde')
          const RequisitionFilterHeader(status: 'en'),

          // Contenido reactivo según el estado de la bandeja
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  provider.loadDeliveredRequisitions(forceRefresh: true),
              child: _buildContent(context, provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    RequisitionSignatureProvider provider,
  ) {
    // 1. Estado de espera Fail-Fast UI: Fecha 'desde' no seleccionada
    if (provider.selectedDesde == null) {
      return _buildDateRequiredState(context);
    }

    // 2. Estado de carga asíncrona inicial
    if (provider.isLoading && provider.documents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 3. Manejo de errores
    if (provider.errorMessage != null && provider.documents.isEmpty) {
      return _buildErrorState(context, provider);
    }

    // 4. Bandeja vacía
    if (provider.documents.isEmpty) {
      return _buildEmptyState(context, provider);
    }

    final documents = provider.documents;

    // 5. Lista de requisiciones entregadas
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              return _RequisitionSignatureCard(
                key: ValueKey(
                  '${document.empresa}_${document.tipoDocumento}_${document.numero}',
                ),
                document: document,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Estado institucional de espera: requiere seleccionar fecha en el filtro superior
  Widget _buildDateRequiredState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08),
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
                    'Selecciona una fecha en el filtro superior para consultar las requisiciones entregadas pendientes de firma.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Estado de error en la consulta
  Widget _buildErrorState(
    BuildContext context,
    RequisitionSignatureProvider provider,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: Colors.red.shade700,
                  ),
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
                    onPressed: () =>
                        provider.loadDeliveredRequisitions(forceRefresh: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Vista informativa cuando no hay requisiciones para los filtros
  Widget _buildEmptyState(
    BuildContext context,
    RequisitionSignatureProvider provider,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes requisiciones entregadas pendientes de firma con los filtros aplicados.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        provider.loadDeliveredRequisitions(forceRefresh: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de Requisición Entregada con franja lateral canónica de 5px,
/// detalle expandible de artículos, badges de firmas y acciones operativas.
class _RequisitionSignatureCard extends StatefulWidget {
  final RequisicionResumen document;

  const _RequisitionSignatureCard({super.key, required this.document});

  @override
  State<_RequisitionSignatureCard> createState() =>
      _RequisitionSignatureCardState();
}

class _RequisitionSignatureCardState extends State<_RequisitionSignatureCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<RequisitionSignatureProvider>();
      provider.loadDetail(
        widget.document.empresa,
        widget.document.tipoDocumento,
        widget.document.numero,
      );
    });
  }

  Widget _buildSignatureBadge({
    required String label,
    required bool signed,
    String? persona,
    String? fecha,
  }) {
    final color = signed ? Colors.green.shade800 : Colors.orange.shade800;
    final bgColor = signed ? Colors.green.shade50 : Colors.orange.shade50;
    final borderColor = signed ? Colors.green.shade200 : Colors.orange.shade200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            signed ? Icons.check_circle : Icons.schedule,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label: ${signed ? "Registrada" : "Pendiente"}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (signed && persona != null && persona.isNotEmpty)
                Text(
                  'Cédula: $persona',
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndRegisterExit(
    BuildContext context,
    RequisitionSignatureProvider provider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Confirmar Salida'),
          ],
        ),
        content: Text(
          '¿Está seguro de registrar la salida para el documento ${widget.document.tipoDocumento} #${widget.document.numero}?\n\nEsta acción actualizará el stock oficial.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Registrar Salida'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    final success = await provider.registerExit(
      empresa: widget.document.empresa,
      tipoDocumento: widget.document.tipoDocumento,
      numero: widget.document.numero,
    );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Salida registrada exitosamente.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      await DialogUtils.showErrorDialog(
        context,
        title: 'Error al Registrar Salida',
        message: provider.actionError ?? 'No fue posible registrar la salida.',
        technicalDetails: provider.technicalDetails,
        statusCode: provider.statusCode,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequisitionSignatureProvider>();
    final auth = context.watch<AuthProvider>();

    final doc = widget.document;
    final detail = provider.getDetail(
      doc.empresa,
      doc.tipoDocumento,
      doc.numero,
    );
    final isLoadingDetail = provider.isDetailLoading(
      doc.empresa,
      doc.tipoDocumento,
      doc.numero,
    );
    final detailError = provider.getDetailError(
      doc.empresa,
      doc.tipoDocumento,
      doc.numero,
    );

    // Búsqueda de firmas SA (Salida) y RE (Recibo)
    RequisicionFirma? firmaSA;
    RequisicionFirma? firmaRE;

    if (detail != null) {
      for (final f in detail.firmas) {
        if (f.tipo.toUpperCase() == 'SA') firmaSA = f;
        if (f.tipo.toUpperCase() == 'RE') firmaRE = f;
      }
    }

    final bool isSourceSigned = firmaSA?.firmada == true;
    final bool isTargetSigned = firmaRE?.firmada == true;
    final bool bothSigned = isSourceSigned && isTargetSigned;

    // Inferencia de Rol y Reglas de Seguridad Operativa
    final String currentCedula = auth.currentCedula?.trim() ?? '';
    final String? terceroSolicitante = detail?.tercero?.trim();
    final String? respBodegaFuente = detail?.responsableBodega?.trim();
    final String? respBodegaDestino = detail?.responsableBodegaDestino?.trim();

    // 1. Validación de Despachador (Firma SA - Entrega y Cierre de Salida)
    final bool isDispatcher =
        respBodegaFuente != null &&
        respBodegaFuente.isNotEmpty &&
        currentCedula == respBodegaFuente;

    // 2. Validación de Receptor (Firma RE - Recibe)
    final bool isReceiver =
        currentCedula.isNotEmpty &&
        (currentCedula == terceroSolicitante ||
            (respBodegaDestino != null &&
                respBodegaDestino.isNotEmpty &&
                currentCedula == respBodegaDestino));

    final bool canSignSA = !isSourceSigned && isDispatcher;
    final bool canSignRE = !isTargetSigned && isReceiver;

    // Color de la franja lateral de 5px: verde si ambas firmas listas, azul si falta firma
    final Color statusColor = bothSigned
        ? Colors.green.shade700
        : Colors.blue.shade700;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Contenido principal de la tarjeta con padding de 5px para la franja
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: false,
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${doc.tipoDocumento} #${doc.numero}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Badge de Empresa
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        'Empresa ${doc.empresa}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bodega y Fecha
                      Row(
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Bodega: ${doc.bodega}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            doc.fecha,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Badge de artículos y badge de estado
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              '${doc.lineas} ${doc.lineas == 1 ? 'artículo entregado' : 'artículos entregados'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              bothSigned
                                  ? 'LISTA PARA ERP'
                                  : 'FIRMAS PENDIENTES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (detail?.observacion != null &&
                          detail!.observacion!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Obs: ${detail.observacion!.trim()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Badges de Firmas SA y RE
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildSignatureBadge(
                            label: 'Firma Salida (SA)',
                            signed: isSourceSigned,
                            persona: firmaSA?.persona,
                            fecha: firmaSA?.fechaFirma,
                          ),
                          _buildSignatureBadge(
                            label: 'Firma Recibo (RE)',
                            signed: isTargetSigned,
                            persona: firmaRE?.persona,
                            fecha: firmaRE?.fechaFirma,
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Acciones Operativas (Inferencia Automática de Roles y Matriz de Estados)
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (isLoadingDetail && detail == null) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ] else if (bothSigned) ...[
                            if (isDispatcher)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Registrar Salida'),
                                onPressed: provider.isRegisteringExit
                                    ? null
                                    : () => _confirmAndRegisterExit(
                                        context,
                                        provider,
                                      ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Firmas completas. Pendiente registro de salida por el responsable de la bodega.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ] else if (canSignSA) ...[
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.draw_rounded, size: 18),
                              label: const Text('Firmar Salida (SA)'),
                              onPressed:
                                  (isLoadingDetail ||
                                      provider.isSubmittingSignature)
                                  ? null
                                  : () async {
                                      final signed = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              RequisitionSignatureCaptureScreen(
                                                empresa: doc.empresa,
                                                tipoDocumento:
                                                    doc.tipoDocumento,
                                                numero: doc.numero,
                                                tipo: 'SA',
                                                personaDefault:
                                                    auth.currentCedula,
                                                nombreFirmanteDefault:
                                                    auth.currentUsername,
                                              ),
                                        ),
                                      );
                                      if (signed == true && context.mounted) {
                                        provider.loadDetail(
                                          doc.empresa,
                                          doc.tipoDocumento,
                                          doc.numero,
                                          force: true,
                                        );
                                      }
                                    },
                            ),
                          ] else if (canSignRE) ...[
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.draw_rounded, size: 18),
                              label: const Text('Firmar Recibo (RE)'),
                              onPressed:
                                  (isLoadingDetail ||
                                      provider.isSubmittingSignature)
                                  ? null
                                  : () async {
                                      final signed = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              RequisitionSignatureCaptureScreen(
                                                empresa: doc.empresa,
                                                tipoDocumento:
                                                    doc.tipoDocumento,
                                                numero: doc.numero,
                                                tipo: 'RE',
                                                personaDefault:
                                                    auth.currentCedula,
                                                nombreFirmanteDefault:
                                                    auth.currentUsername,
                                                solicitanteTercero:
                                                    detail?.tercero,
                                              ),
                                        ),
                                      );
                                      if (signed == true && context.mounted) {
                                        provider.loadDetail(
                                          doc.empresa,
                                          doc.tipoDocumento,
                                          doc.numero,
                                          force: true,
                                        );
                                      }
                                    },
                            ),
                          ] else if (isReceiver &&
                              isTargetSigned &&
                              !isSourceSigned) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blueGrey.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.hourglass_top_rounded,
                                    size: 15,
                                    color: Colors.blueGrey.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Su firma de recibo está registrada. Pendiente salida de bodega.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blueGrey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (isDispatcher &&
                              isSourceSigned &&
                              !isTargetSigned) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blueGrey.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.hourglass_top_rounded,
                                    size: 15,
                                    color: Colors.blueGrey.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Firma de salida registrada. Pendiente recibo del solicitante.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blueGrey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 15,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Usted no es responsable de la bodega ni solicitante de este documento.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                children: [
                  // Detalle de Artículos y Movimientos Entregados
                  if (isLoadingDetail)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Consultando artículos entregados...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (detailError != null)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              detailError,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => provider.loadDetail(
                              doc.empresa,
                              doc.tipoDocumento,
                              doc.numero,
                              force: true,
                            ),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  else if (detail != null)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: detail.lineas.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, lineIndex) {
                        final linea = detail.lineas[lineIndex];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.blueGrey.shade50,
                                child: Text(
                                  '${lineIndex + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      linea.articulo,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (linea.descripcion.trim().isNotEmpty)
                                      Text(
                                        linea.descripcion,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    if (linea.placas.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 2,
                                        children: linea.placas.map((placa) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Text(
                                              placa,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${linea.entregada} ${linea.unidad}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Entregada',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Franja lateral izquierda fija de 5px (Identidad canónica SigoAPP)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: ColoredBox(color: statusColor),
          ),
        ],
      ),
    );
  }
}
