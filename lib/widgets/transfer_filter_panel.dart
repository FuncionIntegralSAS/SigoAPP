import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../models/transfer_filter.dart';
import '../models/transfer_request.dart';
import '../utils/dropdown_template.dart';

class TransferFilterPanel extends StatefulWidget {
  final TransferFilter filter;
  final List<String> availableWarehouses;
  final ValueChanged<TransferFilter> onFilterChanged;

  const TransferFilterPanel({
    super.key,
    required this.filter,
    required this.availableWarehouses,
    required this.onFilterChanged,
  });

  @override
  State<TransferFilterPanel> createState() => _TransferFilterPanelState();
}

class _TransferFilterPanelState extends State<TransferFilterPanel> {
  int get _activeSecondaryFiltersCount {
    var count = 0;
    if (widget.filter.bodegaPropuesta != null) count++;
    if (widget.filter.responsibleQuery != null &&
        widget.filter.responsibleQuery!.trim().isNotEmpty) {
      count++;
    }
    if (widget.filter.fromDate != null || widget.filter.toDate != null) {
      count++;
    }
    return count;
  }

  void _clearSecondaryFilters() {
    widget.onFilterChanged(
      TransferFilter(
        status: widget.filter.status,
        bodegaPropuesta: null,
        responsibleQuery: null,
        fromDate: null,
        toDate: null,
      ),
    );
  }

  void _removeWarehouseFilter() {
    widget.onFilterChanged(
      TransferFilter(
        status: widget.filter.status,
        bodegaPropuesta: null,
        responsibleQuery: widget.filter.responsibleQuery,
        fromDate: widget.filter.fromDate,
        toDate: widget.filter.toDate,
      ),
    );
  }

  void _removeResponsibleFilter() {
    widget.onFilterChanged(
      widget.filter.copyWith(responsibleQuery: null),
    );
  }

