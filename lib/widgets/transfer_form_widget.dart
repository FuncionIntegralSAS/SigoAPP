import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../models/article_model.dart';
import '../models/warehouse_model.dart';
import '../providers/transfer_request_provider.dart';
import '../services/mock_inventory_service.dart';
import '../utils/dropdown_template.dart';

class TransferFormWidget extends StatefulWidget {
  final ArticleModel article;
  final List<String> users;
  final List<WarehouseModel>? warehouses;
  final String? proposedWarehouse;
  final String? proposedResponsible;

  const TransferFormWidget({
    super.key,
    required this.article,
    required this.users,
    this.warehouses,
    this.proposedWarehouse,
    this.proposedResponsible,
  });

  @override
  State<TransferFormWidget> createState() => _TransferFormWidgetState();
}

class _TransferFormWidgetState extends State<TransferFormWidget> {
  String? _targetResponsible;
  WarehouseModel? _targetWarehouse;
  String? _notes;
  late String _originalResponsible;
  late List<WarehouseModel> _availableWarehouses;

  final TextEditingController _responsibleSearchController =
      TextEditingController();
  final ValueNotifier<String?> _responsibleNotifier = ValueNotifier(null);

  final TextEditingController _warehouseSearchController =
      TextEditingController();
  final ValueNotifier<WarehouseModel?> _warehouseNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _originalResponsible =
        widget.article.responsible ?? 'Sin responsable';

    _targetResponsible = widget.users.contains(widget.proposedResponsible)
        ? widget.proposedResponsible
        : null;
    _responsibleNotifier.value = _targetResponsible;

    if (_targetResponsible != null) {
      _availableWarehouses = _getWarehousesFor(_targetResponsible!);
      if (widget.proposedWarehouse != null) {
        final matches = _availableWarehouses.where(
          (w) => w.bodeCodi == widget.proposedWarehouse,
        );
        if (matches.isNotEmpty) {
          _targetWarehouse = matches.first;
        }
      }
    } else {
      _availableWarehouses = [];
    }
    _warehouseNotifier.value = _targetWarehouse;
  }

  List<WarehouseModel> _getWarehousesFor(String responsible) {
    return MockInventoryService().getWarehousesForResponsible(responsible);
  }

  @override
  void dispose() {
    _responsibleSearchController.dispose();
    _responsibleNotifier.dispose();
    _warehouseSearchController.dispose();
    _warehouseNotifier.dispose();
    super.dispose();
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

          Text('Bodega actual: ${widget.article.warehouse}'),
          const SizedBox(height: 12),

          // 1. Selector de Responsable Destino (PRIMERO)
          DropdownButtonFormField2<String>(
            isExpanded: true,
            valueListenable: _responsibleNotifier,
            hint: widget.users.isEmpty
                ? const Text('No hay responsables disponibles')
                : const Text('Seleccionar responsable destino'),
            decoration: const InputDecoration(
              labelText: 'Responsable Destino',
              border: OutlineInputBorder(),
            ),
            items: widget.users
                .map(
                  (u) => DropdownItem<String>(
                    value: u,
                    child: Text(
                      u,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )
                .toList(),
            onChanged: widget.users.isEmpty
                ? null
                : (value) {
                    setState(() {
                      _targetResponsible = value;
                      _responsibleNotifier.value = value;
                      // Al cambiar de responsable se resetea la bodega seleccionada
                      _targetWarehouse = null;
                      _warehouseNotifier.value = null;
                      if (value != null) {
                        _availableWarehouses = _getWarehousesFor(value);
                      } else {
                        _availableWarehouses = [];
                      }
                    });
                  },
            dropdownSearchData: DropdownTemplates.searchData(
              controller: _responsibleSearchController,
              hintText: 'Buscar responsable...',
              searchMatchFn: (item, searchValue) {
                return item.value!
                    .toLowerCase()
                    .contains(searchValue.toLowerCase());
              },
            ),
            onMenuStateChange: (isOpen) {
              if (!isOpen) _responsibleSearchController.clear();
            },
          ),

          const SizedBox(height: 12),

          // 2. Selector de Bodega Destino (SEGUNDO - En cascada)
          DropdownButtonFormField2<WarehouseModel>(
            isExpanded: true,
            valueListenable: _warehouseNotifier,
            hint: _targetResponsible == null
                ? const Text('Seleccione primero un responsable')
                : (_availableWarehouses.isEmpty
                    ? const Text('No hay bodegas asociadas')
                    : const Text('Seleccionar bodega destino')),
            decoration: InputDecoration(
              labelText: 'Bodega Destino',
              border: const OutlineInputBorder(),
              enabled: _targetResponsible != null &&
                  _availableWarehouses.isNotEmpty,
            ),
            items: _availableWarehouses
                .map(
                  (w) => DropdownItem<WarehouseModel>(
                    value: w,
                    child: Text(
                      '${w.bodeCodi} - ${w.bodeDesc}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )
                .toList(),
            onChanged: (_targetResponsible == null ||
                    _availableWarehouses.isEmpty)
                ? null
                : (value) {
                    setState(() {
                      _targetWarehouse = value;
                      _warehouseNotifier.value = value;
                    });
                  },
            dropdownSearchData: DropdownTemplates.searchData(
              controller: _warehouseSearchController,
              hintText: 'Buscar bodega...',
              searchMatchFn: (item, searchValue) {
                final wh = item.value!;
                return wh.bodeDesc
                        .toLowerCase()
                        .contains(searchValue.toLowerCase()) ||
                    wh.bodeCodi
                        .toLowerCase()
                        .contains(searchValue.toLowerCase());
              },
            ),
            onMenuStateChange: (isOpen) {
              if (!isOpen) _warehouseSearchController.clear();
            },
          ),

          const SizedBox(height: 12),

          // 3. Observaciones
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

          // 4. Botón de Creación
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_targetResponsible == null || _targetWarehouse == null)
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      await provider.createRequest(
                        articleId: widget.article.id,
                        articleName: widget.article.name,
                        currentResponsible: _originalResponsible,
                        proposedResponsible: _targetResponsible!,
                        currentWarehouse: widget.article.warehouse,
                        proposedWarehouse: _targetWarehouse!.bodeCodi,
                        requestReason: _notes ?? '',
                      );

                      if (!mounted) return;

                      navigator.pop();

                      messenger.showSnackBar(
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
