import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../models/article_model.dart';
import '../models/warehouse_model.dart';
import '../models/company_model.dart';
import '../models/transfer_person_model.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/transfer_form_widget.dart';
import '../widgets/article_edit_modal.dart';
import '../widgets/inventory_article_tile.dart';
import '../utils/dropdown_template.dart';
import '../utils/permission_utils.dart';
import '../models/auth_model.dart';
import '../utils/auth_utils.dart';

const WarehouseModel _allWarehousesFilter = WarehouseModel(
  codigoBodega: 'ALL',
  descripcionBodega: 'Todas las Bodegas (Inventario Total)',
  estadoBodega: '',
);

const TransferPersonModel _allCollaboratorsFilter = TransferPersonModel(
  cedula: 'ALL',
  nombre: 'Todos los colaboradores',
  apellido: '',
);

class InventoryScreen extends StatefulWidget {
  final bool fromTransferShortcut;

  const InventoryScreen({
    super.key,
    this.fromTransferShortcut = false,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final Color primaryColor = Colors.deepPurple;

  final ValueNotifier<CompanyModel?> _companyNotifier = ValueNotifier(null);
  final ValueNotifier<WarehouseModel?> _warehouseNotifier = ValueNotifier(null);
  final ValueNotifier<TransferPersonModel?> _collaboratorNotifier = ValueNotifier(null);
  final TextEditingController _companySearchController = TextEditingController();
  final TextEditingController _warehouseSearchController = TextEditingController();
  final TextEditingController _collaboratorSearchController = TextEditingController();

  bool _isSelectionMode = false;
  final Map<String, ArticleModel> _selectedArticles = {};

  String _getArticleKey(ArticleModel article) {
    final placaClean = article.placa.trim();
    if (placaClean.isNotEmpty && placaClean.toLowerCase() != 'n/a') {
      return '${article.codigoActivo.trim().toLowerCase()}__${placaClean.toLowerCase()}';
    }
    if (article.id != null) {
      return '${article.codigoActivo.trim().toLowerCase()}__id_${article.id}';
    }
    return '${article.codigoActivo.trim().toLowerCase()}__hash_${identityHashCode(article)}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<InventoryProvider>();
      if (provider.companies.isEmpty || provider.errorMessage != null) {
        provider.loadCompanies();
        return;
      }

      final bool hasCollaboratorSelected = provider.selectedCollaborator != null &&
          provider.selectedCollaborator!.cedula != 'ALL';
      if (hasCollaboratorSelected &&
          provider.selectedCompany != null &&
          provider.selectedWarehouse != null) {
        await provider.refreshArticles();
        if (!mounted) return;
      }
    });
  }

  @override
  void dispose() {
    _companyNotifier.dispose();
    _warehouseNotifier.dispose();
    _collaboratorNotifier.dispose();
    _companySearchController.dispose();
    _warehouseSearchController.dispose();
    _collaboratorSearchController.dispose();
    super.dispose();
  }

  void _syncNotifiers(InventoryProvider provider) {
    if (_companyNotifier.value != provider.selectedCompany) {
      _companyNotifier.value = provider.selectedCompany;
    }
    if (_warehouseNotifier.value != provider.selectedWarehouse) {
      _warehouseNotifier.value = provider.selectedWarehouse;
    }
    if (_collaboratorNotifier.value != provider.selectedCollaborator) {
      _collaboratorNotifier.value = provider.selectedCollaborator;
    }
  }

