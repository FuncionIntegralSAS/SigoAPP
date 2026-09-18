import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/company_model.dart';
import '../providers/requisition_approval_provider.dart';
import 'company_dropdown_field.dart';

/// Barra superior de filtrado institucional para la bandeja de requisiciones.
///
/// Dispone los selectores en el orden canónico:
/// 1. Selector de Empresa (usando el widget estándar [CompanyDropdownField]).
/// 2. Selector de Fecha inicial ("desde", formato ISO Date YYYY-MM-DD sin componente de hora).
class RequisitionFilterHeader extends StatefulWidget {
  final String status;

  const RequisitionFilterHeader({
    super.key,
    required this.status,
  }) : super();

  @override
  State<RequisitionFilterHeader> createState() => _RequisitionFilterHeaderState();
}

class _RequisitionFilterHeaderState extends State<RequisitionFilterHeader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RequisitionApprovalProvider>();
      if (provider.companies.isEmpty && !provider.isLoadingCompanies) {
        provider.loadCompanies();
      }
    });
  }

  String _formatDisplayDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequisitionApprovalProvider>();
    final selectedCompany = provider.getCompanyModelForStatus(widget.status);
    final selectedDesde = provider.getDesdeForStatus(widget.status);
    final companies = provider.companies;
    final isLoadingCompanies = provider.isLoadingCompanies;

    final dateDisplayText = selectedDesde != null ? _formatDisplayDate(selectedDesde) : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Selector de Empresa (Widget estándar institucional con allowClear)
          CompanyDropdownField(
            value: selectedCompany,
            companies: companies,
            isLoading: isLoadingCompanies,
            allowClear: true,
            onChanged: (CompanyModel? newCompany) {
              provider.selectCompany(newCompany, status: widget.status);
            },
          ),
          const SizedBox(height: 8),

          // 2. Campo de Fecha / Calendario (va segundo, sin horas)
          TextFormField(
            key: ValueKey(dateDisplayText),
            readOnly: true,
            initialValue: dateDisplayText,
            decoration: InputDecoration(
              labelText: 'Fecha desde',
              hintText: 'Todas las fechas (dd/mm/aaaa)',
              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
              suffixIcon: selectedDesde != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Limpiar fecha',
                      onPressed: () => provider.setDesde(null, status: widget.status),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDesde ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                helpText: 'Seleccionar fecha desde',
                confirmText: 'Aplicar',
                cancelText: 'Cancelar',
              );
              if (picked != null) {
                provider.setDesde(picked, status: widget.status);
              }
            },
          ),
        ],
      ),
    );
  }
}

