import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/models/article_model.dart';
import '../providers/transfer_request_provider.dart';

class TransferFormWidget extends StatefulWidget {
  final ArticleModel article;
  final List<String> users;
  final String? proposedWarehouse;
  final String? proposedResponsible;

  const TransferFormWidget({
    Key? key,
    required this.article,
    required this.users,
    this.proposedWarehouse,
    this.proposedResponsible,
  }) : super(key: key);

  @override
  State<TransferFormWidget> createState() => _TransferFormWidgetState();
}

class _TransferFormWidgetState extends State<TransferFormWidget> {
  String? _targetResponsible;
  String? _notes;
  late String _originalResponsible;

  @override
  void initState() {
    super.initState();
    _originalResponsible =
        widget.article.responsible ?? 'Sin responsable';

    _targetResponsible = widget.proposedResponsible;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransferRequestProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solicitud de Traspaso',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Text('Activo: ${widget.article.name}'),
          const SizedBox(height: 8),

          Text('Responsable actual: $_originalResponsible'),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: _targetResponsible,
            hint: const Text('Seleccionar responsable destino'),
            items: widget.users
                .map(
                  (u) => DropdownMenuItem(
                    value: u,
                    child: Text(u),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _targetResponsible = value;
              });
            },
          ),

          const SizedBox(height: 12),

          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Observaciones',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (value) {
              _notes = value;
            },
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await provider.createRequest(
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
              },
              child: provider.loading
                  ? const CircularProgressIndicator()
                  : const Text('Crear solicitud'),
            ),
          ),
        ],
      ),
    );
  }
}