  void _toggleArticleSelection(ArticleModel article) {
    setState(() {
      final key = _getArticleKey(article);
      final isAlreadySelected = _selectedArticles.containsKey(key);
      if (isAlreadySelected) {
        _selectedArticles.remove(key);
      } else {
        if (_selectedArticles.isNotEmpty) {
          final first = _selectedArticles.values.first;
          final firstResp = first.responsable?.trim().toLowerCase();
          final artResp = article.responsable?.trim().toLowerCase();
          if (firstResp != null &&
              firstResp.isNotEmpty &&
              artResp != null &&
              artResp.isNotEmpty &&
              firstResp != 'n/a' &&
              artResp != 'n/a' &&
              firstResp != artResp) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Todos los activos del traspaso deben pertenecer al mismo responsable (${first.responsable}).',
                ),
                backgroundColor: Colors.orange.shade800,
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }
        }
        _selectedArticles[key] = article;
      }
    });
  }

  void _cancelSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedArticles.clear();
    });
  }

  void _toggleSelectAll(List<ArticleModel> visibleArticles) {
    if (visibleArticles.isEmpty) return;

    setState(() {
      if (_selectedArticles.length == visibleArticles.length) {
        _selectedArticles.clear();
      } else {
        final firstResp = visibleArticles.first.responsable?.trim().toLowerCase() ?? '';
        final hasMultipleResp = visibleArticles.any(
          (a) => (a.responsable?.trim().toLowerCase() ?? '') != firstResp,
        );

        if (hasMultipleResp && firstResp.isNotEmpty && firstResp != 'n/a') {
          final compatible = visibleArticles.where(
            (a) => (a.responsable?.trim().toLowerCase() ?? '') == firstResp,
          ).toList();
          _selectedArticles.clear();
          for (final a in compatible) {
            _selectedArticles[_getArticleKey(a)] = a;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Se marcaron ${compatible.length} activos del responsable (${visibleArticles.first.responsable}).',
              ),
              backgroundColor: Colors.blue.shade800,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          _selectedArticles.clear();
          for (final a in visibleArticles) {
            _selectedArticles[_getArticleKey(a)] = a;
          }
        }
      }
    });
  }

  /// MÉTODO PARA MOSTRAR EL FORMULARIO DE TRASPASO INDIVIDUAL
  Future<void> _showTransferForm(ArticleModel? article, InventoryProvider provider) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => TransferFormWidget(
        article: article,
        initialSelectedArticles: article != null ? [article] : null,
        initialCompany: provider.selectedCompany,
        initialWarehouse: provider.selectedWarehouse,
        initialCollaborator: provider.selectedCollaborator,
      ),
    );

    if (!mounted) return;

    if (success == true) {
      await provider.refreshArticles();
    }
  }

  /// MÉTODO PARA MOSTRAR EL FORMULARIO DE TRASPASO MÚLTIPLE
  Future<void> _startMultipleTransfer(InventoryProvider provider) async {
    final selectedList = _selectedArticles.values.toList();
    if (selectedList.isEmpty) return;

    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => TransferFormWidget(
        initialSelectedArticles: selectedList,
        initialCompany: provider.selectedCompany,
        initialWarehouse: provider.selectedWarehouse,
        initialCollaborator: provider.selectedCollaborator,
      ),
    );

    if (!mounted) return;

    if (success == true) {
      setState(() {
        _isSelectionMode = false;
        _selectedArticles.clear();
      });
      await provider.refreshArticles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final provider = context.watch<InventoryProvider>();
    _syncNotifiers(provider);

    final bool canCreateTransfer =
        authProvider.permisos.hasPermission(AppPermission.generarTraspaso);

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Cancelar selección',
                onPressed: _cancelSelectionMode,
              )
            : null,
        title: Text(
          _isSelectionMode
              ? '${_selectedArticles.length} seleccionado(s)'
              : 'Inventario de Activos',
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: Icon(
                _selectedArticles.length == provider.articles.length &&
                        provider.articles.isNotEmpty
                    ? Icons.deselect
                    : Icons.select_all,
                color: Colors.white,
              ),
              tooltip: _selectedArticles.length == provider.articles.length &&
                      provider.articles.isNotEmpty
                  ? 'Deseleccionar todos'
                  : 'Marcar todos',
              onPressed: () => _toggleSelectAll(provider.articles),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar Sesión',
            onPressed: AuthUtils.isLoggingOut ? null : () => AuthUtils.logout(context),
          ),
        ],
      ),
      floatingActionButton: canCreateTransfer && !_isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: () {
                if (provider.articles.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No hay activos disponibles en la lista para seleccionar.',
                      ),
                    ),
                  );
                  return;
                }
                setState(() => _isSelectionMode = true);
              },
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.checklist_rounded),
              label: const Text(
                'Traspaso Múltiple',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      bottomNavigationBar: _isSelectionMode
          ? SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _cancelSelectionMode,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleSelectAll(provider.articles),
                        icon: Icon(
                          _selectedArticles.length == provider.articles.length &&
                                  provider.articles.isNotEmpty
                              ? Icons.deselect
                              : Icons.select_all,
                          size: 18,
                        ),
                        label: Text(
                          _selectedArticles.length == provider.articles.length &&
                                  provider.articles.isNotEmpty
                              ? 'Deseleccionar'
                              : 'Marcar todos',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _selectedArticles.isEmpty
                          ? null
                          : () => _startMultipleTransfer(provider),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(
                        _selectedArticles.isEmpty
                            ? 'Realizar traspaso'
                            : 'Realizar (${_selectedArticles.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: provider.state == InventoryState.loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (provider.errorMessage != null)
                    _buildErrorBanner(provider, authProvider),
                  _buildCompanySelector(provider),
                  const SizedBox(height: 10),
                  _buildWarehouseSelector(provider),
                  const SizedBox(height: 10),
                  _buildCollaboratorSelector(provider),
                  const SizedBox(height: 10),
                  Text(
                    'Activos en lista: ${provider.articles.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Expanded(
                    child: provider.articles.isEmpty
                        ? const Center(
                            child: Text('No hay activos para esta bodega'),
                          )
                        : ListView.builder(
                            itemCount: provider.articles.length,
                            itemBuilder: (context, index) {
                                final article = provider.articles[index];
                                final isSelected = _selectedArticles.containsKey(
                                  _getArticleKey(article),
                                );
                              return InventoryArticleTile(
                                article: article,
                                isSelected: isSelected,
                                isSelectionMode: _isSelectionMode,
                                canCreateTransfer: canCreateTransfer,
                                primaryColor: primaryColor,
                                onTap: _isSelectionMode
                                    ? () => _toggleArticleSelection(article)
                                    : () => ArticleEditModal.show(
                                          context,
                                          article,
                                          primaryColor: primaryColor,
                                        ),
                                onToggleSelect: (_) => _toggleArticleSelection(article),
                                onTransfer: () => _showTransferForm(article, provider),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorBanner(
    InventoryProvider provider,
    AuthProvider authProvider,
  ) {
    final errorMessage = provider.errorMessage!;
    final bool isAuthExpired = errorMessage.toLowerCase().contains('sesión') ||
        errorMessage.toLowerCase().contains('iniciar sesión');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red.shade900),
            ),
          ),
          if (isAuthExpired)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar Sesión / Reautenticar',
              color: Colors.red.shade900,
              onPressed: AuthUtils.isLoggingOut ? null : () => AuthUtils.logout(context),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reintentar',
            color: Colors.red.shade900,
            onPressed: () => provider.loadCompanies(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanySelector(InventoryProvider provider) {
    return DropdownButtonFormField2<CompanyModel>(
      isExpanded: true,
      valueListenable: _companyNotifier,
      decoration: InputDecoration(
        labelText: 'Filtrar por Empresa',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: provider.companies
          .map(
            (c) => DropdownItem<CompanyModel>(
              value: c,
              child: Text(
                '${c.codigo} - ${c.descripcion}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) {
          provider.selectCompany(v);
        }
      },
      dropdownSearchData: DropdownTemplates.searchData(
        controller: _companySearchController,
        hintText: 'Buscar empresa...',
        searchMatchFn: (item, searchValue) {
          final comp = item.value!;
          return comp.descripcion.toLowerCase().contains(
                searchValue.toLowerCase(),
              ) ||
              comp.codigo.toLowerCase().contains(searchValue.toLowerCase());
        },
      ),
      onMenuStateChange: (isOpen) {
        if (!isOpen) _companySearchController.clear();
      },
    );
  }

  Widget _buildWarehouseSelector(InventoryProvider provider) {
    final List<WarehouseModel> whOptions = [_allWarehousesFilter, ...provider.warehouses];

    return DropdownButtonFormField2<WarehouseModel>(
      isExpanded: true,
      valueListenable: _warehouseNotifier,
      decoration: InputDecoration(
        labelText: 'Filtrar por Bodega',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: whOptions
          .map(
            (w) => DropdownItem<WarehouseModel>(
              value: w,
              child: Text(
                w.codigoBodega == 'ALL'
                    ? w.descripcionBodega
                    : '${w.codigoBodega} - ${w.descripcionBodega}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) {
          provider.selectWarehouse(v);
        }
      },
      dropdownSearchData: DropdownTemplates.searchData(
        controller: _warehouseSearchController,
        hintText: 'Buscar bodega...',
        searchMatchFn: (item, searchValue) {
          final wh = item.value!;
          return wh.descripcionBodega.toLowerCase().contains(
                searchValue.toLowerCase(),
              ) ||
              wh.codigoBodega.toLowerCase().contains(searchValue.toLowerCase());
        },
      ),
      onMenuStateChange: (isOpen) {
        if (!isOpen) _warehouseSearchController.clear();
      },
    );
  }

  Widget _buildCollaboratorSelector(InventoryProvider provider) {
    final bool isWarehouseSelected = provider.selectedWarehouse != null &&
        provider.selectedWarehouse!.codigoBodega != 'ALL';
    final List<TransferPersonModel> collabOptions = [
      _allCollaboratorsFilter,
      ...provider.collaborators,
    ];

    return DropdownButtonFormField2<TransferPersonModel>(
      isExpanded: true,
      valueListenable: _collaboratorNotifier,
      decoration: InputDecoration(
        labelText: 'Filtrar por Colaborador / Responsable',
        hintText: !isWarehouseSelected
            ? 'Seleccione una bodega específica'
            : (provider.isLoadingCollaborators
                ? 'Cargando colaboradores...'
                : 'Todos los colaboradores'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: provider.isLoadingCollaborators
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      items: isWarehouseSelected
          ? collabOptions
              .map(
                (p) => DropdownItem<TransferPersonModel>(
                  value: p,
                  child: Text(
                    p.cedula == 'ALL'
                        ? p.nombre
                        : '${p.nombreCompleto} (${p.cedula})',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              )
              .toList()
          : [],
      onChanged: !isWarehouseSelected
          ? null
          : (v) {
              if (v == null || v.cedula == 'ALL') {
                provider.selectCollaborator(null);
              } else {
                provider.selectCollaborator(v);
              }
            },
      dropdownSearchData: DropdownTemplates.searchData(
        controller: _collaboratorSearchController,
        hintText: 'Buscar colaborador...',
        searchMatchFn: (item, searchValue) {
          final person = item.value!;
          return person.nombreCompleto
                  .toLowerCase()
                  .contains(searchValue.toLowerCase()) ||
              person.cedula.toLowerCase().contains(searchValue.toLowerCase());
        },
      ),
      onMenuStateChange: (isOpen) {
        if (!isOpen) _collaboratorSearchController.clear();
      },
    );
  }
}
