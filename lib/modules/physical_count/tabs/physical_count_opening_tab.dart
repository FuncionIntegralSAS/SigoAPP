import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sigo_app/modules/physical_count/providers/physical_count_provider.dart';
import 'package:sigo_app/modules/inventory/models/article_model.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:sigo_app/utils/dropdown_template.dart';
import 'package:sigo_app/shared/widgets/company_dropdown_field.dart';
import 'package:sigo_app/shared/widgets/warehouse_dropdown_field.dart';
import 'package:sigo_app/utils/dialog_utils.dart';

class PhysicalCountOpeningTab extends StatefulWidget {
  const PhysicalCountOpeningTab({super.key});

  @override
  State<PhysicalCountOpeningTab> createState() =>
      _PhysicalCountOpeningTabState();
}

class _PhysicalCountOpeningTabState extends State<PhysicalCountOpeningTab> {
  final _formKey = GlobalKey<FormState>();
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  PhysicalCountState? _lastHandledState;

  final TextEditingController _articleSearchController =
      TextEditingController();

  late final ValueNotifier<ArticleModel?> _articleNotifier;

  @override
  void initState() {
    super.initState();
    _articleNotifier = ValueNotifier<ArticleModel?>(null);
  }

  @override
  void dispose() {
    _articleSearchController.dispose();
    _articleNotifier.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    DialogUtils.showErrorDialog(
      context,
      title: 'Error en Apertura de Conteo',
      message: message,
    );
  }

  void _showSuccessDialog(PhysicalCountProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Conteo Creado y Asignado'),
        content: const Text(
          'Se ha generado la apertura de conteo físico y se ha asignado el personal exitosamente.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.resetForm();
              _formKey.currentState?.reset();
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(PhysicalCountProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != provider.selectedDate) {
      provider.updateDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PhysicalCountProvider>(
      builder: (context, provider, child) {
        if (provider.state != _lastHandledState) {
          if (provider.state == PhysicalCountState.error &&
              provider.errorMessage != null) {
            _lastHandledState = provider.state;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorDialog(provider.errorMessage!);
              provider.clearError();
              _lastHandledState = null;
            });
          } else if (provider.state == PhysicalCountState.creada) {
            _lastHandledState = provider.state;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSuccessDialog(provider);
              _lastHandledState = null;
            });
          }
        }

        // Sincronizar notifier de artículo con el estado del provider
        if (_articleNotifier.value != provider.selectedArticle) {
          _articleNotifier.value = provider.selectedArticle;
        }

        final isLoading = provider.state == PhysicalCountState.enProceso;

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CompanyDropdownField(
                      value: provider.selectedCompany,
                      companies: provider.companies,
                      isLoading: isLoading,
                      isRequired: true,
                      onChanged: (c) => provider.selectCompany(c),
                    ),
                    const SizedBox(height: 16),
                    WarehouseDropdownField(
                      value: provider.selectedWarehouse,
                      warehouses: provider.warehouses,
                      isLoading: isLoading,
                      isRequired: true,
                      onChanged: (w) => provider.selectWarehouse(w),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: isLoading ? null : () => _selectDate(provider),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_dateFormat.format(provider.selectedDate)),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField2<ArticleModel>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Artículos',
                        border: OutlineInputBorder(),
                      ),
                      valueListenable: _articleNotifier,
                      items: provider.articles.map((art) {
                        return DropdownItem(
                          value: art,
                          child: Text(
                            '${art.codigoActivo} - ${art.nombre}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: isLoading || provider.articles.isEmpty
                          ? null
                          : (val) => provider.selectArticle(val),
                      dropdownSearchData: DropdownTemplates.searchData(
                        controller: _articleSearchController,
                        hintText: 'Buscar artículo...',
                        searchMatchFn: (item, searchValue) {
                          return item.value!.nombre.toLowerCase().contains(
                                searchValue.toLowerCase(),
                              ) ||
                              item.value!.codigoActivo.toLowerCase().contains(
                                searchValue.toLowerCase(),
                              ) ||
                              (item.value!.placa).toLowerCase().contains(
                                searchValue.toLowerCase(),
                              );
                        },
                      ),
                      onMenuStateChange: (isOpen) {
                        if (!isOpen) _articleSearchController.clear();
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Verificar existencia física'),
                      subtitle: const Text(
                        'Solo tener en cuenta artículos físicamente en la bodega',
                      ),
                      value: provider.verifyExistence,
                      onChanged: isLoading ? null : provider.setVerifyExistence,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () => provider.createAndAssignPhysicalCount(),
                      child: const Text(
                        'Generar Apertura y Asignar Personal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }
}
