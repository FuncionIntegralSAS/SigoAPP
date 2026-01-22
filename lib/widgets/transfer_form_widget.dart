import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/article_model.dart';
import '../providers/transfer_request_provider.dart';

class TransferFormWidget extends StatefulWidget {
  final ArticleModel article;
  final List<String> users;

  const TransferFormWidget({
    Key? key,
    required this.article,
    required this.users,
  }) : super(key: key);

  @override
  State<TransferFormWidget> createState() =>
      _TransferFormWidgetState();
}

class _TransferFormWidgetState
    extends State<TransferFormWidget> {
  final _formKey = GlobalKey<FormState>();

  late String _originalResponsible;
  String? _targetResponsible;
  String? _notes;

  @override
  void initState() {
    super.initState();
    _originalResponsible =
        widget.article.responsible ?? 'Sin responsable';
  }

  Future<void> _handleTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    try {
      final provider = context.read<TransferRequestProvider>();

      provider.createRequest(
        articleId: widget.article.id,
        articleName: widget.article.name,
        currentResponsible: _originalResponsible,
        proposedResponsible: _targetResponsible!,
        currentWarehouse: widget.article.warehouse,
        proposedWarehouse: widget.article.warehouse,
        requestReason: _notes ?? '',
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud de traspaso enviada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stack) {
      debugPrint(' Error al solicitar traspaso: $e');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),

              _buildSectionLabel('Responsable de Origen'),
              _buildReadOnlyField(
                text: _originalResponsible,
                icon: Icons.person_outline,
                color: Colors.grey.shade200,
              ),

              const SizedBox(height: 20),

              _buildSectionLabel('Responsable de Destino'),
              DropdownButtonFormField<String>(
                value: _targetResponsible,
                decoration: InputDecoration(
                  hintText: 'Seleccione el destinatario',
                  filled: true,
                  fillColor:
                      Colors.blue.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon:
                      const Icon(Icons.person_add_alt_1_outlined),
                ),
                items: widget.users
                    .where(
                      (u) => u != _originalResponsible,
                    )
                    .map(
                      (u) => DropdownMenuItem(
                        value: u,
                        child: Text(u),
                      ),
                    )
                    .toList(),
                validator: (value) =>
                    value == null ? 'Seleccione un destino' : null,
                onChanged: (value) =>
                    setState(() => _targetResponsible = value),
              ),

              const SizedBox(height: 20),

              _buildSectionLabel('Observaciones'),
              TextFormField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Motivo del traspaso o estado del artículo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSaved: (value) => _notes = value,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _handleTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swap_horiz_rounded),
                      SizedBox(width: 10),
                      Text(
                        'SOLICITAR TRASPASO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Traspaso de Activo',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'ID: ${widget.article.id}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String text,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
