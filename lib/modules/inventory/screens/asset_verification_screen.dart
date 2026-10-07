import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:geolocator/geolocator.dart';

import 'package:sigo_app/modules/inventory/models/article_model.dart';
import 'package:sigo_app/modules/inventory/models/transfer_person_model.dart';
import 'package:sigo_app/modules/inventory/providers/asset_verification_provider.dart';
import 'package:sigo_app/modules/inventory/providers/inventory_provider.dart';
import 'package:sigo_app/modules/inventory/providers/geolocation_provider.dart';
import 'package:sigo_app/modules/inventory/screens/generator_screen.dart';
import 'package:sigo_app/modules/inventory/widgets/transfer_form_widget.dart';
import 'package:sigo_app/modules/debug/screens/scanner_screen.dart';
import 'package:sigo_app/shared/widgets/company_dropdown_field.dart';
import 'package:sigo_app/shared/widgets/warehouse_dropdown_field.dart';
import 'package:sigo_app/utils/dialog_utils.dart';
import 'package:sigo_app/utils/dropdown_template.dart';

class AssetVerificationScreen extends StatefulWidget {
  const AssetVerificationScreen({super.key});

  @override
  State<AssetVerificationScreen> createState() =>
      _AssetVerificationScreenState();
}

class _AssetVerificationScreenState extends State<AssetVerificationScreen> {
  // Mantenemos estas propiedades por retrocompatibilidad con tests y estado de escaneo reciente
  ArticleModel? verifiedArticle;
  bool? verificationResult;

  final ValueNotifier<TransferPersonModel?> _responsibleNotifier =
      ValueNotifier<TransferPersonModel?>(null);
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

  void _resetLocalVerification() {
    setState(() {
      verifiedArticle = null;
      verificationResult = null;
    });
    _responsibleNotifier.value = null;
  }

