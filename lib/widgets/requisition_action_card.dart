import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/requisition_model.dart';
import '../providers/requisition_approval_provider.dart';

/// Tarjeta de Documento de Requisición (Nivel 1) con flujo Master-Detail.
///
/// Expone la cabecera del documento (tipo, número, bodega, fecha, cantidad de artículos)
/// y consulta bajo demanda sus movimientos y líneas detalladas (Nivel 2) al expandir.
class RequisitionActionCard extends StatefulWidget {
  final RequisicionResumen document;
  final String currentTabStatus;

  const RequisitionActionCard({
    super.key,
    required this.document,
    required this.currentTabStatus,
  });

  @override
  State<RequisitionActionCard> createState() => _RequisitionActionCardState();
}

class _RequisitionActionCardState extends State<RequisitionActionCard> {
  bool _isExpanded = false;

  Color _getStatusColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'in':
        return Colors.amber.shade800;
      case 'ap':
        return Colors.green.shade700;
      case 'en':
        return Colors.blue.shade700;
      case 'ae':
      case 'an':
        return Colors.red.shade700;
      case 'rg':
        return Colors.indigo.shade700;
      default:
        return Colors.blueGrey.shade700;
    }
  }

  String _getStatusLabel(String estado) {
    switch (estado.toLowerCase()) {
      case 'in':
        return 'PENDIENTE';
      case 'ap':
        return 'APROBADA';
      case 'en':
        return 'ENTREGADA';
      case 'ae':
      case 'an':
        return 'ANULADA';
      case 'rg':
        return 'REGISTRADA';
      default:
        return estado.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequisitionApprovalProvider>();
    final doc = widget.document;
    final detail = provider.getDetail(doc.empresa, doc.tipoDocumento, doc.numero);
    final isLoadingDetail = provider.isDetailLoading(doc.empresa, doc.tipoDocumento, doc.numero);
    final detailError = provider.getDetailError(doc.empresa, doc.tipoDocumento, doc.numero);
    final isDocModified = provider.isDocumentModified(doc.empresa, doc.tipoDocumento, doc.numero);
    final selectedLinesCount = provider.countSelectedLinesForDocument(doc.empresa, doc.tipoDocumento, doc.numero);
    final statusColor = _getStatusColor(doc.estado);

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
          // Contenido expandible del Documento con padding para la franja lateral
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                key: ValueKey<String>(
                  'tile_${doc.empresa}_${doc.tipoDocumento}_${doc.numero}',
                ),
                tilePadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                childrenPadding: EdgeInsets.zero,
                initiallyExpanded: _isExpanded,
                onExpansionChanged: (expanded) {
                  setState(() => _isExpanded = expanded);
                  if (expanded && detail == null && !isLoadingDetail) {
                    provider.fetchDocumentDetail(
                      doc.empresa,
                      doc.tipoDocumento,
                      doc.numero,
                    );
                  }
                },
                title: Row(
                  children: [
                    // Checkbox a nivel del Documento como indicador / selector masivo
                    Transform.scale(
                      scale: 0.9,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isDocModified,
                          activeColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (bool? checked) async {
                            if (checked == true) {
                              if (detail != null) {
                                provider.selectAllForDocument(detail, widget.currentTabStatus);
                              } else {
                                await provider.fetchDocumentDetail(
                                  doc.empresa,
                                  doc.tipoDocumento,
                                  doc.numero,
                                );
                                final loaded = provider.getDetail(
                                  doc.empresa,
                                  doc.tipoDocumento,
                                  doc.numero,
                                );
                                if (loaded != null) {
                                  provider.selectAllForDocument(loaded, widget.currentTabStatus);
                                }
                              }
                            } else {
                              provider.deselectDocumentByTerna(
                                doc.empresa,
                                doc.tipoDocumento,
                                doc.numero,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (isDocModified) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_note, size: 14, color: Colors.green.shade800),
                            const SizedBox(width: 2),
                            Text(
                              '$selectedLinesCount mod.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Badge de Estado del Documento
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _getStatusLabel(doc.estado),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
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
                      Row(
                        children: [
                          Icon(Icons.storefront_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Bodega: ${doc.bodega}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            doc.fecha,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Badge con la cantidad de movimientos/artículos
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '${doc.lineas} ${doc.lineas == 1 ? 'artículo solicitado' : 'artículos solicitados'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                children: [
                  PageStorage(
                    bucket: PageStorageBucket(),
                    child: _buildExpansionContent(
                      context,
                      provider,
                      doc,
                      detail,
                      isLoadingDetail,
                      detailError,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Franja lateral izquierda de 5px (Identidad canónica SigoAPP)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: ColoredBox(
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionContent(
    BuildContext context,
    RequisitionApprovalProvider provider,
    RequisicionResumen doc,
    RequisicionDetalle? detail,
    bool isLoading,
    String? error,
  ) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        color: Colors.grey.shade50,
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'Consultando movimientos del documento...',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade50,
        child: Column(
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => provider.fetchDocumentDetail(
                doc.empresa,
                doc.tipoDocumento,
                doc.numero,
                force: true,
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar movimientos'),
            ),
          ],
        ),
      );
    }

    if (detail == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadatos de Cabecera
          if (detail.tercero != null && detail.tercero!.isNotEmpty) ...[
            _buildMetaRow('Solicitante:', detail.tercero!),
            const SizedBox(height: 4),
          ],
          if (detail.fechaRequerida != null && detail.fechaRequerida!.isNotEmpty) ...[
            _buildMetaRow('Fecha requerida:', detail.fechaRequerida!),
            const SizedBox(height: 4),
          ],
          if (detail.observacion != null && detail.observacion!.trim().isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote_rounded, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      detail.observacion!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],

          const SizedBox(height: 6),
          // Barra de acciones del documento (Seleccionar todo / Limpiar)
          Row(
            children: [
              Expanded(
                child: Text(
                  'Líneas (${detail.lineas.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  visualDensity: VisualDensity.compact,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => provider.selectAllForDocument(detail, widget.currentTabStatus),
                icon: const Icon(Icons.done_all, size: 14),
                label: const Text('Todo', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  visualDensity: VisualDensity.compact,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => provider.deselectAllForDocument(detail),
                icon: const Icon(Icons.clear_all, size: 14, color: Colors.grey),
                label: const Text('Limpiar', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            ],
          ),
          const Divider(height: 12),

          // Desglose de Líneas de Movimiento (Nivel 2)
          ...detail.lineas.map(
            (linea) => _RequisitionMovementRow(
              linea: linea,
              documentEmpresa: doc.empresa,
              documentTipoDocumento: doc.tipoDocumento,
              documentNumero: doc.numero,
              currentTabStatus: widget.currentTabStatus,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 12),
        children: [
          TextSpan(text: '$label ', style: TextStyle(color: Colors.grey.shade600)),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Fila individual de movimiento (artículo) dentro del documento de requisición.
class _RequisitionMovementRow extends StatefulWidget {
  final RequisicionDetalleLinea linea;
  final String documentEmpresa;
  final String documentTipoDocumento;
  final dynamic documentNumero;
  final String currentTabStatus;

  const _RequisitionMovementRow({
    required this.linea,
    required this.documentEmpresa,
    required this.documentTipoDocumento,
    required this.documentNumero,
    required this.currentTabStatus,
  });

  @override
  State<_RequisitionMovementRow> createState() => _RequisitionMovementRowState();
}

class _RequisitionMovementRowState extends State<_RequisitionMovementRow> {
  late final TextEditingController _qtyController;

  String get _lineId =>
      '${widget.documentEmpresa}_${widget.documentTipoDocumento}_${widget.documentNumero}_${widget.linea.bodega}_${widget.linea.articulo}_${widget.linea.secuencia}';

  int get _maxAllowedQuantity {
    if (widget.currentTabStatus == 'in') {
      return widget.linea.solicitada.round();
    }
    if (widget.currentTabStatus == 'ap') {
      return widget.linea.aprobada.round();
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    final provider = context.read<RequisitionApprovalProvider>();
    final currentSelectedQty = provider.getSelectedItemQuantity(_lineId);
    _qtyController = TextEditingController(
      text: currentSelectedQty > 0 ? currentSelectedQty.toString() : '',
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _onQtyChanged(String text, RequisitionApprovalProvider provider) {
    final value = int.tryParse(text) ?? 0;
    final bool isValid = value > 0 && value <= _maxAllowedQuantity;

    if (isValid) {
      provider.toggleSelection(_lineId, true, value);
    } else {
      provider.toggleSelection(_lineId, false, 0);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequisitionApprovalProvider>();
    final isSelected = provider.isItemSelected(_lineId);
    final enteredQty = int.tryParse(_qtyController.text) ?? 0;
    final bool isQtyValid = enteredQty > 0 && enteredQty <= _maxAllowedQuantity;

    // Sincronizar controlador si se seleccionó en lote externamente ("Seleccionar todo" o Checkbox en cabecera)
    final selectedQtyInProvider = provider.getSelectedItemQuantity(_lineId);
    if (isSelected && selectedQtyInProvider > 0 && _qtyController.text != selectedQtyInProvider.toString()) {
      _qtyController.text = selectedQtyInProvider.toString();
    } else if (!isSelected && isQtyValid && selectedQtyInProvider == 0) {
      _qtyController.text = '';
    }

    final descArticulo = widget.linea.descripcion.isNotEmpty
        ? widget.linea.descripcion
        : widget.linea.articulo;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
              : Colors.grey.shade200,
          width: isSelected ? 1.2 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del Artículo (el Checkbox a nivel de movimiento ha sido eliminado)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        descArticulo,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 10, color: Colors.green.shade800),
                            const SizedBox(width: 2),
                            Text(
                              'Modificado',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Cód: ${widget.linea.articulo} • Sec: ${widget.linea.secuencia} • Und: ${widget.linea.unidad}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),

                // Desglose de cantidades según la pestaña activa
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildQuantityChip('Sol: ${widget.linea.solicitada.round()}'),
                    if (widget.currentTabStatus == 'ap' || widget.linea.aprobada > 0)
                      _buildQuantityChip(
                        'Aprob: ${widget.linea.aprobada.round()}',
                        isHighlight: widget.currentTabStatus == 'ap',
                      ),
                    if (widget.linea.entregada > 0)
                      _buildQuantityChip('Entr: ${widget.linea.entregada.round()}'),
                    if (widget.linea.pendiente > 0)
                      _buildQuantityChip('Pend: ${widget.linea.pendiente.round()}'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Campo de entrada de cantidad a procesar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.currentTabStatus == 'in' ? 'Aprobar' : 'Entregar',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 72,
                height: 36,
                child: TextField(
                  key: ValueKey('qty_field_$_lineId'),
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  onChanged: (text) => _onQtyChanged(text, provider),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    hintText: '$_maxAllowedQuantity',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: (_qtyController.text.isNotEmpty && !isQtyValid)
                            ? Colors.red.shade600
                            : (isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              if (_qtyController.text.isNotEmpty && !isQtyValid)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    'Máx: $_maxAllowedQuantity',
                    style: TextStyle(fontSize: 10, color: Colors.red.shade700),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityChip(String label, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isHighlight ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isHighlight ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
          color: isHighlight ? Colors.green.shade900 : Colors.grey.shade800,
        ),
      ),
    );
  }
}