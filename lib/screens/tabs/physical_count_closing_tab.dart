import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/providers/physical_count_provider.dart';
import 'package:sigo_app/providers/auth_provider.dart';
import 'package:sigo_app/models/physical_count_model.dart';
import 'package:sigo_app/models/company_model.dart';
import 'package:sigo_app/utils/dropdown_template.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:sigo_app/utils/dialog_utils.dart';

class PhysicalCountClosingTab extends StatefulWidget {
  const PhysicalCountClosingTab({super.key});

  @override
  State<PhysicalCountClosingTab> createState() =>
      _PhysicalCountClosingTabState();
}

class _PhysicalCountClosingTabState extends State<PhysicalCountClosingTab> {
  final TextEditingController _warehouseCodeController =
      TextEditingController();
  final TextEditingController _companySearchController = TextEditingController();
  final ValueNotifier<CompanyModel?> _companyNotifier = ValueNotifier(null);
  
  PhysicalCountState? _lastHandledCloseState;
  
  Timer? _debounce;
  PendingCountWarehouseModel? _selectedWarehouse;

  @override
  void dispose() {
    _debounce?.cancel();
    _warehouseCodeController.dispose();
    _companySearchController.dispose();
    _companyNotifier.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessDialog(PhysicalCountProvider provider) {
    final message = provider.closeSuccessMessage ??
        'Se ha cerrado exitosamente el conteo físico para la bodega "${_warehouseCodeController.text.trim()}" de la empresa "${_companySearchController.text.trim()}".';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        title: const Text(
          'CONTEO CERRADO',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _warehouseCodeController.clear();
              _companyNotifier.value = null;
              setState(() {
                _selectedWarehouse = null;
              });
              provider.resetCloseForm();
            },
            child: const Text(
              'Aceptar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndClose(PhysicalCountProvider provider) async {
    final empresa = _companyNotifier.value?.codigo.trim() ?? '';
    final bodega = _warehouseCodeController.text.trim();

    if (empresa.isEmpty) {
      _showErrorSnackBar('Debe ingresar el código de la empresa.');
      return;
    }
    if (bodega.isEmpty) {
      _showErrorSnackBar('Debe ingresar el código de la bodega.');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final token = authProvider.currentToken;

    if (token == null || token.isEmpty) {
      _showErrorSnackBar('No hay sesión activa. Inicie sesión nuevamente.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        title: const Text(
          'CONFIRMAR CIERRE',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          '¿Estás seguro que quieres cerrar el conteo para la bodega $bodega de la empresa $empresa?',
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(
                      color: Colors.deepPurple,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const StadiumBorder(),
                    elevation: 2,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      provider.closePhysicalCount(token, empresa, bodega);
    }
  }

  void _onCompanySelected(CompanyModel? value, PhysicalCountProvider provider) async {
    _companyNotifier.value = value;
    setState(() {
      _selectedWarehouse = null;
    });
    _warehouseCodeController.clear();
    
    if (value != null) {
      await provider.fetchPendingWarehouses(value.codigo);
      if (mounted &&
          provider.pendingWarehousesErrorMessage == null &&
          provider.pendingWarehouses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se encontraron bodegas pendientes para la empresa ${value.descripcion}.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      await provider.fetchPendingWarehouses('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PhysicalCountProvider>(
      builder: (context, provider, child) {
        // Manejo de error al cargar bodegas pendientes
        if (provider.pendingWarehousesErrorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.pendingWarehousesErrorMessage != null && mounted) {
              DialogUtils.showPendingWarehousesErrorDialog(context, provider);
            }
          });
        }

        // Manejo de estados del cierre (independiente de apertura/asignación)
        if (provider.closeState != _lastHandledCloseState) {
          if (provider.closeState == PhysicalCountState.error &&
              provider.closeErrorMessage != null) {
            _lastHandledCloseState = provider.closeState;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorSnackBar(provider.closeErrorMessage!);
              provider.clearCloseError();
              _lastHandledCloseState = null;
            });
          } else if (provider.closeState == PhysicalCountState.creada) {
            _lastHandledCloseState = provider.closeState;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSuccessDialog(provider);
              _lastHandledCloseState = null;
            });
          }
        }

        final isLoading = provider.closeState == PhysicalCountState.enProceso;

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Cierre de Conteo Físico',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ingrese el código de la bodega para cerrar el conteo físico activo asociado.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField2<CompanyModel>(
                    decoration: const InputDecoration(
                      labelText: 'Empresa',
                      border: OutlineInputBorder(),
                    ),
                    valueListenable: _companyNotifier,
                    items: provider.companies.map((company) {
                      return DropdownItem(
                        value: company,
                        child: Text(
                          '${company.codigo} - ${company.descripcion}',
                        ),
                      );
                    }).toList(),
                    onChanged: isLoading
                        ? null
                        : (val) => _onCompanySelected(val, provider),
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
                  DropdownButtonFormField<PendingCountWarehouseModel>(
                    value: _selectedWarehouse,
                    decoration: const InputDecoration(
                      labelText: 'Bodega con Conteo Pendiente',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warehouse),
                    ),
                    isExpanded: true,
                    hint: provider.isLoadingPendingWarehouses
                        ? const Text('Cargando...')
                        : provider.pendingWarehouses.isEmpty
                            ? const Text('No hay bodegas pendientes')
                            : const Text('Seleccione una bodega'),
                    items: provider.pendingWarehouses.map((warehouse) {
                      return DropdownMenuItem<PendingCountWarehouseModel>(
                        value: warehouse,
                        child: Text('${warehouse.bodega} - ${warehouse.descripcion}'),
                      );
                    }).toList(),
                    onChanged: isLoading || provider.isLoadingPendingWarehouses || provider.pendingWarehouses.isEmpty
                        ? null
                        : (val) {
                            setState(() {
                              _selectedWarehouse = val;
                              _warehouseCodeController.text = val?.bodega ?? '';
                            });
                          },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isLoading
                        ? null
                        : () => _confirmAndClose(provider),
                    child: const Text(
                      'Cerrar Conteo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
