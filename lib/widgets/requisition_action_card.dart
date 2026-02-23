import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RequisitionActionCard extends StatefulWidget {
  final String articulo;
  final String solicita;
  final String estado;
  final String empresa;
  final String tipoDocumento;
  final String numero;
  final String fecha;
  final String bodega;
  final String unidad;
  final String observacion;
  
  // Campos fijos de cantidad
  final int cantidadSolicitada;
  final int cantidadAprobada;
  final int cantidadEntregada;
  
  final Function(bool, int) onSelectionChanged;

  const RequisitionActionCard({
    Key? key,
    required this.articulo,
    required this.solicita,
    required this.estado,
    required this.empresa,
    required this.tipoDocumento,
    required this.numero,
    required this.fecha,
    required this.bodega,
    required this.unidad,
    required this.observacion,
    required this.cantidadSolicitada,
    required this.cantidadAprobada,
    required this.cantidadEntregada,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  State<RequisitionActionCard> createState() => _RequisitionActionCardState();
}

class _RequisitionActionCardState extends State<RequisitionActionCard> {
  final TextEditingController _actionController = TextEditingController();
  bool _isChecked = false;
  bool _isCheckboxEnabled = false;

  @override
  void dispose() {
    _actionController.dispose();
    super.dispose();
  }

  // Define el límite de validación según el estado actual
  int get _maxAllowedQuantity {
    if (widget.estado == 'in') return widget.cantidadSolicitada;
    if (widget.estado == 'ap') return widget.cantidadAprobada;
    return 0; // Para otros estados o fallback
  }

  // Define la etiqueta del indicador visual
  String get _chipLabel {
    if (widget.estado == 'in') return 'Req: ${widget.cantidadSolicitada}';
    if (widget.estado == 'ap') return 'Aprob: ${widget.cantidadAprobada}';
    return 'Cant: 0';
  }

  // Define el texto de sugerencia del campo de entrada
  String get _inputHint {
    if (widget.estado == 'in') return 'Aprob.';
    if (widget.estado == 'ap') return 'Entreg.';
    return '';
  }

  void _validateInput(String text) {
    final value = int.tryParse(text) ?? 0;
    
    // Validamos contra el límite dinámico calculado
    final bool isValid = value > 0 && value <= _maxAllowedQuantity;
    
    setState(() {
      _isCheckboxEnabled = isValid;
      if (!isValid && _isChecked) {
        _isChecked = false;
        widget.onSelectionChanged(false, 0);
      }
    });
  }

  Color _getStatusColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'in': return Colors.blueGrey;
      case 'ap': return Colors.green;
      case 'en': return Colors.orange;
      case 'an': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.only(left: 8.0, right: 16.0),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _isChecked,
                onChanged: _isCheckboxEnabled
                    ? (bool? value) {
                        setState(() => _isChecked = value ?? false);
                        widget.onSelectionChanged(
                          _isChecked,
                          int.parse(_actionController.text),
                        );
                      }
                    : null,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.articulo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.solicita,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Chip(
                    label: Text(_chipLabel),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 75,
                    height: 40,
                    child: TextField(
                      controller: _actionController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      onChanged: _validateInput,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(8),
                        hintText: _inputHint,
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: (_actionController.text.isNotEmpty && !_isCheckboxEnabled) 
                                ? Colors.red 
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetaRow('Empresa / Bodega:', '${widget.empresa} | ${widget.bodega}'),
                  const SizedBox(height: 8),
                  _buildMetaRow('Documento:', '${widget.tipoDocumento} #${widget.numero}'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetaRow('Fecha:', widget.fecha),
                      Row(
                        children: [
                          const Text('Estado: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.estado).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _getStatusColor(widget.estado)),
                            ),
                            child: Text(
                              widget.estado.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(widget.estado),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow('Unidad:', widget.unidad),
                  const Divider(height: 24),
                  const Text('Observación:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    widget.observacion,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 13),
        children: [
          TextSpan(text: '$label ', style: const TextStyle(color: Colors.grey)),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}