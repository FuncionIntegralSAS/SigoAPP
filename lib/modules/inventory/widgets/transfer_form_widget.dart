import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:sigo_app/modules/inventory/models/article_model.dart';
import 'package:sigo_app/shared/models/company_model.dart';
import 'package:sigo_app/shared/models/warehouse_model.dart';
import 'package:sigo_app/modules/inventory/models/transfer_person_model.dart';
import 'package:sigo_app/modules/inventory/models/transfer_asset_model.dart';
import 'package:sigo_app/modules/inventory/providers/inventory_provider.dart';
import 'package:sigo_app/modules/inventory/providers/transfer_form_provider.dart';
import 'package:sigo_app/modules/inventory/providers/transfer_request_provider.dart';
import 'package:sigo_app/utils/dropdown_template.dart';
import 'package:sigo_app/utils/dialog_utils.dart';
import 'package:sigo_app/shared/widgets/company_dropdown_field.dart';
import 'package:sigo_app/shared/widgets/warehouse_dropdown_field.dart';
import 'package:sigo_app/shared/widgets/app_error_widget.dart';

/// Formulario interactivo para la creación de solicitudes de traspaso multi-artículo
/// estructurado en flujo dinámico:
/// Empresa -> Bodega Origen -> Responsable Fuente -> Selección de Activos ->
/// Bodega Destino -> Responsable Destino -> Observaciones -> Envío.
class TransferFormWidget extends StatefulWidget {
  final ArticleModel? article;
  final List<ArticleModel>? initialSelectedArticles;
  final List<String>? users;
  final List<WarehouseModel>? warehouses;
  final String? bodegaPropuesta;
  final String? responsablePropuesto;
  final CompanyModel? initialCompany;
  final WarehouseModel? initialWarehouse;
  final TransferPersonModel? initialCollaborator;

  const TransferFormWidget({
    super.key,
    this.article,
    this.initialSelectedArticles,
    this.users,
    this.warehouses,
    this.bodegaPropuesta,
    this.responsablePropuesto,
    this.initialCompany,
    this.initialWarehouse,
    this.initialCollaborator,
  });

  @override
  State<TransferFormWidget> createState() => _TransferFormWidgetState();
}

class _TransferFormWidgetState extends State<TransferFormWidget> {
  // Controladores de búsqueda para dropdowns
  final TextEditingController _originPersonSearchController =
      TextEditingController();
  final TextEditingController _targetPersonSearchController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // ValueNotifiers para DropdownButton2
  final ValueNotifier<TransferPersonModel?> _originPersonNotifier =
      ValueNotifier(null);
  final ValueNotifier<TransferPersonModel?> _targetPersonNotifier =
      ValueNotifier(null);

  CompanyModel? _selectedCompany;
  WarehouseModel? _selectedOriginWarehouse;
  WarehouseModel? _selectedTargetWarehouse;

  bool _initializedWithArticles = false;
  bool _isSelectedAssetsExpanded = false;

  bool get _isContextualized =>
      (widget.initialSelectedArticles != null &&
          widget.initialSelectedArticles!.isNotEmpty) ||
      widget.article != null;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final formProvider = context.read<TransferFormProvider>();
      final inventoryProvider = context.read<InventoryProvider>();

      formProvider.resetForm();

      // Cargar empresas si aún no están en memoria
      if (inventoryProvider.companies.isEmpty) {
        await inventoryProvider.loadCompanies();
      }

      if (!mounted) return;

      // 1. Selección de empresa inicial
      CompanyModel? companyToSelect =
          widget.initialCompany ??
          inventoryProvider.selectedCompany ??
          (inventoryProvider.companies.isNotEmpty
              ? inventoryProvider.companies.first
              : null);

      if (companyToSelect != null) {
        _selectedCompany = companyToSelect;
        formProvider.setEmpresa(companyToSelect.codigo);
        if (inventoryProvider.selectedCompany?.codigo !=
            companyToSelect.codigo) {
          inventoryProvider.selectCompany(companyToSelect, tipo: 'PE');
        } else {
          await inventoryProvider.loadWarehouses(
            companyToSelect.codigo,
            tipo: 'PE',
          );
        }
      }

      // 2. Si se invocó con artículos pre-seleccionados o un artículo individual
      final articlesToInit =
          widget.initialSelectedArticles ??
          (widget.article != null ? [widget.article!] : null);

