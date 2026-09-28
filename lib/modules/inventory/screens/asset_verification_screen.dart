import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import 'package:sigo_app/modules/inventory/models/article_model.dart';
import 'package:sigo_app/modules/inventory/widgets/transfer_form_widget.dart';
import 'package:sigo_app/modules/inventory/providers/inventory_provider.dart';
import 'package:sigo_app/modules/inventory/providers/geolocation_provider.dart';
import 'package:sigo_app/utils/dropdown_template.dart';
import 'package:sigo_app/modules/debug/screens/scanner_screen.dart';
import 'package:sigo_app/modules/inventory/screens/generator_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sigo_app/utils/dialog_utils.dart';

class AssetVerificationScreen extends StatefulWidget {
  const AssetVerificationScreen({super.key});

  @override
  State<AssetVerificationScreen> createState() =>
      _AssetVerificationScreenState();
}

class _AssetVerificationScreenState extends State<AssetVerificationScreen> {
  String? selectedResponsible;

  ArticleModel? verifiedArticle;
  bool? verificationResult;

  final ValueNotifier<String?> _responsibleNotifier = ValueNotifier(null);
  final TextEditingController _responsibleSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final inventory = context.read<InventoryProvider>();
      if (inventory.collaborators.isNotEmpty) {
        // Los colaboradores ya están cargados en memoria
        return;
      }
      if (inventory.companies.isEmpty &&
          inventory.state != InventoryState.loading) {
        await inventory.loadCompanies();
      }
      if (!mounted) return;
      if (inventory.selectedCompany == null &&
          inventory.companies.isNotEmpty) {
        inventory.selectCompany(inventory.companies.first, tipo: 'PE');
      }
      if (!mounted) return;
      if (inventory.warehouses.isNotEmpty && inventory.collaborators.isEmpty) {
        final wh = inventory.selectedWarehouse ??
            inventory.warehouses.firstWhere(
              (w) => w.codigoBodega != 'ALL' && w.isPersonal,
              orElse: () => inventory.warehouses.first,
            );
        if (wh.codigoBodega != 'ALL') {
          await inventory.loadCollaborators(
            wh.codigoBodega,
            inventory.selectedCompany?.codigo ?? '01',
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _responsibleNotifier.dispose();
    _responsibleSearchController.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: ScannerScreen(expectedResponsible: selectedResponsible),
      ),
    );

    if (result != null) {
      final article = result['article'] as ArticleModel;
      setState(() {
        verifiedArticle = article;
        verificationResult = result['isValid'] as bool;
      });
      _checkGeolocation(article);
    }
  }

  Future<void> _checkGeolocation(ArticleModel article) async {
    if (article.id == null) return;

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position currentPosition;
    try {
      currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      return;
    }

    if (!mounted) return;
    final geoProvider = context.read<GeolocationProvider>();
    final storedLocation = await geoProvider.getGeolocation(article.id!);

    bool shouldUpdate = false;
    String dialogTitle = '';
    String dialogContent = '';

    if (storedLocation != null) {
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        storedLocation.latitud,
        storedLocation.longitud,
      );

      if (distance > 1) {
        shouldUpdate = true;
        dialogTitle = 'Actualizar Ubicación';
        dialogContent =
            'La ubicación actual del activo difiere de la registrada. ¿Desea actualizarla?';
      }
    } else {
      shouldUpdate = true;
      dialogTitle = 'Registrar Ubicación';
      dialogContent =
          'El activo no tiene ubicación registrada. ¿Desea guardar la ubicación actual?';
    }

