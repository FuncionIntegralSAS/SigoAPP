import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sigo_app/providers/physical_count_provider.dart';
import 'package:sigo_app/models/company_model.dart';
import 'package:sigo_app/models/warehouse_model.dart';
import 'package:sigo_app/models/article_model.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:sigo_app/utils/dropdown_template.dart';

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

  final TextEditingController _companySearchController =
      TextEditingController();
  final TextEditingController _warehouseSearchController =
      TextEditingController();
  final TextEditingController _articleSearchController =
      TextEditingController();

  late final ValueNotifier<CompanyModel?> _companyNotifier;
  late final ValueNotifier<WarehouseModel?> _warehouseNotifier;
  late final ValueNotifier<ArticleModel?> _articleNotifier;

  @override
  void initState() {
    super.initState();
    _companyNotifier = ValueNotifier<CompanyModel?>(null);
    _warehouseNotifier = ValueNotifier<WarehouseModel?>(null);
    _articleNotifier = ValueNotifier<ArticleModel?>(null);
  }

  @override
  void dispose() {
    _companySearchController.dispose();
    _warehouseSearchController.dispose();
    _articleSearchController.dispose();
    _companyNotifier.dispose();
    _warehouseNotifier.dispose();
    _articleNotifier.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessDialog(PhysicalCountProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Conteo Creado'),
        content: const Text(
          'Se ha generado la apertura de conteo físico exitosamente para la bodega seleccionada.',
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
              _showErrorSnackBar(provider.errorMessage!);
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

        // Sincronizar notifiers con el estado del provider
        if (_companyNotifier.value != provider.selectedCompany) {
          _companyNotifier.value = provider.selectedCompany;
        }
        if (_warehouseNotifier.value != provider.selectedWarehouse) {
          _warehouseNotifier.value = provider.selectedWarehouse;
        }
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
                    DropdownButtonFormField2<CompanyModel>(
                      decoration: const InputDecoration(
                        labelText: 'Empresa',
                        border: OutlineInputBorder(),
                      ),
                      valueListenable: _companyNotifier,
                      items: provider.companies.map((company) {
                        return DropdownItem(
                          value: company,
                          child: Text(company.descripcion),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (val) => provider.selectCompany(val),
                      dropdownSearchData: DropdownTemplates.searchData(
                        controller: _companySearchController,
                        hintText: 'Buscar empresa...',
                        searchMatchFn: (item, searchValue) {
                          return item.value!.descripcion.toLowerCase().contains(
                            searchValue.toLowerCase(),
                          );
                        },
                      ),
                      onMenuStateChange: (isOpen) {
                        if (!isOpen) _companySearchController.clear();
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField2<WarehouseModel>(
                      decoration: const InputDecoration(
                        labelText: 'Bodega',
                        border: OutlineInputBorder(),
                      ),
                      valueListenable: _warehouseNotifier,
                      items: provider.warehouses.map((wh) {
                        return DropdownItem(
                          value: wh,
                          child: Text(wh.bodeDesc),
                        );
                      }).toList(),
                      onChanged: isLoading || provider.warehouses.isEmpty
                          ? null
                          : (val) => provider.selectWarehouse(val),
                      dropdownSearchData: DropdownTemplates.searchData(
                        controller: _warehouseSearchController,
                        hintText: 'Buscar bodega...',
                        searchMatchFn: (item, searchValue) {
                          return item.value!.bodeDesc.toLowerCase().contains(
                                searchValue.toLowerCase(),
                              ) ||
                              item.value!.bodeCodi.toLowerCase().contains(
                                searchValue.toLowerCase(),
                              );
                        },
                      ),
                      onMenuStateChange: (isOpen) {
                        if (!isOpen) _warehouseSearchController.clear();
                      },
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
                      decoration: const InputDecoration(
                        labelText: 'Artículos',
                        border: OutlineInputBorder(),
                      ),
                      valueListenable: _articleNotifier,
                      items: provider.articles.map((art) {
                        return DropdownItem(value: art, child: Text(art.name));
                      }).toList(),
                      onChanged: isLoading || provider.articles.isEmpty
                          ? null
                          : (val) => provider.selectArticle(val),
                      dropdownSearchData: DropdownTemplates.searchData(
                        controller: _articleSearchController,
                        hintText: 'Buscar artículo...',
                        searchMatchFn: (item, searchValue) {
                          return item.value!.name.toLowerCase().contains(
                                searchValue.toLowerCase(),
                              ) ||
                              item.value!.id.toLowerCase().contains(
                                searchValue.toLowerCase(),
                              ) ||
                              (item.value!.licensePlate).toLowerCase().contains(
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isLoading
                          ? null
                          : () => provider.submitPhysicalCount(),
                      child: const Text(
                        'Generar Apertura de Conteo',
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
