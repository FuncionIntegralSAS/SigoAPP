import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:sigo_app/modules/inventory/models/article_model.dart';
import 'package:sigo_app/utils/dropdown_template.dart';

/// Campo de selección estándar para Catálogo de Artículos/Activos en SigoAPP.
///
/// Encapsula la apariencia y comportamiento institucional del sistema:
/// - Esquinas con radio uniforme `BorderRadius.circular(8)`.
/// - Ícono de activo institucional [Icons.vpn_key_outlined].
/// - Buscador interno mediante [DropdownTemplates.searchData] por código, placa y nombre.
/// - Control reactivo de estados asíncronos (cargando, lista vacía, inhabilitado).
/// - Desduplicación automática de ítems para prevenir excepciones de valor en DropdownButton2.
/// - Formato estandarizado de ítem: `código - placa - descripción`.
/// - Opción de deselección/limpieza rápida (`allowClear: true`) para paneles de filtros.
class ArticleDropdownField extends StatefulWidget {
  final ArticleModel? value;
  final List<ArticleModel> articles;
  final ValueChanged<ArticleModel?>? onChanged;
  final bool isLoading;
  final bool allowClear;
  final String labelText;
  final String? hintText;
  final bool isRequired;
  final String? errorText;
  final Widget? prefixIcon;

  const ArticleDropdownField({
    super.key,
    required this.articles,
    required this.onChanged,
    this.value,
    this.isLoading = false,
    this.allowClear = false,
    this.labelText = 'Activo / Artículo',
    this.hintText,
    this.isRequired = false,
    this.errorText,
    this.prefixIcon,
  });

  @override
  State<ArticleDropdownField> createState() => _ArticleDropdownFieldState();
}

class _ArticleDropdownFieldState extends State<ArticleDropdownField> {
  final TextEditingController _searchController = TextEditingController();
  late final ValueNotifier<ArticleModel?> _valueNotifier;

  @override
  void initState() {
    super.initState();
    _valueNotifier = ValueNotifier<ArticleModel?>(widget.value);
  }

  @override
  void didUpdateWidget(covariant ArticleDropdownField oldWidget) {
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

  String _formatItemLabel(ArticleModel article) {
    final code = article.codigoActivo.isNotEmpty
        ? article.codigoActivo
        : (article.id != null ? article.id.toString() : 'N/A');
    final placa = article.placa.trim().isNotEmpty
        ? article.placa.trim()
        : 'N/A';
    final nombre = article.nombre.trim();

    return '$code - $placa - $nombre';
  }

  @override
  Widget build(BuildContext context) {
    final seen = <ArticleModel>{};
    final uniqueArticles = widget.articles.where((a) => seen.add(a)).toList();

    // Sincronizar el notifier si el valor seleccionado ya no existe en la lista
    if (_valueNotifier.value != null && !uniqueArticles.contains(_valueNotifier.value)) {
      _valueNotifier.value = null;
    }

    final effectiveHint = widget.hintText ??
        (widget.isLoading
            ? 'Cargando activos...'
            : uniqueArticles.isEmpty
                ? 'No hay activos disponibles'
                : (widget.allowClear ? 'Todos los activos' : 'Seleccione un activo'));

    final isInteractive = !widget.isLoading && uniqueArticles.isNotEmpty && widget.onChanged != null;

    return DropdownButtonFormField2<ArticleModel>(
      valueListenable: _valueNotifier,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: effectiveHint,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon ?? const Icon(Icons.vpn_key_outlined, size: 20),
        suffixIcon: (widget.allowClear && widget.value != null && isInteractive)
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Limpiar activo',
                onPressed: () {
                  _valueNotifier.value = null;
                  widget.onChanged?.call(null);
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black, width: 1.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: uniqueArticles.map((ArticleModel article) {
        return DropdownItem<ArticleModel>(
          value: article,
          child: Text(
            _formatItemLabel(article),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: isInteractive
          ? (ArticleModel? newValue) {
              _valueNotifier.value = newValue;
              widget.onChanged?.call(newValue);
            }
          : null,
      validator: widget.isRequired
          ? (value) {
              if (value == null) {
                return 'Por favor seleccione un activo';
              }
              return null;
            }
          : null,
      dropdownSearchData: DropdownTemplates.searchData(
        controller: _searchController,
        hintText: 'Buscar activo...',
        searchMatchFn: (item, searchValue) {
          final art = item.value;
          if (art == null) return false;
          final q = searchValue.toLowerCase();
          return art.nombre.toLowerCase().contains(q) ||
              art.placa.toLowerCase().contains(q) ||
              art.codigoActivo.toLowerCase().contains(q) ||
              (art.id != null && art.id.toString().contains(q));
        },
      ),
      dropdownStyleData: DropdownTemplates.styleData(),
      onMenuStateChange: (isOpen) {
        if (!isOpen) {
          _searchController.clear();
        }
      },
    );
  }
}