    if (shouldUpdate && mounted) {
      final update = await DialogUtils.showConfirmationDialog(
        context,
        title: dialogTitle,
        message: dialogContent,
        confirmText: 'Sí',
        cancelText: 'No',
      );

      if (update == true && mounted) {
        final success = await geoProvider.syncGeolocation(
          article.id!,
          currentPosition.latitude,
          currentPosition.longitude,
        );
        if (mounted) {
          if (success) {
            DialogUtils.showSuccessSnackBar(
              context,
              'Ubicación guardada exitosamente',
            );
          } else {
            DialogUtils.showErrorDialog(
              context,
              title: 'Error de Sincronización',
              message:
                  'No se pudo sincronizar la ubicación: ${geoProvider.errorMessage ?? "Error de conexión"}',
            );
          }
        }
      }
    }
  }

  void _suggestTransfer() {
    if (verifiedArticle == null) return;

    // Validación preventiva: activo ya en trámite pendiente
    if (verifiedArticle!.enTramite) {
      DialogUtils.showWarningSnackBar(
        context,
        'El activo ya se encuentra en un trámite de traspaso pendiente.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransferFormWidget(
        article: verifiedArticle!,
        responsablePropuesto: selectedResponsible,
        bodegaPropuesta: verifiedArticle!.bodega,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final responsibles = inventoryProvider.collaborators
        .map((c) => c.nombreCompleto.trim().isNotEmpty
            ? c.nombreCompleto.trim()
            : c.cedula.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    if (selectedResponsible != null &&
        !responsibles.contains(selectedResponsible)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            selectedResponsible = null;
            _responsibleNotifier.value = null;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Activos'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Responsable esperado (opcional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField2<String>(
              isExpanded: true,
              valueListenable: _responsibleNotifier,
              hint: Text(
                inventoryProvider.isLoadingCollaborators
                    ? 'Cargando colaboradores...'
                    : (responsibles.isEmpty
                        ? 'Sin colaboradores disponibles'
                        : 'Seleccione un responsable'),
              ),
              items: responsibles
                  .map(
                    (r) => DropdownItem<String>(
                      value: r,
                      child: Text(
                        r,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (inventoryProvider.isLoadingCollaborators ||
                      responsibles.isEmpty)
                  ? null
                  : (value) {
                      setState(() {
                        selectedResponsible = value;
                        _responsibleNotifier.value = value;
                      });
                    },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: inventoryProvider.isLoadingCollaborators
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (selectedResponsible != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                selectedResponsible = null;
                                _responsibleNotifier.value = null;
                              });
                            },
                            tooltip: 'Limpiar selección',
                          )
                        : null),
              ),
              dropdownSearchData: DropdownTemplates.searchData(
                controller: _responsibleSearchController,
                hintText: 'Buscar responsable...',
                searchMatchFn: (item, searchValue) {
                  return item.value!.toLowerCase().contains(
                        searchValue.toLowerCase(),
                      );
                },
              ),
              dropdownStyleData: DropdownTemplates.styleData(),
              onMenuStateChange: (isOpen) {
                if (!isOpen && mounted) _responsibleSearchController.clear();
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear Activo'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GeneratorScreen()),
                  );
                },
                icon: const Icon(Icons.qr_code),
                label: const Text('Generar QR'),
              ),
            ),

            const SizedBox(height: 24),

            if (verifiedArticle != null) ...[
              const Divider(),
              const SizedBox(height: 12),

              Text(
                verifiedArticle!.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              Text('Placa: ${verifiedArticle!.placa}'),
              Text(
                'Responsable: ${verifiedArticle!.responsable ?? "No asignado"}',
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Icon(
                    verificationResult == true
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    color: verificationResult == true
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      verificationResult == true
                          ? 'El activo corresponde al responsable seleccionado'
                          : 'El responsable del activo no coincide',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: verificationResult == true
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),

              if (verifiedArticle!.enTramite) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_clock,
                        size: 18,
                        color: Colors.amber.shade900,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Activo en trámite de traspaso pendiente. No se pueden generar nuevas solicitudes.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // =============================
              // SUGERENCIA DE TRASPASO
              // =============================
              if (verificationResult == false) ...[
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Se sugiere realizar un traspaso'),
                    onPressed: _suggestTransfer,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
