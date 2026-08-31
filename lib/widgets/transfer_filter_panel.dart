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
  final TextEditingController _warehouseSearchController =
      TextEditingController();
  late final ValueNotifier<TransferStatus?> _statusNotifier;
  late final ValueNotifier<String?> _warehouseNotifier;

  @override
  void initState() {
    super.initState();
    _statusNotifier = ValueNotifier(widget.filter.status);
    _warehouseNotifier = ValueNotifier(widget.filter.bodegaPropuesta);
  }

  @override
  void didUpdateWidget(covariant TransferFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.status != _statusNotifier.value) {
      _statusNotifier.value = widget.filter.status;
    }
    if (widget.filter.bodegaPropuesta != _warehouseNotifier.value) {
      _warehouseNotifier.value = widget.filter.bodegaPropuesta;
    }
  }

  @override
  void dispose() {
    _warehouseSearchController.dispose();
    _statusNotifier.dispose();
    _warehouseNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildStatusFilter(),
            const SizedBox(height: 12),
            _buildWarehouseFilter(),
            const SizedBox(height: 12),
            _buildResponsibleFilter(),
            const SizedBox(height: 12),
            _buildDateRangeFilter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField2<TransferStatus>(
      isExpanded: true,
      valueListenable: _statusNotifier,
      decoration: const InputDecoration(
        labelText: 'Estado del traspaso',
        border: OutlineInputBorder(),
      ),
      items: TransferStatus.values.map((status) {
        return DropdownItem<TransferStatus>(
          value: status,
          child: Text(
            status.name,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          _statusNotifier.value = value;
          widget.onFilterChanged(widget.filter.copyWith(status: value));
        }
      },
    );
  }

  Widget _buildWarehouseFilter() {
    return DropdownButtonFormField2<String?>(
      isExpanded: true,
      valueListenable: _warehouseNotifier,
      decoration: const InputDecoration(
        labelText: 'Bodega destino',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownItem<String?>(
          value: null,
          child: Text(
            'Todas',
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
        _warehouseNotifier.value = value;
        widget.onFilterChanged(
          widget.filter.copyWith(
            bodegaPropuesta: value,
          ),
        );
      },
      dropdownSearchData: DropdownTemplates.searchData(
        controller: _warehouseSearchController,
        hintText: 'Buscar bodega...',
        searchMatchFn: (item, searchValue) {
          if (item.value == null) {
            return 'todas'.contains(searchValue.toLowerCase());
          }
          return item.value!
              .toLowerCase()
              .contains(searchValue.toLowerCase());
        },
      ),
      onMenuStateChange: (isOpen) {
        if (!isOpen) _warehouseSearchController.clear();
      },
    );
  }

  Widget _buildResponsibleFilter() {
    return TextFormField(
      initialValue: widget.filter.responsibleQuery,
      decoration: const InputDecoration(
        labelText: 'Responsable propuesto',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        widget.onFilterChanged(
          widget.filter.copyWith(
            responsibleQuery: value.isEmpty ? null : value,
          ),
        );
      },
    );
  }

  Widget _buildDateRangeFilter(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateField(
            label: 'Desde',
            date: widget.filter.fromDate,
            onDateSelected: (date) {
              widget.onFilterChanged(widget.filter.copyWith(fromDate: date));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateField(
            label: 'Hasta',
            date: widget.filter.toDate,
            onDateSelected: (date) {
              widget.onFilterChanged(widget.filter.copyWith(toDate: date));
            },
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onDateSelected;

  const _DateField({
    required this.label,
    required this.date,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final text = date == null
        ? ''
        : '${date!.day}/${date!.month}/${date!.year}';

    return TextFormField(
      key: ValueKey(text),
      readOnly: true,
      initialValue: text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        onDateSelected(selected);
      },
    );
  }
}
