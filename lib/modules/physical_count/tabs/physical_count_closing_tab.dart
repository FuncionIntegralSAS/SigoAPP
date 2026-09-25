import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigo_app/modules/physical_count/providers/physical_count_provider.dart';
import 'package:sigo_app/modules/auth/providers/auth_provider.dart';
import 'package:sigo_app/modules/physical_count/models/physical_count_model.dart';
import 'package:sigo_app/shared/models/company_model.dart';
import 'package:sigo_app/utils/dropdown_template.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:sigo_app/utils/dialog_utils.dart';
import 'package:sigo_app/shared/widgets/company_dropdown_field.dart';

class PhysicalCountClosingTab extends StatefulWidget {
  const PhysicalCountClosingTab({super.key});

  @override
  State<PhysicalCountClosingTab> createState() =>
      _PhysicalCountClosingTabState();
}

class _PhysicalCountClosingTabState extends State<PhysicalCountClosingTab> {
  final TextEditingController _warehouseCodeController =
      TextEditingController();
  final TextEditingController _warehouseSearchController = TextEditingController();
  final ValueNotifier<PendingCountWarehouseModel?> _warehouseNotifier =
      ValueNotifier(null);

  PhysicalCountState? _lastHandledCloseState;

  Timer? _debounce;
  CompanyModel? _selectedCompany;
  PendingCountWarehouseModel? _selectedWarehouse;

  @override
  void dispose() {
    _debounce?.cancel();
    _warehouseCodeController.dispose();
    _warehouseSearchController.dispose();
    _warehouseNotifier.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    DialogUtils.showErrorDialog(
      context,
      title: 'Error en Cierre de Conteo',
      message: message,
    );
  }

  Future<void> _showSuccessDialog(PhysicalCountProvider provider) async {
    final message = provider.closeSuccessMessage ??
        'Se ha cerrado exitosamente el conteo físico para la bodega "${_warehouseCodeController.text.trim()}" de la empresa "${_selectedCompany?.descripcion ?? ''}".';
    await DialogUtils.showSuccessDialog(
      context,
      title: 'CONTEO CERRADO',
      message: message,
    );
    if (!mounted) return;
    _warehouseCodeController.clear();
    _warehouseNotifier.value = null;
    setState(() {
      _selectedCompany = null;
      _selectedWarehouse = null;
    });
    provider.resetCloseForm();
  }

  Future<void> _confirmAndClose(PhysicalCountProvider provider) async {
    final empresa = _selectedCompany?.codigo.trim() ?? '';
    final bodega = _selectedWarehouse?.bodega ?? _warehouseCodeController.text.trim();

    if (empresa.isEmpty) {
      _showErrorDialog('Debe ingresar el código de la empresa.');
      return;
    }
    if (bodega.isEmpty) {
      _showErrorDialog('Debe ingresar el código de la bodega.');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final token = authProvider.currentToken;

    if (token == null || token.isEmpty) {
      _showErrorDialog('No hay sesión activa. Inicie sesión nuevamente.');
      return;
    }

    final confirmed = await DialogUtils.showConfirmationDialog(
      context,
      title: 'CONFIRMAR CIERRE',
      message: '¿Estás seguro que quieres cerrar el conteo para la bodega $bodega de la empresa $empresa?',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      provider.closePhysicalCount(token, empresa, bodega);
    }
  }

  void _onCompanySelected(CompanyModel? value, PhysicalCountProvider provider) async {
    setState(() {
      _selectedCompany = value;
      _selectedWarehouse = null;
    });
    _warehouseNotifier.value = null;
    _warehouseCodeController.clear();
    
    if (value != null) {
      await provider.fetchPendingWarehouses(value.codigo);
      if (mounted &&
          provider.pendingWarehousesErrorMessage == null &&
          provider.pendingWarehouses.isEmpty) {
        DialogUtils.showWarningSnackBar(
          context,
          'No se encontraron bodegas pendientes para la empresa ${value.descripcion}.',
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
              _showErrorDialog(provider.closeErrorMessage!);
              provider.clearCloseError();
              _lastHandledCloseState = null;
            });
          } else if (provider.closeState == PhysicalCountState.creada) {
            _lastHandledCloseState = provider.closeState;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await _showSuccessDialog(provider);
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
                  CompanyDropdownField(
                    value: _selectedCompany,
                    companies: provider.companies,
                    isLoading: isLoading,
                    isRequired: true,
                    onChanged: (c) => _onCompanySelected(c, provider),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField2<PendingCountWarehouseModel>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Bodega con Conteo Pendiente',
                      border: OutlineInputBorder(),
                    ),
                    valueListenable: _warehouseNotifier,
                    hint: provider.isLoadingPendingWarehouses
                        ? const Text('Cargando...')
                        : provider.pendingWarehouses.isEmpty
                            ? const Text('No hay bodegas pendientes')
                            : const Text('Seleccione una bodega'),
                    items: provider.pendingWarehouses.map((bodega) {
                      return DropdownItem(
                        value: bodega,
                        child: Text(
                          '${bodega.bodega} - ${bodega.descripcion}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: isLoading ||
                            provider.isLoadingPendingWarehouses ||
                            provider.pendingWarehouses.isEmpty
                        ? null
                        : (val) {
                            setState(() {
                              _selectedWarehouse = val;
                              _warehouseNotifier.value = val;
                              _warehouseCodeController.text = val?.bodega ?? '';
                            });
                          },
                    dropdownSearchData: DropdownTemplates.searchData(
                      controller: _warehouseSearchController,
                      hintText: 'Buscar bodega...',
                      searchMatchFn: (item, searchValue) {
                        return item.value!.descripcion.toLowerCase().contains(
                                  searchValue.toLowerCase(),
                                ) ||
                            item.value!.bodega.toLowerCase().contains(
                                  searchValue.toLowerCase(),
                                );
                      },
                    ),
                    onMenuStateChange: (isOpen) {
                      if (!isOpen) _warehouseSearchController.clear();
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () => _confirmAndClose(provider),
                    child: const Text(
                      'Cerrar Conteo',
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
