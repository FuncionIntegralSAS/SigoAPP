import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../models/article_model.dart';
import '../models/warehouse_model.dart';
import '../providers/transfer_form_provider.dart';
import '../providers/transfer_request_provider.dart';
import '../utils/dropdown_template.dart';

class TransferFormWidget extends StatefulWidget {
  final ArticleModel article;
  final List<String>? users;
  final List<WarehouseModel>? warehouses;
  final String? bodegaPropuesta;
  final String? responsablePropuesto;

  const TransferFormWidget({
    super.key,
    required this.article,
    this.users,
    this.warehouses,
    this.bodegaPropuesta,
    this.responsablePropuesto,
  });

  @override
  State<TransferFormWidget> createState() => _TransferFormWidgetState();
}

class _TransferFormWidgetState extends State<TransferFormWidget> {
  final TextEditingController _employeeSearchController =
      TextEditingController();
  final TextEditingController _warehouseSearchController =
      TextEditingController();
  final ValueNotifier<WarehouseModel?> _warehouseNotifier = ValueNotifier(null);

  WarehouseModel? _targetWarehouse;
  String? _notes;
  late String _originalResponsible;

  @override
  void initState() {
    super.initState();
    _originalResponsible = widget.article.responsable ?? 'Sin responsable';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formProvider = context.read<TransferFormProvider>();
      formProvider.resetForm();

      if (widget.responsablePropuesto != null &&
          widget.responsablePropuesto!.isNotEmpty) {
        _employeeSearchController.text = widget.responsablePropuesto!;
        formProvider.searchEmployee(widget.responsablePropuesto!);
      }
    });
  }

  @override
  void dispose() {
    _employeeSearchController.dispose();
    _warehouseSearchController.dispose();
    _warehouseNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<TransferRequestProvider>();
    final formProvider = context.watch<TransferFormProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solicitud de Traspaso',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Text('Activo: ${widget.article.nombre}'),
            const SizedBox(height: 6),
            Text('Código: ${widget.article.codigoActivo}'),
            const SizedBox(height: 6),
            Text('Responsable actual: $_originalResponsible'),
            const SizedBox(height: 6),
            Text('Bodega actual: ${widget.article.bodega}'),
            const SizedBox(height: 16),

            // 1. Búsqueda de Responsable Destino por Cédula / Código
            TextFormField(
              controller: _employeeSearchController,
              decoration: InputDecoration(
                labelText: 'Buscar Empleado Destino',
                hintText: 'Ingrese cédula del empleado...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.badge_outlined),
                suffixIcon: formProvider.isSearchingEmployee
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          formProvider.searchEmployee(
                            _employeeSearchController.text,
                          );
                        },
                      ),
              ),
              onFieldSubmitted: (query) {
                formProvider.searchEmployee(query);
              },
            ),

            if (formProvider.employeeName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${formProvider.employeeName!} (División: ${formProvider.divisionId ?? "N/A"})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (formProvider.employeeError != null) ...[
              const SizedBox(height: 6),
              Text(
                formProvider.employeeError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 14),

            // 2. Selector de Bodega Destino (Restringida a la división del empleado)
            DropdownButtonFormField2<WarehouseModel>(
              isExpanded: true,
              valueListenable: _warehouseNotifier,
              hint: formProvider.isLoadingWarehouses
                  ? const Text('Cargando bodegas de la división...')
                  : formProvider.employeeName == null
                      ? const Text('Busque primero el empleado destino')
                      : formProvider.warehouses.isEmpty
                          ? const Text('Sin bodegas asociadas a la división')
                          : const Text('Seleccionar bodega destino'),
              decoration: InputDecoration(
                labelText: 'Bodega Destino (División)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.warehouse_outlined),
                enabled: formProvider.employeeName != null &&
                    formProvider.warehouses.isNotEmpty &&
                    !formProvider.isLoadingWarehouses,
              ),
              items: formProvider.warehouses
                  .map(
                    (w) => DropdownItem<WarehouseModel>(
                      value: w,
                      child: Text(
                        '${w.codigoBodega} - ${w.descripcionBodega}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (formProvider.employeeName == null ||
                      formProvider.warehouses.isEmpty)
                  ? null
                  : (value) {
                      setState(() {
                        _targetWarehouse = value;
                        _warehouseNotifier.value = value;
                      });
                      formProvider.selectWarehouse(value?.codigoBodega);
                    },
              dropdownSearchData: DropdownTemplates.searchData(
                controller: _warehouseSearchController,
                hintText: 'Buscar bodega...',
                searchMatchFn: (item, searchValue) {
                  final wh = item.value!;
                  return wh.descripcionBodega
                          .toLowerCase()
                          .contains(searchValue.toLowerCase()) ||
                      wh.codigoBodega
                          .toLowerCase()
                          .contains(searchValue.toLowerCase());
                },
              ),
              onMenuStateChange: (isOpen) {
                if (!isOpen) _warehouseSearchController.clear();
              },
            ),

            if (formProvider.warehouseError != null) ...[
              const SizedBox(height: 6),
              Text(
                formProvider.warehouseError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 14),

            // 3. Observaciones
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Observaciones / Motivo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
              onChanged: (value) {
                _notes = value;
              },
            ),

            const SizedBox(height: 18),

            // 4. Botón de Creación
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (formProvider.employeeName == null ||
                        _targetWarehouse == null ||
                        requestProvider.loading)
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);

                        await requestProvider.createRequest(
                          idArticulo: widget.article.codigoActivo,
                          nombreArticulo: widget.article.nombre,
                          responsableActual: _originalResponsible,
                          responsablePropuesto: formProvider.employeeName!,
                          bodegaActual: widget.article.bodega,
                          bodegaPropuesta: _targetWarehouse!.codigoBodega,
                          motivoSolicitud: _notes ??
                              'Solicitud de traspaso generada desde SigoAPP',
                        );

                        if (!mounted) return;

                        navigator.pop();

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Solicitud de traspaso enviada exitosamente',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: requestProvider.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Crear Solicitud',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
