import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:sigo_app/modules/auth/providers/auth_provider.dart';
import 'package:sigo_app/modules/requisitions/providers/requisition_signature_provider.dart';
import 'package:sigo_app/utils/app_logger.dart';
import 'package:sigo_app/utils/dialog_utils.dart';

/// Pantalla interactiva de captura de firma manuscrita digital para Requisiciones.
///
/// Permite capturar la firma de Salida (SA - Despachador de Bodega) o
/// la firma de Recibo (RE - Solicitante / Colaborador receptor),
/// con confirmación de cédula/documento de identidad.
class RequisitionSignatureCaptureScreen extends StatefulWidget {
  final String empresa;
  final String tipoDocumento;
  final dynamic numero;
  final String tipo; // 'SA' o 'RE'
  final String? personaDefault;
  final String? nombreFirmanteDefault;
  final String? solicitanteTercero;

  const RequisitionSignatureCaptureScreen({
    super.key,
    required this.empresa,
    required this.tipoDocumento,
    required this.numero,
    required this.tipo,
    this.personaDefault,
    this.nombreFirmanteDefault,
    this.solicitanteTercero,
  });

  @override
  State<RequisitionSignatureCaptureScreen> createState() =>
      _RequisitionSignatureCaptureScreenState();
}

class _RequisitionSignatureCaptureScreenState
    extends State<RequisitionSignatureCaptureScreen> {
  late final TextEditingController _cedulaController;
  final _formKey = GlobalKey<FormState>();

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _cedulaController = TextEditingController(text: widget.personaDefault ?? '');
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  bool get _isDispatcher => widget.tipo.toUpperCase() == 'SA';

  String get _signatureTitle =>
      _isDispatcher ? 'Firma de Salida (Bodega)' : 'Firma de Recibo (Solicitante)';

  String get _roleDescription => _isDispatcher
      ? 'Firma del despachador o encargado de bodega que autoriza la salida de los artículos.'
      : 'Firma del colaborador o dependencia solicitante que confirma la recepción física conforme.';

  Future<void> _handleSaveSignature() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Por favor, estampe la firma antes de guardar.'),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final Uint8List? bytes = await _signatureController.toPngBytes();
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al procesar los trazos de la firma.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
      return;
    }

    final String base64Signature = base64Encode(bytes);
    if (!mounted) return;

    final String cedula = _cedulaController.text.trim();
    final String formattedFirma = base64Signature.startsWith('data:image')
        ? base64Signature
        : 'data:image/png;base64,$base64Signature';

    final payloadMap = {
      'empresa': widget.empresa,
      'tipoDocumento': widget.tipoDocumento,
      'numero': widget.numero.toString(),
      'tipo': widget.tipo,
      'persona': cedula,
      'firma': formattedFirma,
    };

    AppLogger.i('================ PETICIÓN REGISTRAR FIRMA ================');
    AppLogger.i('Endpoint: PUT /api/v1/requisiciones/${widget.empresa}/${widget.tipoDocumento}/${widget.numero}/firmar');
    AppLogger.i('Payload (Objeto enviado al backend):');
    AppLogger.i('{\n'
        '  "tipo": "${payloadMap['tipo']}",\n'
        '  "persona": "${payloadMap['persona']}",\n'
        '  "firma": "${formattedFirma.length > 80 ? '${formattedFirma.substring(0, 80)}... [Longitud total: ${formattedFirma.length} chars]' : formattedFirma}"\n'
        '}');
    AppLogger.i('JSON completo serializado (RequisicionFirmaRequest):');
    debugPrint(jsonEncode({
      'tipo': widget.tipo,
      'persona': cedula,
      'firma': formattedFirma,
    }));
    AppLogger.i('==========================================================');

    final provider = context.read<RequisitionSignatureProvider>();
    final success = await provider.submitSignature(
      empresa: widget.empresa,
      tipoDocumento: widget.tipoDocumento,
      numero: widget.numero,
      tipo: widget.tipo,
      persona: cedula,
      firmaBase64: base64Signature,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text('$_signatureTitle registrada correctamente.'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      Navigator.pop(context, true);
    } else {
      await DialogUtils.showErrorDialog(
        context,
        title: 'Error al Registrar Firma',
        message: provider.actionError ?? 'No fue posible registrar la firma digital.',
        technicalDetails: provider.technicalDetails,
        statusCode: provider.statusCode,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequisitionSignatureProvider>();
    final auth = context.watch<AuthProvider>();
    final isBusy = provider.isSubmittingSignature;

    final isRecibo = widget.tipo.toUpperCase() == 'RE';

    return Scaffold(
      appBar: AppBar(
        title: Text(_signatureTitle),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta de información del documento
                  Card(
                    elevation: 1,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${widget.tipoDocumento} #${widget.numero}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _isDispatcher
                                      ? Colors.blue.shade50
                                      : Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _isDispatcher
                                        ? Colors.blue.shade200
                                        : Colors.teal.shade200,
                                  ),
                                ),
                                child: Text(
                                  _isDispatcher ? 'SALIDA (SA)' : 'RECIBO (RE)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _isDispatcher
                                        ? Colors.blue.shade800
                                        : Colors.teal.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _roleDescription,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                          ),
                          if (widget.nombreFirmanteDefault != null &&
                              widget.nombreFirmanteDefault!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Firmante sugerido: ${widget.nombreFirmanteDefault!.trim()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                          // Reflejo visual de titularidad o rol de despacho
                          if (isRecibo) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.teal.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified_user_rounded,
                                    color: Colors.teal.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Usted está firmando como receptor titular de esta requisición (${auth.currentUsername ?? auth.currentCedula}).',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.teal.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_isDispatcher) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Usted está firmando como despachador de almacén (${auth.currentUsername ?? auth.currentCedula}).',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Campo de Identificación / Cédula del Firmante (Fijado a sesión)
                  TextFormField(
                    controller: _cedulaController,
                    readOnly: true,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Cédula / Identificación del Firmante *',
                      hintText: 'Número de documento de la sesión',
                      helperText: isRecibo
                          ? 'Cédula del titular solicitante y receptor en sesión'
                          : 'Cédula del despachador de almacén en sesión',
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                      suffixIcon: const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La cédula o identificación es obligatoria';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Área de Lienzo / Canvas de Firma
                  const Text(
                    'Lienzo de Firma Manuscrita:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Signature(
                          controller: _signatureController,
                          height: 240,
                          backgroundColor: Colors.white,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          color: Colors.grey.shade100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Firme sobre el recuadro blanco',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: isBusy ? null : () => _signatureController.clear(),
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text('Limpiar trazo'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón de confirmación y guardado
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    onPressed: isBusy ? null : _handleSaveSignature,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Guardar y Registrar Firma',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bloqueo modal con indicador de carga
          if (isBusy)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text(
                          'Registrando firma...',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
