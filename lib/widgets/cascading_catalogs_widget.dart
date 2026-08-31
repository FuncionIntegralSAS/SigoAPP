import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../providers/transfer_form_provider.dart';
import '../utils/dropdown_template.dart';

class CascadingCatalogsWidget extends StatefulWidget {
  const CascadingCatalogsWidget({super.key});

  @override
  State<CascadingCatalogsWidget> createState() =>
      _CascadingCatalogsWidgetState();
}

class _CascadingCatalogsWidgetState extends State<CascadingCatalogsWidget> {
  final TextEditingController _employeeController = TextEditingController();
  final TextEditingController _warehouseSearchController =
      TextEditingController();
  final ValueNotifier<String?> _warehouseNotifier = ValueNotifier(null);

  @override
  void dispose() {
    _employeeController.dispose();
    _warehouseSearchController.dispose();
    _warehouseNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransferFormProvider>(
      builder: (context, provider, child) {
        if (_warehouseNotifier.value != provider.selectedWarehouseId) {
          _warehouseNotifier.value = provider.selectedWarehouseId;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. CAMPO DE BÚSQUEDA DE EMPLEADO ---
            TextFormField(
              controller: _employeeController,
              decoration: InputDecoration(
                labelText: 'Codigo / Documento del Nuevo Responsable',
                hintText: 'Ej. 123',
                errorText: provider.employeeError,
                suffixIcon: provider.isSearchingEmployee
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          // Disparamos la búsqueda (Paso 1)
                          provider.searchEmployee(_employeeController.text);
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
              onFieldSubmitted: (value) => provider.searchEmployee(value),
            ),

            // Mostrar el nombre si se encontró
            if (provider.employeeName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Empleado: ${provider.employeeName}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            const SizedBox(height: 24),

            DropdownButtonFormField2<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Bodega Destino',
                border: const OutlineInputBorder(),
                errorText: provider.warehouseError,
              ),
              valueListenable: _warehouseNotifier,
              hint: provider.isLoadingWarehouses
                  ? const Text('Cargando bodegas...')
                  : provider.warehouses.isEmpty
                      ? const Text('No hay bodegas disponibles')
                      : const Text('Seleccione una bodega'),
              items: provider.warehouses.map((bodega) {
                return DropdownItem<String>(
                  value: bodega.codigoBodega,
                  child: Text(
                    '${bodega.codigoBodega} - ${bodega.descripcionBodega}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: provider.warehouses.isEmpty ||
                      provider.isLoadingWarehouses
                  ? null
                  : (String? newValue) {
                      _warehouseNotifier.value = newValue;
                      provider.selectWarehouse(newValue);
                    },
              dropdownSearchData: DropdownTemplates.searchData(
                controller: _warehouseSearchController,
                hintText: 'Buscar bodega...',
                searchMatchFn: (item, searchValue) {
                  final bodega = provider.warehouses
                      .where((w) => w.codigoBodega == item.value)
                      .firstOrNull;
                  if (bodega != null) {
                    return bodega.descripcionBodega
                            .toLowerCase()
                            .contains(searchValue.toLowerCase()) ||
                        bodega.codigoBodega
                            .toLowerCase()
                            .contains(searchValue.toLowerCase());
                  }
                  return item.value
                          ?.toLowerCase()
                          .contains(searchValue.toLowerCase()) ??
                      false;
                },
              ),
              onMenuStateChange: (isOpen) {
                if (!isOpen) _warehouseSearchController.clear();
              },
            ),
          ],
        );
      },
    );
  }
}