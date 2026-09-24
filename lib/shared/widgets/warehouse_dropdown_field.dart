import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:sigo_app/shared/models/warehouse_model.dart';
import 'package:sigo_app/utils/dropdown_template.dart';

/// Campo de selección estándar para Catálogo de Bodegas en SigoAPP.
///
/// Encapsula la apariencia y comportamiento institucional del sistema:
/// - Esquinas con radio uniforme `BorderRadius.circular(8)`.
/// - Ícono de bodega institucional [Icons.storefront_outlined].
/// - Buscador interno mediante [DropdownTemplates.searchData] por código y descripción.
/// - Control reactivo de estados asíncronos (cargando, lista vacía, inhabilitado).
/// - Opción de deselección/limpieza rápida (`allowClear: true`) para paneles de filtros.
class WarehouseDropdownField extends StatefulWidget {
  final WarehouseModel? value;
  final List<WarehouseModel> warehouses;
  final ValueChanged<WarehouseModel?>? onChanged;
  final bool isLoading;
  final bool allowClear;
  final String labelText;
  final String? hintText;
  final bool isRequired;
  final String? errorText;

  const WarehouseDropdownField({
    super.key,
    required this.warehouses,
    required this.onChanged,
    this.value,
    this.isLoading = false,
    this.allowClear = false,
    this.labelText = 'Bodega',
    this.hintText,
    this.isRequired = false,
    this.errorText,
  });

  @override
  State<WarehouseDropdownField> createState() => _WarehouseDropdownFieldState();
}

class _WarehouseDropdownFieldState extends State<WarehouseDropdownField> {
  final TextEditingController _searchController = TextEditingController();
  late final ValueNotifier<WarehouseModel?> _valueNotifier;

  @override
  void initState() {
    super.initState();
    _valueNotifier = ValueNotifier<WarehouseModel?>(widget.value);
  }

  @override
  void didUpdateWidget(covariant WarehouseDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _valueNotifier.value = widget.value;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _valueNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHint = widget.hintText ??
        (widget.isLoading
            ? 'Cargando bodegas...'
            : widget.warehouses.isEmpty
                ? 'No hay bodegas disponibles'
                : (widget.allowClear ? 'Todas las bodegas' : 'Seleccione una bodega'));

    final isInteractive = !widget.isLoading && widget.warehouses.isNotEmpty && widget.onChanged != null;

    return DropdownButtonFormField2<WarehouseModel>(
      valueListenable: _valueNotifier,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: effectiveHint,
        errorText: widget.errorText,
        prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
        suffixIcon: (widget.allowClear && widget.value != null && isInteractive)
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Limpiar bodega',
                onPressed: () {
                  _valueNotifier.value = null;
                  widget.onChanged?.call(null);
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: widget.warehouses.map((WarehouseModel warehouse) {
        return DropdownItem<WarehouseModel>(
          value: warehouse,
          child: Text(
            '${warehouse.codigoBodega} - ${warehouse.descripcionBodega}',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: isInteractive
          ? (WarehouseModel? newValue) {
              _valueNotifier.value = newValue;
              widget.onChanged?.call(newValue);
            }
          : null,
      validator: widget.isRequired
          ? (value) {
              if (value == null) {
                return 'Por favor seleccione una bodega';
              }
              return null;
            }
          : null,
      dropdownSearchData: DropdownTemplates.searchData(
        controller: _searchController,
        hintText: 'Buscar bodega...',
        searchMatchFn: (item, searchValue) {
          final wh = item.value;
          if (wh == null) return false;
          final query = searchValue.toLowerCase();
          return wh.descripcionBodega.toLowerCase().contains(query) ||
              wh.codigoBodega.toLowerCase().contains(query);
        },
      ),
      onMenuStateChange: (isOpen) {
        if (!isOpen) {
          _searchController.clear();
        }
      },
    );
  }
}
