import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import '../models/company_model.dart';
import '../utils/dropdown_template.dart';

/// Campo de selección estándar para Catálogo de Empresas en SigoAPP.
///
/// Encapsula la apariencia y comportamiento institucional del sistema:
/// - Esquinas con radio uniforme `BorderRadius.circular(8)`.
/// - Ícono de negocio institucional [Icons.business_outlined].
/// - Buscador interno mediante [DropdownTemplates.searchData] por código y descripción.
/// - Control reactivo de estados asíncronos (cargando, lista vacía, inhabilitado).
/// - Opción de deselección/limpieza rápida (`allowClear: true`) para paneles de filtros.
class CompanyDropdownField extends StatefulWidget {
  final CompanyModel? value;
  final List<CompanyModel> companies;
  final ValueChanged<CompanyModel?>? onChanged;
  final bool isLoading;
  final bool allowClear;
  final String labelText;
  final String? hintText;
  final bool isRequired;
  final String? errorText;

  const CompanyDropdownField({
    super.key,
    required this.companies,
    required this.onChanged,
    this.value,
    this.isLoading = false,
    this.allowClear = false,
    this.labelText = 'Empresa',
    this.hintText,
    this.isRequired = false,
    this.errorText,
  });

  @override
  State<CompanyDropdownField> createState() => _CompanyDropdownFieldState();
}

class _CompanyDropdownFieldState extends State<CompanyDropdownField> {
  final TextEditingController _searchController = TextEditingController();
  late final ValueNotifier<CompanyModel?> _valueNotifier;

  @override
  void initState() {
    super.initState();
    _valueNotifier = ValueNotifier<CompanyModel?>(widget.value);
  }

  @override
  void didUpdateWidget(covariant CompanyDropdownField oldWidget) {
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
            ? 'Cargando empresas...'
            : widget.companies.isEmpty
                ? 'No hay empresas disponibles'
                : (widget.allowClear ? 'Todas las empresas' : 'Seleccione una empresa'));

    final isInteractive = !widget.isLoading && widget.companies.isNotEmpty && widget.onChanged != null;

    return DropdownButtonFormField2<CompanyModel>(
      valueListenable: _valueNotifier,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: effectiveHint,
        errorText: widget.errorText,
        prefixIcon: const Icon(Icons.business_outlined, size: 20),
        suffixIcon: (widget.allowClear && widget.value != null && isInteractive)
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Limpiar empresa',
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
      items: widget.companies.map((CompanyModel company) {
        return DropdownItem<CompanyModel>(
          value: company,
          child: Text(
            '${company.codigo} - ${company.descripcion}',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: isInteractive
          ? (CompanyModel? newValue) {
              _valueNotifier.value = newValue;
              widget.onChanged?.call(newValue);
            }
          : null,
      validator: widget.isRequired
          ? (value) {
              if (value == null) {
                return 'Por favor seleccione una empresa';
              }
              return null;
            }
          : null,
      dropdownSearchData: DropdownTemplates.searchData(
        controller: _searchController,
        hintText: 'Buscar empresa...',
        searchMatchFn: (item, searchValue) {
          final comp = item.value;
          if (comp == null) return false;
          final query = searchValue.toLowerCase();
          return comp.descripcion.toLowerCase().contains(query) ||
              comp.codigo.toLowerCase().contains(query);
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