  Future<void> _openScanner() async {
    final inventory = context.read<InventoryProvider>();
    final expectedPerson = inventory.selectedCollaborator;
    final expectedName = expectedPerson?.nombreCompleto.trim().isNotEmpty == true
        ? expectedPerson!.nombreCompleto.trim()
        : expectedPerson?.cedula.trim();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: ScannerScreen(expectedResponsible: expectedName),
      ),
    );

    if (result != null && mounted) {
      final article = result['article'] as ArticleModel;
      final verificationProvider = context.read<AssetVerificationProvider>();
      final isVerified = verificationProvider.verifyAsset(
        article,
        inventory.articles,
      );

      setState(() {
        verifiedArticle = article;
        verificationResult = isVerified;
      });

      if (isVerified) {
        DialogUtils.showSuccessSnackBar(
          context,
          'Activo ${article.codigoActivo.isNotEmpty ? article.codigoActivo : article.placa} verificado correctamente',
        );
      } else {
        DialogUtils.showWarningSnackBar(
          context,
          'El activo escaneado no corresponde al responsable esperado.',
        );
      }

      await _checkGeolocation(article);
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

  void _suggestTransfer(ArticleModel article) {
    if (article.enTramite) {
      DialogUtils.showWarningSnackBar(
        context,
        'El activo ya se encuentra en un trámite de traspaso pendiente.',
      );
      return;
    }

    final inventory = context.read<InventoryProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransferFormWidget(
        article: article,
        responsablePropuesto: inventory.selectedCollaborator?.nombreCompleto,
        bodegaPropuesta: article.bodega.isNotEmpty
            ? article.bodega
            : inventory.selectedWarehouse?.codigoBodega,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final verificationProvider = context.watch<AssetVerificationProvider>();

    TransferPersonModel? selectedPerson;
    if (inventory.selectedCollaborator != null) {
      final match = inventory.collaborators.where(
        (p) => p.cedula == inventory.selectedCollaborator!.cedula,
      );
      if (match.isNotEmpty) {
        selectedPerson = match.first;
      }
    }
    if (_responsibleNotifier.value != selectedPerson) {
      _responsibleNotifier.value = selectedPerson;
    }

    // Lista de conflictos consolidada (del provider y del activo reciente si no coincide)
    final conflictList = List<ArticleModel>.from(verificationProvider.conflictAssets);
    if (verifiedArticle != null && verificationResult == false) {
      final already = conflictList.any((c) =>
          (c.codigoActivo.isNotEmpty && c.codigoActivo == verifiedArticle!.codigoActivo) ||
          (c.placa.isNotEmpty && c.placa == verifiedArticle!.placa));
      if (!already) {
        conflictList.insert(0, verifiedArticle!);
      }
    }

    final totalArticles = inventory.articles.length;
    final verifiedCount = inventory.articles
        .where((art) => verificationProvider.isVerified(art))
        .length;
    final pendingCount = totalArticles - verifiedCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Activos'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Selector Empresa
            CompanyDropdownField(
              companies: inventory.companies,
              value: inventory.selectedCompany,
              isLoading: inventory.state == InventoryState.loading &&
                  inventory.companies.isEmpty,
              labelText: 'Empresa',
              allowClear: false,
              onChanged: (c) {
                if (c != null && c != inventory.selectedCompany) {
                  inventory.selectCompany(c, tipo: 'PE');
                  verificationProvider.resetVerification();
                  _resetLocalVerification();
                }
              },
            ),

            const SizedBox(height: 12),

            // 2. Selector Bodega
            WarehouseDropdownField(
              warehouses: inventory.warehouses,
              value: inventory.selectedWarehouse,
              isLoading: inventory.state == InventoryState.loading &&
                  inventory.warehouses.isEmpty,
              labelText: 'Bodega',
              allowClear: false,
              onChanged: (w) {
                if (w != inventory.selectedWarehouse) {
                  inventory.selectWarehouse(w);
                  verificationProvider.resetVerification();
                  _resetLocalVerification();
                }
              },
            ),

            const SizedBox(height: 12),

            // 3. Selector Responsable
            DropdownButtonFormField2<TransferPersonModel>(
              isExpanded: true,
              valueListenable: _responsibleNotifier,
              decoration: InputDecoration(
                labelText: 'Responsable',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                suffixIcon: inventory.isLoadingCollaborators
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (selectedPerson != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _responsibleNotifier.value = null;
                              inventory.selectCollaborator(null);
                              verificationProvider.resetVerification();
                              _resetLocalVerification();
                            },
                            tooltip: 'Limpiar selección',
                          )
                        : null),
              ),
              hint: Text(
                inventory.isLoadingCollaborators
                    ? 'Cargando colaboradores...'
                    : (inventory.collaborators.isEmpty
                        ? (inventory.selectedWarehouse == null
                            ? 'Seleccione primero una bodega'
                            : 'Sin colaboradores disponibles')
                        : 'Seleccione un responsable'),
              ),
              items: inventory.collaborators.map((person) {
                final displayName = person.nombreCompleto.trim().isNotEmpty
                    ? person.nombreCompleto.trim()
                    : person.cedula.trim();
                return DropdownItem<TransferPersonModel>(
                  value: person,
                  child: Text(
                    displayName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: (inventory.isLoadingCollaborators ||
                      inventory.collaborators.isEmpty)
                  ? null
                  : (person) {
                      _responsibleNotifier.value = person;
                      inventory.selectCollaborator(person);
                      verificationProvider.resetVerification();
                      _resetLocalVerification();
                    },
              dropdownSearchData: DropdownTemplates.searchData(
                controller: _responsibleSearchController,
                hintText: 'Buscar responsable...',
                searchMatchFn: (item, searchValue) {
                  final p = item.value;
                  if (p == null) return false;
                  final query = searchValue.toLowerCase();
                  return p.nombreCompleto.toLowerCase().contains(query) ||
                      p.cedula.toLowerCase().contains(query);
                },
              ),
              dropdownStyleData: DropdownTemplates.styleData(),
              onMenuStateChange: (isOpen) {
                if (!isOpen && mounted) _responsibleSearchController.clear();
              },
            ),

            const SizedBox(height: 16),

            // Botones de Escaneo y Generación de QR
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: inventory.selectedCollaborator == null
                        ? null
                        : _openScanner,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Escanear Activo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GeneratorScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Generar QR'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sección de Activos Asignados Esperados
            if (inventory.selectedCollaborator == null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_search_outlined,
                      size: 48,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Seleccione un colaborador responsable para consultar sus activos asignados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (inventory.state == InventoryState.loading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Cargando activos asignados...'),
                    ],
                  ),
                ),
              ),
            ] else if (inventory.articles.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'El colaborador seleccionado no tiene activos asignados en esta bodega.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Activos Asignados ($totalArticles)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$verifiedCount',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.radio_button_unchecked,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$pendingCount',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: inventory.articles.length,
                itemBuilder: (context, index) {
                  final art = inventory.articles[index];
                  final isVerified = verificationProvider.isVerified(art);
                  return _buildExpectedAssetCard(art, isVerified);
                },
              ),
            ],

            // Sección de Activos en Conflicto / Descartados
            if (conflictList.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade800,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Activos en Conflicto / No Esperados (${conflictList.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: conflictList.length,
                itemBuilder: (context, index) {
                  final conflictArt = conflictList[index];
                  return _buildConflictAssetCard(conflictArt);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpectedAssetCard(ArticleModel art, bool isVerified) {
    final stripeColor =
        isVerified ? Colors.green.shade600 : Colors.grey.shade400;
    final bgColor = isVerified ? Colors.green.shade50 : Colors.white;
    final iconColor =
        isVerified ? Colors.green.shade700 : Colors.grey.shade500;
    final icon = isVerified ? Icons.check_circle : Icons.radio_button_unchecked;
    final label = isVerified ? 'Verificado' : 'Pendiente';

    final placaText =
        art.placa.trim().isNotEmpty ? art.placa.trim() : 'SIN PLACA';
    final displayText = "${art.codigoActivo} - $placaText - ${art.nombre}";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isVerified ? Colors.green.shade200 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 14,
              right: 12,
              top: 10,
              bottom: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isVerified ? Colors.green.shade900 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: iconColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (art.enTramite) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
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
                          size: 14,
                          color: Colors.amber.shade900,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'En trámite de traspaso',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: ColoredBox(color: stripeColor),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictAssetCard(ArticleModel conflictArt) {
    final placaText = conflictArt.placa.trim().isNotEmpty
        ? conflictArt.placa.trim()
        : 'SIN PLACA';
    final displayText =
        "${conflictArt.codigoActivo} - $placaText - ${conflictArt.nombre}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.shade300,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 14,
              right: 12,
              top: 12,
              bottom: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade800,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Conflicto',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Responsable actual: ${conflictArt.responsable ?? "No asignado"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.brown.shade800,
                  ),
                ),
                if (conflictArt.enTramite) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Se sugiere realizar un traspaso'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade900,
                      side: BorderSide(color: Colors.orange.shade700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _suggestTransfer(conflictArt),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: ColoredBox(color: Colors.orange.shade700),
          ),
        ],
      ),
    );
  }
}
