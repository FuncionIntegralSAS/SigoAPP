import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:sigo_app/modules/inventory/providers/transfer_approval_provider.dart';
import 'package:sigo_app/modules/inventory/widgets/transfer_filter_panel.dart';
import 'package:sigo_app/modules/inventory/models/transfer_request.dart';
import 'package:sigo_app/shared/widgets/app_error_widget.dart';
import 'package:sigo_app/utils/dialog_utils.dart';

class TransferApprovalScreen extends StatefulWidget {
  const TransferApprovalScreen({super.key});

  @override
  State<TransferApprovalScreen> createState() => _TransferApprovalScreenState();
}

class _TransferApprovalScreenState extends State<TransferApprovalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TransferApprovalProvider>();
      provider.loadTransfers();
    });
  }

  String _getEmptyStateTitle(TransferStatus status) {
    switch (status) {
      case TransferStatus.pending:
        return 'Sin solicitudes pendientes';
      case TransferStatus.approved:
        return 'No hay solicitudes aprobadas';
      case TransferStatus.rejected:
        return 'No hay solicitudes rechazadas';
      case TransferStatus.received:
        return 'No hay solicitudes recibidas';
      case TransferStatus.completed:
        return 'No hay trámites procesados';
      case TransferStatus.sourceSigned:
        return 'No hay trámites firmados por origen';
      case TransferStatus.targetSigned:
        return 'No hay trámites firmados por destino';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TransferApprovalProvider>();
    final transfers = provider.filteredTransfers;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Aprobación de Traspasos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Actualizar lista',
            onPressed: provider.loading ? null : () => provider.loadTransfers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Panel superior móvil con chips de estado y filtros secundarios
          TransferFilterPanel(
            filter: provider.filter,
            availableWarehouses: provider.availableWarehouses,
            onFilterChanged: provider.updateFilter,
          ),
          // Franja superior de resumen institucional
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Text(
              'Solicitudes en lista: ${transfers.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          if (provider.loading)
            const LinearProgressIndicator(minHeight: 2),
          // Lista de traspasos con soporte pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadTransfers(),
              child: provider.error != null && transfers.isEmpty
                  ? AppErrorWidget.view(
                      title: 'Error al cargar trámites',
                      message: provider.error!,
                      onRetry: () => provider.loadTransfers(),
                    )
                  : transfers.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    provider.loading
                                        ? Icons.hourglass_top_rounded
                                        : Icons.assignment_turned_in_outlined,
                                    size: 48,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  provider.loading
                                      ? 'Cargando solicitudes...'
                                      : _getEmptyStateTitle(provider.filter.status),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  provider.loading
                                      ? 'Por favor espere un momento'
                                      : 'No se encontraron solicitudes que coincidan con los criterios seleccionados.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                                if (!provider.loading) ...[
                                  const SizedBox(height: 20),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    label: const Text('Actualizar'),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => provider.loadTransfers(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            top: 8,
                            bottom: 24,
                          ),
                          itemCount: transfers.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final request = transfers[index];
                            return _TransferCard(
                              key: ValueKey(request.id),
                              request: request,
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferCard extends StatefulWidget {
  final TransferRequest request;

  const _TransferCard({
    super.key,
    required this.request,
  });

  @override
  State<_TransferCard> createState() => _TransferCardState();
}

class _TransferCardState extends State<_TransferCard> {
  bool _isArticlesExpanded = false;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    final hourStr = date.hour.toString().padLeft(2, '0');
    final minStr = date.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minStr';

    if (dateDay == today) {
      return 'Hoy, $timeStr';
    } else if (dateDay == yesterday) {
      return 'Ayer, $timeStr';
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = _monthName(date.month);
      return '$day $month ${date.year}, $timeStr';
    }
  }

  String _monthName(int month) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  Color _getStatusColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.pending:
        return Colors.amber.shade800;
      case TransferStatus.approved:
        return Colors.green.shade700;
      case TransferStatus.rejected:
        return Colors.red.shade700;
      case TransferStatus.received:
        return Colors.blue.shade700;
      case TransferStatus.sourceSigned:
        return Colors.purple.shade700;
      case TransferStatus.targetSigned:
        return Colors.teal.shade700;
      case TransferStatus.completed:
        return Colors.indigo.shade700;
    }
  }

  Widget _buildStatusBadge(TransferStatus status) {
    final color = _getStatusColor(status);
    String text;
    IconData icon;

    switch (status) {
      case TransferStatus.pending:
        icon = Icons.schedule_rounded;
        text = 'Pendiente';
        break;
      case TransferStatus.approved:
        icon = Icons.check_circle_outline_rounded;
        text = 'Aprobado';
        break;
      case TransferStatus.rejected:
        icon = Icons.cancel_outlined;
        text = 'Rechazado';
        break;
      case TransferStatus.received:
        icon = Icons.mark_email_read_outlined;
        text = 'Recibido';
        break;
      case TransferStatus.sourceSigned:
        icon = Icons.draw_outlined;
        text = 'Firmado Entrega';
        break;
      case TransferStatus.targetSigned:
        icon = Icons.draw_outlined;
        text = 'Firmado Recibe';
        break;
      case TransferStatus.completed:
        icon = Icons.done_all_rounded;
        text = 'Procesado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _displayBodega(String rawBodega, {required bool isOrigen}) {
    final clean = rawBodega.trim();
    if (clean.isEmpty || clean == 'BOD-ORIGEN' || clean == 'BOD-DESTINO') {
      return isOrigen ? 'BOG001 - Almacén Central' : 'MED002 - Taller de Mantenimiento';
    }
    return clean;
  }

  Widget _buildFlowSection(BuildContext context, TransferRequest request) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Origen
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: Colors.blueGrey.shade700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _displayBodega(request.bodegaActual, isOrigen: true),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (request.responsableActual.isNotEmpty)
                        Text(
                          request.responsableActual,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Flecha central sutil
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 15,
              color: Colors.grey.shade400,
            ),
          ),
          // Destino
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.warehouse_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _displayBodega(request.bodegaPropuesta, isOrigen: false),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (request.responsablePropuesto.isNotEmpty)
                        Text(
                          request.responsablePropuesto,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticlesSection(BuildContext context, TransferRequest request) {
    final theme = Theme.of(context);
    final count = request.articulos.length;

    if (count <= 1) {
      // 1 solo artículo
      final item = request.articulos.isNotEmpty ? request.articulos.first : null;
      final desc = item?.nombre != null && item!.nombre!.trim().isNotEmpty
          ? item.nombre!.trim()
          : (request.nombreArticulo.isNotEmpty ? request.nombreArticulo : (item?.articulo ?? ''));
      final codigo = item?.articulo ?? request.idArticulo;
      final placa = item?.placa ?? request.placa;
      final hasDistinctDesc = desc.isNotEmpty && desc != codigo;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 16,
              color: Colors.blueGrey.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasDistinctDesc ? desc : codigo,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasDistinctDesc)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        'Código: $codigo',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (placa != null && placa.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Placa: $placa',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Múltiples artículos con acordeón compacto
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                _isArticlesExpanded = !_isArticlesExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: Colors.blueGrey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '$count artículos',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (request.articulos.first.nombre != null &&
                              request.articulos.first.nombre!.trim().isNotEmpty)
                          ? '${request.articulos.first.nombre!.trim()} (${request.articulos.first.articulo})'
                          : request.articulos.first.articulo,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _isArticlesExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_isArticlesExpanded) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int index = 0; index < request.articulos.length; index++) ...[
                    if (index > 0)
                      Divider(height: 6, color: Colors.grey.shade200),
                    _buildArticleRow(request.articulos[index], theme),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArticleRow(TransferArticleItem art, ThemeData theme) {
    final hasNombre =
        art.nombre != null && art.nombre!.trim().isNotEmpty;
    final desc = hasNombre ? art.nombre!.trim() : art.articulo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.circle,
            size: 5,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasNombre)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      'Código: ${art.articulo}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (art.placa != null && art.placa!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'Placa: ${art.placa}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransferApprovalProvider>();
    final isProcessing = provider.isProcessing(widget.request.id);
    final request = widget.request;
    final statusColor = _getStatusColor(request.estado);

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra vertical izquierda de estado institucional (5px)
              Container(
                width: 5,
                color: statusColor,
              ),
              // Contenido principal de la tarjeta
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fila 1: Trámite ID, Documento y Estado
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              'Trámite #${request.id}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (request.numeroDocumento != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                '${request.tipoDocumento ?? "DOC"} #${request.numeroDocumento}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          _buildStatusBadge(request.estado),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Fila 2: Fecha de solicitud
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(request.fechaSolicitud),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Flujo Origen -> Destino Compacto
                      _buildFlowSection(context, request),
                      const SizedBox(height: 8),
                      // Artículos
                      _buildArticlesSection(context, request),
                      // Motivo de la solicitud (si existe)
                      if (request.motivoSolicitud.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.format_quote_rounded,
                                size: 15,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  request.motivoSolicitud,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Motivo del rechazo (si fue rechazado y tiene motivo)
                      if (request.motivoRechazo != null &&
                          request.motivoRechazo!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 15,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Motivo de rechazo:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      request.motivoRechazo!,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.red.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Botones de acción: solo si el trámite está pendiente
                      if (request.estado == TransferStatus.pending) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isProcessing)
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Procesando...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(
                                    color: Colors.red.shade300,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                                icon: const Icon(Icons.cancel_outlined,
                                    size: 15),
                                label: const Text('Rechazar'),
                                onPressed: () => _confirmReject(
                                    context, provider, request),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B5E20),
                                  foregroundColor: Colors.white,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                icon: const Icon(
                                    Icons.check_circle_outline,
                                    size: 15),
                                label: const Text('Aprobar'),
                                onPressed: () async {
                                  HapticFeedback.lightImpact();
                                  final success = await provider
                                      .approveTransfer(request.id);
                                  if (!context.mounted) return;

                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Traspaso aprobado correctamente'),
                                        backgroundColor: Color(0xFF1B5E20),
                                      ),
                                    );
                                  } else {
                                    DialogUtils.showErrorDialog(
                                      context,
                                      title: 'Error al Aprobar Traspaso',
                                      message: provider.error ??
                                          'No fue posible aprobar la solicitud.',
                                      statusCode: provider.statusCode,
                                      technicalDetails:
                                          provider.technicalDetails,
                                      buttonText: 'Aceptar',
                                    );
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReject(
    BuildContext context,
    TransferApprovalProvider provider,
    TransferRequest request,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isMotivoValid = controller.text.trim().isNotEmpty;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Rechazar Traspaso',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Estás seguro de rechazar el trámite #${request.id}? Esta acción registrará el rechazo en el sistema.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      maxLength: 500,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Motivo del rechazo *',
                        hintText: 'Explica el motivo por el cual se rechaza este traspaso...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        helperText: 'El motivo es obligatorio',
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Rechazar Trámite'),
                  onPressed: !isMotivoValid
                      ? null
                      : () async {
                          final motivo = controller.text.trim();
                          Navigator.pop(dialogContext);

                          final success = await provider.rejectTransfer(
                            request.id,
                            motivo,
                          );
                          if (!context.mounted) return;

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Traspaso rechazado correctamente'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          } else {
                            DialogUtils.showErrorDialog(
                              context,
                              title: 'Error al Rechazar Traspaso',
                              message: provider.error ??
                                  'No fue posible rechazar la solicitud.',
                              statusCode: provider.statusCode,
                              technicalDetails: provider.technicalDetails,
                              buttonText: 'Aceptar',
                            );
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
