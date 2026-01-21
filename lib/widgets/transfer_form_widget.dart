import '../models/article_model.dart';
import '../models/transfer_request.dart';

import 'package:flutter/material.dart';

/// Widget de formulario para gestionar el traspaso de artículos entre responsables.
/// Recibe la lista de usuarios y el artículo desde el InventoryScreen.
class TransferFormWidget extends StatefulWidget {
  final ArticleModel article;
  final List<String> users;
  final Function(TransferRequest request) onTransferRequested;


  const TransferFormWidget({
    Key? key,
    required this.article,
    required this.users,
    required this.onTransferRequested,
  }) : super(key: key);

  @override
  _TransferFormWidgetState createState() => _TransferFormWidgetState();
}

class _TransferFormWidgetState extends State<TransferFormWidget> {
  final _formKey = GlobalKey<FormState>();
  
  late String _originalResponsible;
  String? _targetResponsible;
  String? _notes;

  @override
  void initState() {
    super.initState();
    // Se extrae el responsable original del estado actual del artículo
    _originalResponsible = widget.article.responsible ?? 'Sin responsable';
  }

  void _handleTransfer() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final request = TransferRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        articleId: widget.article.id,
        articleName: widget.article.name,

        currentResponsible: _originalResponsible,
        proposedResponsible: _targetResponsible!,

        currentWarehouse: widget.article.warehouse,
        proposedWarehouse: widget.article.warehouse, 

        requestReason: _notes ?? '',
        requestDate: DateTime.now(),
      );

      widget.onTransferRequested(request);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              
              // Sección de Origen (Visual/Informativa)
              _buildSectionLabel('Responsable de Origen'),
              _buildReadOnlyField(
                text: _originalResponsible,
                icon: Icons.person_outline,
                color: Colors.grey.shade200,
              ),
              
              const SizedBox(height: 20),

              // Sección de Destino (Interacción)
              _buildSectionLabel('Responsable de Destino'),
              DropdownButtonFormField<String>(
                value: _targetResponsible,
                decoration: InputDecoration(
                  hintText: 'Seleccione el destinatario',
                  filled: true,
                  fillColor: Colors.blue.withValues(alpha: 0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_add_alt_1_outlined),
                ),
                // Filtramos la lista recibida para no mostrar al responsable actual
                items: widget.users
                    .where((user) => user != _originalResponsible)
                    .map((user) => DropdownMenuItem(value: user, child: Text(user)))
                    .toList(),
                validator: (value) => value == null ? 'Seleccione un destino' : null,
                onChanged: (value) => setState(() => _targetResponsible = value),
              ),

              const SizedBox(height: 20),

              // Observaciones
              _buildSectionLabel('Observaciones'),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Motivo del traspaso o estado del artículo...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                onSaved: (value) => _notes = value,
              ),

              const SizedBox(height: 32),

              // Botón de ejecución
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _handleTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swap_horiz_rounded),
                      SizedBox(width: 10),
                      Text('SOLICITAR TRASPASO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
            const Text('Traspaso de Activo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('ID: ${widget.article.id}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
        )
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  Widget _buildReadOnlyField({required String text, required IconData icon, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)),
        ],
      ),
    );
  }
}