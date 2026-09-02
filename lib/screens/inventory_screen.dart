import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../models/article_model.dart';
import '../models/warehouse_model.dart';
import '../models/company_model.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/transfer_form_widget.dart'; // Importamos el widget del formulario
import '../utils/dropdown_template.dart';
import '../providers/geolocation_provider.dart';

const WarehouseModel _allWarehousesFilter = WarehouseModel(
  codigoBodega: 'ALL',
  descripcionBodega: 'Todas las Bodegas (Inventario Total)',
  estadoBodega: '',
);

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final Color primaryColor = Colors.deepPurple;

  final List<String> _statusOptions = [
    'Operativo',
    'En Mantenimiento',
    'Dañado',
    'Baja',
  ];

  final ValueNotifier<CompanyModel?> _companyNotifier = ValueNotifier(null);
  final ValueNotifier<WarehouseModel?> _warehouseNotifier = ValueNotifier(null);
  final TextEditingController _companySearchController = TextEditingController();
  final TextEditingController _warehouseSearchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<InventoryProvider>();
      if (provider.companies.isEmpty || provider.errorMessage != null) {
        provider.loadCompanies();
      }
    });
  }

  @override
  void dispose() {
    _companyNotifier.dispose();
    _warehouseNotifier.dispose();
    _companySearchController.dispose();
    _warehouseSearchController.dispose();
    super.dispose();
  }

  void _syncNotifiers(InventoryProvider provider) {
    if (_companyNotifier.value != provider.selectedCompany) {
      _companyNotifier.value = provider.selectedCompany;
    }
    if (_warehouseNotifier.value != provider.selectedWarehouse) {
      _warehouseNotifier.value = provider.selectedWarehouse;
    }
  }

  /// MÉTODO PARA MOSTRAR EL FORMULARIO DE TRASPASO
  void _showTransferForm(ArticleModel article, InventoryProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => TransferFormWidget(
        article: article,
      ),
    );
  }

  void _showEditArticleForm(ArticleModel article) async {
    final commentsController = TextEditingController(
      text: article.comentarios ?? '',
    );

    String? selectedStatus = article.estado ?? 'Operativo';
    String? rutaFoto = article.rutaFoto;

    final editStatusNotifier = ValueNotifier<String?>(selectedStatus);

    double? currentLat = article.latitud;
    double? currentLon = article.longitud;
    bool isLocating = false;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> captureLocation() async {
            if (currentLat != null && currentLon != null) {
              final update = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Actualizar Ubicación'),
                  content: const Text('El activo ya cuenta con una ubicación registrada. ¿Desea reemplazarla por su ubicación actual?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sí'),
                    ),
                  ],
                ),
              );
              if (update != true) return;
            }

            setModalState(() => isLocating = true);
            try {
              LocationPermission permission =
                  await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
              }
              final position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                ),
              );

              if (!context.mounted) return;

              setModalState(() {
                currentLat = position.latitude;
                currentLon = position.longitude;
                isLocating = false;
              });
            } catch (e) {
              if (!context.mounted) return;
              setModalState(() => isLocating = false);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error GPS: $e')));
            }
          }

          Future<void> takePhoto() async {
            setModalState(() {
              rutaFoto =
                  'path/to/local/storage/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Foto capturada (Simulación: Cámara)'),
                ),
              );
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Actualizar Estado de Activo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Información del Activo (Sólo Lectura)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Placa: ${article.placa}'),
                        Text('Bodega: ${article.bodega}'),
                        Text(
                          'Responsable: ${article.responsable ?? 'Sin responsable'}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selector de Estado
                  DropdownButtonFormField2<String>(
                    isExpanded: true,
                    valueListenable: editStatusNotifier,
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      prefixIcon: const Icon(Icons.info_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: _statusOptions
                        .map(
                          (s) => DropdownItem<String>(
                            value: s,
                            child: Text(
                              s,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      selectedStatus = v;
                      editStatusNotifier.value = v;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Comentarios del Evento / Estado
                  TextField(
                    controller: commentsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Comentarios del estado',
                      prefixIcon: Icon(Icons.comment),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Captura de Foto
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            rutaFoto == null ? 'TOMAR FOTO' : 'CAMBIAR FOTO',
                          ),
                        ),
                      ),
                      if (rutaFoto != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Geolocalización
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Geolocalización',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            isLocating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : IconButton(
                                    onPressed: captureLocation,
                                    icon: Icon(
                                      Icons.my_location,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                  ),
                          ],
                        ),
                        if (currentLat != null)
                          Text(
                            'Lat: $currentLat, Lon: $currentLon',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blueGrey,
                            ),
                          ),
                        if (currentLat == null)
                          const Text(
                            'Sin coordenadas registradas',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón Guardar
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            try {
                              if (currentLat != null &&
                                  currentLon != null &&
                                  article.id != null) {
                                final geoProvider =
                                    context.read<GeolocationProvider>();
                                final synced = await geoProvider.syncGeolocation(
                                  article.id!,
                                  currentLat!,
                                  currentLon!,
                                );
                                if (!synced && context.mounted) {
                                  await showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Aviso de Sincronización'),
                                      content: Text(
                                        'No se pudo registrar la ubicación en el servidor:\n${geoProvider.errorMessage ?? "Error de red"}\n\nLos cambios locales continuarán.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Aceptar'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }

                              final updatedArticle = article.copyWith(
                                latitud: currentLat,
                                longitud: currentLon,
                                estado: selectedStatus,
                                comentarios: commentsController.text.trim(),
                              );

                              if (context.mounted) {
                                context
                                    .read<InventoryProvider>()
                                    .updateArticleLocally(updatedArticle);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Datos del activo actualizados correctamente',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                setModalState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'ACTUALIZAR DATOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );

    commentsController.dispose();
    editStatusNotifier.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final provider = context.watch<InventoryProvider>();
    _syncNotifiers(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de Activos'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: provider.state == InventoryState.loading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (provider.errorMessage != null)
              Container(
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
                        provider.errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Reintentar',
                      color: Colors.red.shade900,
                      onPressed: () => provider.loadCompanies(),
                    ),
                  ],
                ),
              ),
            _buildCompanySelector(provider),
            const SizedBox(height: 10),
            _buildWarehouseSelector(provider),
            const SizedBox(height: 10),
            Text(
              'Activos en lista: ${provider.articles.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: provider.articles.isEmpty
                  ? const Center(child: Text('No hay activos para esta bodega'))
                  : ListView.builder(
                      itemCount: provider.articles.length,
                      itemBuilder: (context, index) =>
                          _buildArticleTile(provider.articles[index], provider),
                    ),
            ),
          ],
        ),
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

  Widget _buildArticleTile(ArticleModel article, InventoryProvider provider) {
    Color statusColor;
    switch (article.estado) {
      case 'Operativo':
        statusColor = Colors.green;
        break;
      case 'En Mantenimiento':
        statusColor = Colors.orange;
        break;
      case 'Dañado':
        statusColor = Colors.red;
        break;
      case 'Baja':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _showEditArticleForm(article),
        leading: Container(
          width: 6,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        title: Text(
          article.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Placa: ${article.placa} • Resp: ${article.responsable ?? 'N/A'}',
            ),
            if (article.comentarios != null && article.comentarios!.isNotEmpty)
              Text(
                article.comentarios!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            Text(
              'Estado: ${article.estado ?? "Operativo"}',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        /// MODIFICADO: TRAILING AHORA INCLUYE EL BOTÓN DE TRASPASO
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.orange),
              tooltip: 'Traspasar Activo',
              onPressed: () => _showTransferForm(article, provider),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