      if (articlesToInit != null &&
          articlesToInit.isNotEmpty &&
          !_initializedWithArticles) {
        _initializedWithArticles = true;
        await _initFromArticles(
          articlesToInit,
          inventoryProvider,
          formProvider,
        );
      } else {
        // 3. Pre-seleccionar Bodega Origen si se pasó o estaba seleccionada en InventoryProvider
        WarehouseModel? originWarehouseToSelect =
            widget.initialWarehouse ?? inventoryProvider.selectedWarehouse;
        if (originWarehouseToSelect != null &&
            originWarehouseToSelect.codigoBodega != 'ALL' &&
            originWarehouseToSelect.isPersonal) {
          final matchedOriginWarehouse = (widget.warehouses ??
                  inventoryProvider.warehouses)
              .where(
                (w) =>
                    w.codigoBodega.trim().toLowerCase() ==
                        originWarehouseToSelect.codigoBodega.trim().toLowerCase() &&
                    w.isPersonal,
              )
              .firstOrNull;

          if (matchedOriginWarehouse != null) {
            _selectedOriginWarehouse = matchedOriginWarehouse;
            await formProvider.selectOriginBodega(
              matchedOriginWarehouse.codigoBodega,
              empresa: _selectedCompany?.codigo ?? '01',
              tipo: matchedOriginWarehouse.tipo ?? 'PE',
            );
          }

          if (!mounted) return;

          // 4. Pre-seleccionar Colaborador Fuente si se pasó o estaba seleccionado en InventoryProvider
          TransferPersonModel? collaboratorToSelect =
              widget.initialCollaborator ??
              inventoryProvider.selectedCollaborator;
          if (collaboratorToSelect != null &&
              collaboratorToSelect.cedula != 'ALL') {
            final matchedPerson = formProvider.originPersons
                .where(
                  (p) =>
                      p.cedula.trim().toLowerCase() ==
                          collaboratorToSelect.cedula.trim().toLowerCase() ||
                      p.nombreCompleto.trim().toLowerCase() ==
                          collaboratorToSelect.nombreCompleto
                              .trim()
                              .toLowerCase(),
                )
                .firstOrNull;

            final targetPerson = matchedPerson ?? collaboratorToSelect;
            await formProvider.selectOriginPerson(
              targetPerson,
              empresa: _selectedCompany?.codigo ?? '01',
            );
            _originPersonNotifier.value = targetPerson;
          }
        }
      }
    });
  }

  Future<void> _initFromArticles(
    List<ArticleModel> articles,
    InventoryProvider inventoryProvider,
    TransferFormProvider formProvider,
  ) async {
    if (articles.isEmpty) return;

    // A. Pre-agregar inmediatamente todos los activos en formProvider
    for (final art in articles) {
      final artPlaca = art.placa.trim();
      final hasArtPlaca = artPlaca.isNotEmpty && artPlaca.toLowerCase() != 'n/a';
      final asset = TransferAssetModel(
        articulo: art.codigoActivo,
        placa: hasArtPlaca ? artPlaca : null,
        nombre: art.nombre,
        centroInformacion: null,
        tercero: null,
        enTramite: false,
      );
      formProvider.addPreselectedAsset(asset);
    }

    final availableWarehouses =
        widget.warehouses ?? inventoryProvider.warehouses;
    WarehouseModel? matchedWarehouse;

    // 1. Resolver bodega origen
    if (widget.initialWarehouse != null &&
        widget.initialWarehouse!.codigoBodega != 'ALL') {
      matchedWarehouse = widget.initialWarehouse;
    } else if (inventoryProvider.selectedWarehouse != null &&
        inventoryProvider.selectedWarehouse!.codigoBodega != 'ALL') {
      matchedWarehouse = inventoryProvider.selectedWarehouse;
    } else {
      final firstBodega = articles.first.bodega.trim();
      if (firstBodega.isNotEmpty) {
        try {
          matchedWarehouse = availableWarehouses.firstWhere(
            (w) =>
                w.codigoBodega.trim().toLowerCase() ==
                    firstBodega.toLowerCase() ||
                w.descripcionBodega.trim().toLowerCase() ==
                    firstBodega.toLowerCase(),
          );
        } catch (_) {
          matchedWarehouse = WarehouseModel(
            codigoBodega: firstBodega,
            descripcionBodega: firstBodega,
            estadoBodega: 'A',
          );
        }
      } else if (availableWarehouses.isNotEmpty) {
        matchedWarehouse = availableWarehouses.first;
      }
    }

    if (matchedWarehouse != null) {
      _selectedOriginWarehouse = matchedWarehouse;
      await formProvider.selectOriginBodega(
        matchedWarehouse.codigoBodega,
        empresa: _selectedCompany?.codigo ?? '01',
      );
    }

    if (!mounted) return;

    // 2. Resolver persona fuente
    TransferPersonModel? matchedPerson;
    if (widget.initialCollaborator != null &&
        widget.initialCollaborator!.cedula != 'ALL') {
      matchedPerson = widget.initialCollaborator;
    } else if (inventoryProvider.selectedCollaborator != null &&
        inventoryProvider.selectedCollaborator!.cedula != 'ALL') {
      matchedPerson = inventoryProvider.selectedCollaborator;
    } else if (articles.first.responsable != null &&
        articles.first.responsable!.trim().isNotEmpty &&
        articles.first.responsable!.toUpperCase() != 'N/A') {
      final resp = articles.first.responsable!.trim().toLowerCase();
      final candidatePersons = [
        ...formProvider.originPersons,
        ...inventoryProvider.collaborators,
      ];
      matchedPerson = candidatePersons
          .where(
            (p) =>
                p.cedula.trim().toLowerCase() == resp ||
                p.nombreCompleto.trim().toLowerCase() == resp ||
                resp.contains(p.nombreCompleto.trim().toLowerCase()) ||
                p.nombreCompleto.trim().toLowerCase().contains(resp),
          )
          .firstOrNull;

      matchedPerson ??= TransferPersonModel(
        cedula: articles.first.responsable!,
        nombre: articles.first.responsable!,
        apellido: '',
      );
    } else if (formProvider.originPersons.isNotEmpty) {
      matchedPerson = formProvider.originPersons.first;
    } else if (inventoryProvider.collaborators.isNotEmpty &&
        inventoryProvider.collaborators.first.cedula != 'ALL') {
      matchedPerson = inventoryProvider.collaborators.first;
    }

    if (matchedPerson != null) {
      await formProvider.selectOriginPerson(
        matchedPerson,
        empresa: _selectedCompany?.codigo ?? '01',
      );
      _originPersonNotifier.value = matchedPerson;
    }

    if (!mounted) return;

    // 3. Re-inyectar todos los activos preseleccionados asegurando que ninguno quede por fuera
    for (final art in articles) {
      final artPlaca = art.placa.trim();
      final hasArtPlaca = artPlaca.isNotEmpty && artPlaca.toLowerCase() != 'n/a';

      final matchedAsset = formProvider.personAssets.where((a) {
        if (a.articulo.trim().toLowerCase() != art.codigoActivo.trim().toLowerCase()) {
          return false;
        }
        final aPlaca = a.placa?.trim();
        final hasAPlaca = aPlaca != null && aPlaca.isNotEmpty && aPlaca.toLowerCase() != 'n/a';
        if (hasArtPlaca || hasAPlaca) {
          return hasArtPlaca && hasAPlaca && aPlaca.toLowerCase() == artPlaca.toLowerCase();
        }
        return true;
      }).firstOrNull;

      final assetToAdd =
          matchedAsset ??
          TransferAssetModel(
            articulo: art.codigoActivo,
            placa: hasArtPlaca ? artPlaca : null,
            nombre: art.nombre,
            centroInformacion:
                formProvider.selectedAssets.firstOrNull?.centroInformacion,
            tercero: formProvider.selectedAssets.firstOrNull?.tercero,
            enTramite: false,
          );

      formProvider.addPreselectedAsset(assetToAdd);
    }
  }

  @override
  void dispose() {
    _originPersonSearchController.dispose();
    _targetPersonSearchController.dispose();
    _notesController.dispose();

    _originPersonNotifier.dispose();
    _targetPersonNotifier.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formProvider = context.watch<TransferFormProvider>();
    final inventoryProvider = context.watch<InventoryProvider>();
    final requestProvider = context.watch<TransferRequestProvider>();

    final availableWarehouses =
        widget.warehouses ?? inventoryProvider.warehouses;

    // Sincronizar notifiers con el provider
    if (_originPersonNotifier.value != formProvider.selectedOriginPerson) {
      _originPersonNotifier.value = formProvider.selectedOriginPerson;
    }
    if (_targetPersonNotifier.value != formProvider.selectedDestinationPerson) {
      _targetPersonNotifier.value = formProvider.selectedDestinationPerson;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra superior con indicador de arrastre centrado y botón de cerrar
          Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
                tooltip: 'Cerrar',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Contenido con Scroll
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isContextualized) ...[
                    _buildCompactOriginCard(
                      context,
                      formProvider,
                      inventoryProvider,
                      availableWarehouses,
                    ),
                    _buildCompactAssetsCard(context, formProvider),
                  ] else ...[
                    // =========================================================
                    // SECCIÓN 1: EMPRESA, BODEGA ORIGEN Y RESPONSABLE FUENTE
                    // =========================================================
                    _buildSectionHeader(
                      context,
                      title: '1. Origen y Responsable Fuente',
                      icon: Icons.storefront_outlined,
                    ),
                    const SizedBox(height: 10),
                    _buildOriginSelectors(
                      context,
                      formProvider,
                      inventoryProvider,
                      availableWarehouses,
                    ),
                    const SizedBox(height: 16),

                    // =========================================================
                    // SECCIÓN 2: ACTIVOS ASIGNADOS AL COLABORADOR FUENTE
                    // =========================================================
                    _buildSectionHeader(
                      context,
                      title: '2. Activos a Traspasar',
                      icon: Icons.inventory_2_outlined,
                      badgeText: formProvider.selectedAssets.isNotEmpty
                          ? '${formProvider.selectedAssets.length} seleccionados'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    _buildAssetsSelector(context, formProvider),
                    const SizedBox(height: 16),
                  ],

                  // =========================================================
                  // SECCIÓN 3: BODEGA Y COLABORADOR DESTINO
                  // =========================================================
                  _buildSectionHeader(
                    context,
                    title: '3. Destino del Traspaso',
                    icon: Icons.move_to_inbox_outlined,
                  ),
                  const SizedBox(height: 10),

                  // Selector de Bodega Destino
                  WarehouseDropdownField(
                    value: _selectedTargetWarehouse,
                    warehouses: availableWarehouses,
                    labelText: 'Bodega Destino',
                    hintText: availableWarehouses.isEmpty
                        ? 'Sin bodegas disponibles'
                        : 'Seleccione la bodega destino',
                    isRequired: true,
                    onChanged: availableWarehouses.isEmpty
                        ? null
                        : (WarehouseModel? warehouse) {
                            setState(() {
                              _selectedTargetWarehouse = warehouse;
                            });
                            formProvider.selectDestinationBodega(
                              warehouse?.codigoBodega,
                              empresa: _selectedCompany?.codigo ?? '01',
                            );
                          },
                  ),
                  const SizedBox(height: 12),

                  // Dropdown de Persona Destino
                  DropdownButtonFormField2<TransferPersonModel>(
                    isExpanded: true,
                    valueListenable: _targetPersonNotifier,
                    decoration: InputDecoration(
                      labelText: 'Colaborador Destino (Nuevo Responsable)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person_add_alt_1_outlined),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      suffixIcon: formProvider.isLoadingDestinationPersons
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                    ),
                    hint: formProvider.isLoadingDestinationPersons
                        ? const Text('Cargando colaboradores...')
                        : formProvider.selectedDestinationBodega == null
                        ? const Text('Seleccione primero la bodega destino')
                        : formProvider.destinationPersons.isEmpty
                        ? const Text('Sin colaboradores en esta bodega')
                        : const Text('Seleccione el colaborador destino'),
                    items: formProvider.destinationPersons.map((p) {
                      final isOriginPerson =
                          formProvider.selectedOriginPerson != null &&
                          p.cedula == formProvider.selectedOriginPerson!.cedula;
                      return DropdownItem<TransferPersonModel>(
                        value: p,
                        enabled: !isOriginPerson,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${p.nombreCompleto} (${p.cedula})',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isOriginPerson ? Colors.grey : null,
                                  fontStyle: isOriginPerson
                                      ? FontStyle.italic
                                      : null,
                                ),
                              ),
                            ),
                            if (isOriginPerson)
                              Text(
                                '(Es origen)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red.shade400,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged:
                        (formProvider.isLoadingDestinationPersons ||
                            formProvider.destinationPersons.isEmpty)
                        ? null
                        : (TransferPersonModel? person) {
                            formProvider.selectDestinationPerson(person);
                          },
                    dropdownSearchData: DropdownTemplates.searchData(
                      controller: _targetPersonSearchController,
                      hintText: 'Buscar colaborador destino...',
                      searchMatchFn: (item, searchValue) {
                        final p = item.value!;
                        return p.nombreCompleto.toLowerCase().contains(
                              searchValue.toLowerCase(),
                            ) ||
                            p.cedula.toLowerCase().contains(
                              searchValue.toLowerCase(),
                            );
                      },
                    ),
                  ),

                  if (formProvider.destinationPersonsError != null) ...[
                    const SizedBox(height: 6),
                    AppErrorWidget.inline(
                      message: formProvider.destinationPersonsError!,
                    ),
                  ],

                  if (formProvider.destinationPersonValidationError !=
                      null) ...[
                    const SizedBox(height: 6),
                    AppErrorWidget.inline(
                      message: formProvider.destinationPersonValidationError!,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // =========================================================
                  // SECCIÓN 4: MOTIVO / OBSERVACIONES
                  // =========================================================
                  _buildSectionHeader(
                    context,
                    title: '4. Motivo y Observaciones',
                    icon: Icons.edit_note_outlined,
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones / Motivo de la Solicitud',
                      hintText:
                          'Ej. Traslado de equipos por reubicación de puesto de trabajo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    maxLines: 2,
                    onChanged: (value) => formProvider.setObservacion(value),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // =========================================================
          // BOTÓN PRINCIPAL DE CREACIÓN
          // =========================================================
          SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    (!formProvider.isFormValid || requestProvider.loading)
                    ? null
                    : () => _handleCreateTransfer(
                        formProvider,
                        requestProvider,
                      ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: requestProvider.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  requestProvider.loading
                      ? 'Procesando...'
                      : 'Crear Solicitud (${formProvider.selectedAssets.length} activo${formProvider.selectedAssets.length != 1 ? 's' : ''})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? badgeText,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (badgeText != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAssetsSelector(
    BuildContext context,
    TransferFormProvider formProvider,
  ) {
    if (formProvider.selectedOriginPerson == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Seleccione el colaborador fuente para cargar los activos asignados.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      );
    }

    if (formProvider.isLoadingAssets) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const Column(
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 8),
            Text(
              'Consultando activos fijos asignados...',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (formProvider.assetsError != null) {
      final isNonPeError = formProvider.assetsError!
              .toLowerCase()
              .contains('bodegas personales [pe]') ||
          formProvider.assetsError!.toLowerCase().contains('tipo [fi]');
      return AppErrorWidget.banner(
        title: isNonPeError ? 'BODEGA NO PERMITIDA' : 'ERROR AL CONSULTAR ACTIVOS',
        message: formProvider.assetsError!,
        isWarning: isNonPeError,
        icon: isNonPeError
            ? Icons.warning_amber_rounded
            : Icons.error_outline_rounded,
        onShowDetails: () {
          DialogUtils.showErrorDialog(
            context,
            title: isNonPeError
                ? 'Bodega No Permitida'
                : 'Error al Consultar Activos',
            message: formProvider.assetsError!,
          );
        },
        onRetry: () {
          if (_selectedOriginWarehouse != null &&
              formProvider.selectedOriginPerson != null) {
            formProvider.loadAssetsForPerson(
              formProvider.selectedOriginPerson!.cedula,
              bodega: _selectedOriginWarehouse!.codigoBodega,
              empresa: _selectedCompany?.codigo ?? '01',
            );
          }
        },
      );
    }

    if (formProvider.personAssets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: Colors.amber.shade800,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'El colaborador no tiene activos fijos asignados para traspasar.',
                style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (formProvider.selectionLimitError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppErrorWidget.inline(
              message: formProvider.selectionLimitError!,
            ),
          ),

        // Indicador de regla PL/SQL y límite
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.rule, size: 16, color: Colors.blue.shade800),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Regla: Máximo 50 artículos por solicitud. Todos deben compartir Centro de Información y Tercero.',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                ),
              ),
            ],
          ),
        ),

        // Lista de activos fijos con scroll limitado
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: formProvider.personAssets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final asset = formProvider.personAssets[index];
              final isSelected = formProvider.isAssetSelected(asset);
              final isSelectable = formProvider.isAssetSelectable(asset);
              final ineligibilityReason = formProvider
                  .getAssetIncompatibilityReason(asset);

              final bool isBlocked = !isSelected && !isSelectable;

              return InkWell(
                onTap: (isSelectable || isSelected)
                    ? () {
                        final toggled = formProvider.toggleAssetSelection(asset);
                        if (!toggled && formProvider.selectionLimitError != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(formProvider.selectionLimitError!),
                              backgroundColor: Colors.orange.shade800,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    : () {
                        if (formProvider.selectedAssets.length >= 50 && !asset.enTramite) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Límite alcanzado: Máximo 50 artículos por solicitud de traspaso.'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade50
                        : (isBlocked ? Colors.grey.shade100 : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue.shade400
                          : (isBlocked
                                ? Colors.grey.shade300
                                : Colors.grey.shade400),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (isSelectable || isSelected)
                            ? (_) {
                                final toggled = formProvider.toggleAssetSelection(asset);
                                if (!toggled && formProvider.selectionLimitError != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(formProvider.selectionLimitError!),
                                      backgroundColor: Colors.orange.shade800,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            : null,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              asset.nombre,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isBlocked
                                    ? Colors.grey.shade600
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cód: ${asset.articulo}${asset.placa != null ? " • Placa: ${asset.placa}" : ""}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isBlocked
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (asset.centroInformacion != null)
                                  _buildTagChip(
                                    'CI: ${asset.centroInformacion}',
                                    isBlocked,
                                  ),
                                if (asset.tercero != null)
                                  _buildTagChip(
                                    'Tercero: ${asset.tercero}',
                                    isBlocked,
                                  ),
                                if (asset.enTramite)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.lock_clock,
                                          size: 12,
                                          color: Colors.amber.shade900,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'En trámite pendiente',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (!asset.enTramite &&
                                    !isSelected &&
                                    !isSelectable)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Incompatible (CI / Tercero)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (ineligibilityReason != null &&
                                !asset.enTramite) ...[
                              const SizedBox(height: 4),
                              Text(
                                ineligibilityReason,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(String label, bool isBlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isBlocked ? Colors.grey.shade200 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isBlocked ? Colors.grey.shade700 : Colors.blue.shade800,
        ),
      ),
    );
  }

  // --- ENVÍO DE LA SOLICITUD ---
  Future<void> _handleCreateTransfer(
    TransferFormProvider formProvider,
    TransferRequestProvider requestProvider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final selectedAssets = formProvider.selectedAssets;

    // Validación 1: Máximo 50 artículos y al menos 1
    if (selectedAssets.isEmpty) {
      await DialogUtils.showErrorDialog(
        context,
        title: 'Selección Requerida',
        message: 'Debe seleccionar al menos un artículo para generar el traspaso.',
      );
      return;
    }
    if (selectedAssets.length > 50) {
      await DialogUtils.showErrorDialog(
        context,
        title: 'Límite de Artículos Superado',
        message: 'No se pueden agregar más de 50 artículos por solicitud de traspaso.',
      );
      return;
    }

    // Validación 2: Sin artículos repetidos (clave articulo + placa)
    final seenKeys = <String>{};
    for (final a in selectedAssets) {
      final key = '${a.articulo.trim().toLowerCase()}_${(a.placa ?? '').trim().toLowerCase()}';
      if (!seenKeys.add(key)) {
        await DialogUtils.showErrorDialog(
          context,
          title: 'Artículo Duplicado',
          message: 'El artículo ${a.nombre} (${a.articulo}) con placa ${a.placa ?? "N/A"} está repetido en la solicitud.',
        );
        return;
      }
    }

    // Validación 3: Ningún artículo en trámite pendiente
    final inTransit = selectedAssets.where((a) => a.enTramite).firstOrNull;
    if (inTransit != null) {
      await DialogUtils.showErrorDialog(
        context,
        title: 'Activo En Trámite Pendiente',
        message: 'El artículo "${inTransit.nombre}" (${inTransit.articulo}) se encuentra en trámite pendiente y no puede ser traspasado.',
      );
      return;
    }

    // Validación 4: Compatibilidad estricta (CI y Tercero)
    final firstCi = selectedAssets.first.centroInformacion?.trim();
    final firstTercero = selectedAssets.first.tercero?.trim();
    for (final a in selectedAssets) {
      final ci = a.centroInformacion?.trim();
      final t = a.tercero?.trim();
      if (ci != null && firstCi != null && ci != firstCi) {
        await DialogUtils.showErrorDialog(
          context,
          title: 'Incompatibilidad de Artículos',
          message: 'Todos los artículos seleccionados deben compartir el mismo Centro de Información.',
        );
        return;
      }
      if (t != null && firstTercero != null && t != firstTercero) {
        await DialogUtils.showErrorDialog(
          context,
          title: 'Incompatibilidad de Artículos',
          message: 'Todos los artículos seleccionados deben compartir el mismo Tercero.',
        );
        return;
      }
    }

    // Validación 5: Bodega Origen Personal [PE]
    final originWarehouse = _selectedOriginWarehouse;
    if (originWarehouse != null && !originWarehouse.isPersonal) {
      await DialogUtils.showErrorDialog(
        context,
        title: 'Bodega No Permitida',
        message: 'La bodega ${originWarehouse.codigoBodega} es de tipo [${originWarehouse.tipo ?? "FI"}]: solo se pueden traspasar activos de bodegas personales [PE].',
      );
      return;
    }

    final String empresa =
        _selectedCompany?.codigo ?? formProvider.selectedEmpresa ?? '01';
    final String personaFuente = formProvider.selectedOriginPerson!.cedula;
    final String personaDestino =
        formProvider.selectedDestinationPerson!.cedula;
    final String observacion = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : 'Solicitud de traspaso generada desde SigoAPP';

    final articulosPayload = selectedAssets
        .map((a) => a.toTransferArticleItem())
        .toList();

    // Impresión en consola del objeto a enviar
    final payloadParaConsola = {
      'empresa': empresa,
      'personaFuente': personaFuente,
      'personaDestino': personaDestino,
      'articulos': articulosPayload.map((a) => a.toJson()).toList(),
      'observacion': observacion,
      'tipoMovimiento': null,
    };
    final prettyPayloadJson =
        const JsonEncoder.withIndent('  ').convert(payloadParaConsola);
    debugPrint('\n======================================================');
    debugPrint('[MODAL TRASPASO] OBJETO ENVIADO AL CREAR SOLICITUD:');
    debugPrint(prettyPayloadJson);
    debugPrint('======================================================\n');

    final success = await requestProvider.createRequest(
      codigoActivo: selectedAssets.first.articulo,
      nombreArticulo: selectedAssets.first.nombre,
      responsableActual: formProvider.selectedOriginPerson!.nombreCompleto,
      responsablePropuesto:
          formProvider.selectedDestinationPerson!.nombreCompleto,
      bodegaActual:
          _selectedOriginWarehouse?.codigoBodega ??
          formProvider.selectedOriginBodega ??
          '',
      bodegaPropuesta:
          _selectedTargetWarehouse?.codigoBodega ??
          formProvider.selectedDestinationBodega ??
          '',
      motivoSolicitud: observacion,
      empresa: empresa,
      personaFuente: personaFuente,
      personaDestino: personaDestino,
      placa: selectedAssets.first.placa,
      articulos: articulosPayload,
    );

    if (!mounted) return;

    if (success) {
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Traspaso creado exitosamente con ${articulosPayload.length} artículo(s).',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      await DialogUtils.showInferredErrorDialog(
        context,
        title: 'Error al Crear Solicitud de Traspaso',
        error: requestProvider.errorMessage ??
            'No fue posible registrar la solicitud de traspaso en el ERP.',
        technicalDetails: requestProvider.technicalDetails,
        statusCode: requestProvider.statusCode,
        endpoint: requestProvider.endpoint,
      );
    }
  }

  // --- MÉTODOS AUXILIARES PARA MODO COMPACTO Y CONTEXTUALIZADO ---

  Widget _buildCompactOriginCard(
    BuildContext context,
    TransferFormProvider formProvider,
    InventoryProvider inventoryProvider,
    List<WarehouseModel> availableWarehouses,
  ) {
    final articlesToInit =
        widget.initialSelectedArticles ??
        (widget.article != null ? [widget.article!] : <ArticleModel>[]);
    final fallbackBodega =
        articlesToInit.isNotEmpty && articlesToInit.first.bodega.isNotEmpty
        ? articlesToInit.first.bodega
        : "N/A";
    final fallbackResp =
        articlesToInit.isNotEmpty &&
            articlesToInit.first.responsable != null &&
            articlesToInit.first.responsable!.isNotEmpty
        ? articlesToInit.first.responsable!
        : "N/A";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Origen del Traspaso',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.business, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Empresa: ${_selectedCompany?.descripcion ?? formProvider.selectedEmpresa ?? widget.initialCompany?.descripcion ?? "01"}',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.warehouse, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Bodega: ${_selectedOriginWarehouse?.descripcionBodega ?? formProvider.selectedOriginBodega ?? widget.initialWarehouse?.descripcionBodega ?? fallbackBodega}',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Responsable: ${formProvider.selectedOriginPerson?.nombreCompleto ?? widget.initialCollaborator?.nombreCompleto ?? fallbackResp}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAssetsCard(
    BuildContext context,
    TransferFormProvider formProvider,
  ) {
    final articlesToInit =
        widget.initialSelectedArticles ??
        (widget.article != null ? [widget.article!] : <ArticleModel>[]);

    final displayAssets = formProvider.selectedAssets.isNotEmpty
        ? formProvider.selectedAssets
        : articlesToInit
              .map(
                (a) {
                  final placaClean = a.placa.trim();
                  return TransferAssetModel(
                    articulo: a.codigoActivo,
                    placa: (placaClean.isNotEmpty && placaClean.toLowerCase() != 'n/a')
                        ? placaClean
                        : null,
                    nombre: a.nombre,
                    centroInformacion: null,
                    tercero: null,
                    enTramite: false,
                  );
                },
              )
              .toList();

    final count = displayAssets.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Activos a traspasar ($count)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => setState(() {
              _isSelectedAssetsExpanded = !_isSelectedAssetsExpanded;
            }),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayAssets.isEmpty
                          ? 'Ningún activo seleccionado'
                          : displayAssets
                                    .map(
                                      (a) =>
                                          a.placa != null && a.placa!.isNotEmpty
                                          ? a.placa!
                                          : a.nombre,
                                    )
                                    .take(3)
                                    .join(', ') +
                                (count > 3 ? ' y ${count - 3} más...' : ''),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isSelectedAssetsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 18,
                    color: Colors.blueGrey.shade700,
                  ),
                ],
              ),
            ),
          ),
          if (_isSelectedAssetsExpanded && displayAssets.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 140),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: displayAssets.length,
                  separatorBuilder: (_, _) => const Divider(height: 8),
                  itemBuilder: (context, index) {
                    final asset = displayAssets[index];
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            asset.placa ?? asset.articulo,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            asset.nombre,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOriginSelectors(
    BuildContext context,
    TransferFormProvider formProvider,
    InventoryProvider inventoryProvider,
    List<WarehouseModel> availableWarehouses,
  ) {
    final originWarehouses =
        availableWarehouses.where((w) => w.isPersonal).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompanyDropdownField(
          value: _selectedCompany,
          companies: inventoryProvider.companies,
          labelText: 'Empresa',
          isRequired: true,
          onChanged: (CompanyModel? company) {
            if (company == null) return;
            setState(() {
              _selectedCompany = company;
              _selectedOriginWarehouse = null;
              _selectedTargetWarehouse = null;
            });
            formProvider.setEmpresa(company.codigo);
            inventoryProvider.selectCompany(company, tipo: 'PE');
          },
        ),
        const SizedBox(height: 12),

        WarehouseDropdownField(
          value: _selectedOriginWarehouse,
          warehouses: originWarehouses,
          labelText: 'Bodega Origen (Solo Personal PE)',
          hintText: originWarehouses.isEmpty
              ? 'Sin bodegas personales disponibles'
              : 'Seleccione la bodega origen',
          isRequired: true,
          onChanged: originWarehouses.isEmpty
              ? null
              : (WarehouseModel? warehouse) {
                  setState(() {
                    _selectedOriginWarehouse = warehouse;
                  });
                  formProvider.selectOriginBodega(
                    warehouse?.codigoBodega,
                    empresa: _selectedCompany?.codigo ?? '01',
                    tipo: warehouse?.tipo ?? 'PE',
                  );
                },
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField2<TransferPersonModel>(
          isExpanded: true,
          valueListenable: _originPersonNotifier,
          decoration: InputDecoration(
            labelText: 'Colaborador Fuente (Responsable Actual)',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.person_pin_circle_outlined),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            suffixIcon: formProvider.isLoadingOriginPersons
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          hint: formProvider.isLoadingOriginPersons
              ? const Text('Cargando colaboradores...')
              : formProvider.selectedOriginBodega == null
              ? const Text('Seleccione primero la bodega origen')
              : formProvider.originPersons.isEmpty
              ? const Text('Sin colaboradores en esta bodega')
              : const Text('Seleccione el colaborador fuente'),
          items: formProvider.originPersons.map((p) {
            return DropdownItem<TransferPersonModel>(
              value: p,
              child: Text(
                '${p.nombreCompleto} (${p.cedula})',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged:
              (formProvider.isLoadingOriginPersons ||
                  formProvider.originPersons.isEmpty)
              ? null
              : (TransferPersonModel? person) {
                  formProvider.selectOriginPerson(
                    person,
                    empresa: _selectedCompany?.codigo ?? '01',
                  );
                },
          dropdownSearchData: DropdownTemplates.searchData(
            controller: _originPersonSearchController,
            hintText: 'Buscar colaborador...',
            searchMatchFn: (item, searchValue) {
              final p = item.value!;
              return p.nombreCompleto.toLowerCase().contains(
                    searchValue.toLowerCase(),
                  ) ||
                  p.cedula.toLowerCase().contains(searchValue.toLowerCase());
            },
          ),
        ),

        if (formProvider.originPersonsError != null) ...[
          const SizedBox(height: 6),
          AppErrorWidget.inline(
            message: formProvider.originPersonsError!,
          ),
        ],
      ],
    );
  }
}
