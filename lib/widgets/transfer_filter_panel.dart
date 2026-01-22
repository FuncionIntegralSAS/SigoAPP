import 'package:flutter/material.dart';

import '../models/transfer_filter.dart';
import '../models/transfer_request.dart';

class TransferFilterPanel extends StatelessWidget {
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
    return DropdownButtonFormField<TransferStatus>(
      value: filter.status,
      decoration: const InputDecoration(
        labelText: 'Estado del traspaso',
        border: OutlineInputBorder(),
      ),
      items: TransferStatus.values.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(status.name),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onFilterChanged(filter.copyWith(status: value));
        }
      },
    );
  }

  Widget _buildWarehouseFilter() {
    return DropdownButtonFormField<String?>(
      value: filter.proposedWarehouse,
      decoration: const InputDecoration(
        labelText: 'Bodega destino',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Todas'),
        ),
        ...availableWarehouses.map(
          (warehouse) => DropdownMenuItem<String?>(
            value: warehouse,
            child: Text(warehouse),
          ),
        ),
      ],
      onChanged: (value) {
        onFilterChanged(filter.copyWith(proposedWarehouse: value));
      },
    );
  }

  Widget _buildResponsibleFilter() {
    return TextFormField(
      initialValue: filter.responsibleQuery,
      decoration: const InputDecoration(
        labelText: 'Responsable propuesto',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        onFilterChanged(
          filter.copyWith(
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
            date: filter.fromDate,
            onDateSelected: (date) {
              onFilterChanged(filter.copyWith(fromDate: date));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateField(
            label: 'Hasta',
            date: filter.toDate,
            onDateSelected: (date) {
              onFilterChanged(filter.copyWith(toDate: date));
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
      readOnly: true,
      controller: TextEditingController(text: text),
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