  void _removeDateRangeFilter() {
    widget.onFilterChanged(
      widget.filter.copyWith(fromDate: null, toDate: null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCount = _activeSecondaryFiltersCount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Botón de filtros secundarios con badge de conteo
                Badge(
                  isLabelVisible: activeCount > 0,
                  label: Text(
                    '$activeCount',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _openSecondaryFiltersBottomSheet(context),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: activeCount > 0
                            ? theme.colorScheme.primary.withValues(alpha: 0.08)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: activeCount > 0
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: activeCount > 0
                            ? theme.colorScheme.primary
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Separador vertical sutil
                Container(
                  height: 22,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(width: 8),
                // Barra desplazable horizontal de estados
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildStatusChip(
                          context,
                          status: TransferStatus.pending,
                          label: 'Pendientes',
                          icon: Icons.hourglass_empty_rounded,
                          color: Colors.amber.shade800,
                        ),
                        const SizedBox(width: 6),
                        _buildStatusChip(
                          context,
                          status: TransferStatus.completed,
                          label: 'Procesados',
                          icon: Icons.done_all_rounded,
                          color: Colors.indigo.shade700,
                        ),
                        const SizedBox(width: 6),
                        _buildStatusChip(
                          context,
                          status: TransferStatus.approved,
                          label: 'Aprobados',
                          icon: Icons.check_circle_outline_rounded,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 6),
                        _buildStatusChip(
                          context,
                          status: TransferStatus.rejected,
                          label: 'Rechazados',
                          icon: Icons.highlight_off_rounded,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 6),
                        _buildStatusChip(
                          context,
                          status: TransferStatus.received,
                          label: 'Recibidos',
                          icon: Icons.mark_email_read_outlined,
                          color: Colors.blue.shade700,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chips rápidos de filtros secundarios activos
          if (activeCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    if (widget.filter.bodegaPropuesta != null) ...[
                      _buildSecondaryActiveChip(
                        icon: Icons.storefront_outlined,
                        label: 'Bodega: ${widget.filter.bodegaPropuesta}',
                        onDeleted: _removeWarehouseFilter,
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (widget.filter.responsibleQuery != null &&
                        widget.filter.responsibleQuery!.trim().isNotEmpty) ...[
                      _buildSecondaryActiveChip(
                        icon: Icons.person_outline,
                        label: 'Resp: ${widget.filter.responsibleQuery}',
                        onDeleted: _removeResponsibleFilter,
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (widget.filter.fromDate != null ||
                        widget.filter.toDate != null) ...[
                      _buildSecondaryActiveChip(
                        icon: Icons.calendar_today_outlined,
                        label: _formatDateRange(
                            widget.filter.fromDate, widget.filter.toDate),
                        onDeleted: _removeDateRangeFilter,
                      ),
                      const SizedBox(width: 6),
                    ],
                    InkWell(
                      onTap: _clearSecondaryFilters,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close,
                                size: 13, color: Colors.red.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Limpiar filtros',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  Widget _buildSecondaryActiveChip({
    required IconData icon,
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(4),
            child: Icon(Icons.close, size: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required TransferStatus status,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = widget.filter.status == status;

    return InkWell(
      onTap: () {
        if (!isSelected) {
          widget.onFilterChanged(widget.filter.copyWith(status: status));
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? color : Colors.grey.shade600,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime? from, DateTime? to) {
    String formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
    if (from != null && to != null) {
      return '${formatDate(from)} - ${formatDate(to)}';
    } else if (from != null) {
      return 'Desde ${formatDate(from)}';
    } else if (to != null) {
      return 'Hasta ${formatDate(to)}';
    }
    return '';
  }

  void _openSecondaryFiltersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return _SecondaryFiltersModal(
          initialFilter: widget.filter,
          availableWarehouses: widget.availableWarehouses,
          onApply: (updatedFilter) {
            Navigator.pop(bottomSheetContext);
            widget.onFilterChanged(updatedFilter);
          },
        );
      },
    );
  }
}

class _SecondaryFiltersModal extends StatefulWidget {
  final TransferFilter initialFilter;
  final List<String> availableWarehouses;
  final ValueChanged<TransferFilter> onApply;

  const _SecondaryFiltersModal({
    required this.initialFilter,
    required this.availableWarehouses,
    required this.onApply,
  });

  @override
  State<_SecondaryFiltersModal> createState() => _SecondaryFiltersModalState();
}

class _SecondaryFiltersModalState extends State<_SecondaryFiltersModal> {
  final TextEditingController _warehouseSearchController =
      TextEditingController();
  late final TextEditingController _responsibleController;
  late final ValueNotifier<String?> _warehouseNotifier;

  String? _selectedWarehouse;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _selectedWarehouse = widget.initialFilter.bodegaPropuesta;
    _warehouseNotifier = ValueNotifier(_selectedWarehouse);
    _responsibleController = TextEditingController(
      text: widget.initialFilter.responsibleQuery ?? '',
    );
    _fromDate = widget.initialFilter.fromDate;
    _toDate = widget.initialFilter.toDate;
  }

  @override
  void dispose() {
    _warehouseSearchController.dispose();
    _responsibleController.dispose();
    _warehouseNotifier.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedWarehouse = null;
      _warehouseNotifier.value = null;
      _responsibleController.clear();
      _fromDate = null;
      _toDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomInset + 20,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera del modal
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Filtros Secundarios',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Restablecer'),
                onPressed: _resetFilters,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Selector de bodega destino
          DropdownButtonFormField2<String?>(
            valueListenable: _warehouseNotifier,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Bodega destino',
              prefixIcon: const Icon(Icons.storefront_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            items: [
              const DropdownItem<String?>(
                value: null,
                child: Text(
                  'Todas las bodegas',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              ...widget.availableWarehouses.map(
                (bodega) => DropdownItem<String?>(
                  value: bodega,
                  child: Text(
                    bodega,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedWarehouse = value;
                _warehouseNotifier.value = value;
              });
            },
            dropdownSearchData: DropdownTemplates.searchData(
              controller: _warehouseSearchController,
              hintText: 'Buscar bodega...',
              searchMatchFn: (item, searchValue) {
                if (item.value == null) {
                  return 'todas las bodegas'.contains(searchValue.toLowerCase());
                }
                return item.value!
                    .toLowerCase()
                    .contains(searchValue.toLowerCase());
              },
            ),
            onMenuStateChange: (isOpen) {
              if (!isOpen) _warehouseSearchController.clear();
            },
          ),
          const SizedBox(height: 14),
          // Búsqueda por responsable propuesto
          TextField(
            controller: _responsibleController,
            decoration: InputDecoration(
              labelText: 'Responsable propuesto',
              hintText: 'Ej. Juan Pérez o cédula',
              prefixIcon: const Icon(Icons.person_outline),
              suffixIcon: _responsibleController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _responsibleController.clear();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          // Rango de fechas
          Row(
            children: [
              Expanded(
                child: _ModalDateField(
                  label: 'Desde',
                  date: _fromDate,
                  onDateSelected: (d) => setState(() => _fromDate = d),
                  onClear: () => setState(() => _fromDate = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModalDateField(
                  label: 'Hasta',
                  date: _toDate,
                  onDateSelected: (d) => setState(() => _toDate = d),
                  onClear: () => setState(() => _toDate = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Botones inferiores de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aplicar Filtros'),
                  onPressed: () {
                    final query = _responsibleController.text.trim();
                    widget.onApply(
                      TransferFilter(
                        status: widget.initialFilter.status,
                        bodegaPropuesta: _selectedWarehouse,
                        responsibleQuery: query.isEmpty ? null : query,
                        fromDate: _fromDate,
                        toDate: _toDate,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModalDateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onDateSelected;
  final VoidCallback onClear;

  const _ModalDateField({
    required this.label,
    required this.date,
    required this.onDateSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final text = date == null
        ? ''
        : '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}';

    return TextFormField(
      key: ValueKey(text),
      readOnly: true,
      initialValue: text,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'dd/mm/aaaa',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        suffixIcon: date != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: onClear,
              )
            : null,
      ),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (selected != null) {
          onDateSelected(selected);
        }
      },
    );
  }
}
