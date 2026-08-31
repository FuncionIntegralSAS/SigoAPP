import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../models/article_model.dart';
import '../models/warehouse_model.dart';
import '../services/mock_inventory_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/transfer_form_widget.dart'; // Importamos el widget del formulario
import '../utils/dropdown_template.dart';

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
  final MockInventoryService _service = MockInventoryService();
  final Color primaryColor = Colors.deepPurple;

  List<ArticleModel> _allArticles = [];
  List<WarehouseModel> _warehouses = [];
  List<String> _responsibles = [];

  final List<String> _statusOptions = [
    'Operativo',
    'En Mantenimiento',
    'Dañado',
    'Baja',
  ];

  WarehouseModel? _selectedWarehouse;
  final ValueNotifier<WarehouseModel?> _filterWarehouseNotifier = ValueNotifier(
    null,
  );
  final TextEditingController _warehouseFilterSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _filterWarehouseNotifier.dispose();
    _warehouseFilterSearchController.dispose();
    super.dispose();
  }

  void _loadData() {
    if (!mounted) return;
    setState(() {
      _allArticles = List.from(_service.getArticles());
      if (_warehouses.isEmpty) {
        _warehouses = [_allWarehousesFilter, ..._service.getWarehouses()];
        _selectedWarehouse = _allWarehousesFilter;
        _filterWarehouseNotifier.value = _selectedWarehouse;
      }

      _responsibles = [
        'Juan Pérez',
        'Maria López',
        'Carlos Ruiz',
        'Andrés Felipe Restrepo',
      ];
    });
  }

  List<ArticleModel> get _filteredArticles {
    if (_selectedWarehouse == null ||
        _selectedWarehouse!.codigoBodega == _allWarehousesFilter.codigoBodega) {
      return _allArticles;
    }
    return _allArticles
        .where((a) => a.bodega == _selectedWarehouse!.codigoBodega)
        .toList();
  }

  /// MÉTODO PARA MOSTRAR EL FORMULARIO DE TRASPASO
  void _showTransferForm(ArticleModel article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => TransferFormWidget(
        article: article,
        users: _responsibles,
        warehouses: _warehouses
            .where((w) => w.codigoBodega != _allWarehousesFilter.codigoBodega)
            .toList(),
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
                        : () {
                            setModalState(() => isSaving = true);
                            try {
                              final updatedArticle = article.copyWith(
                                estado: selectedStatus,
                                comentarios: commentsController.text,
                                latitud: currentLat,
                                longitud: currentLon,
                                rutaFoto: rutaFoto,
                              );

                              _service.updateArticle(updatedArticle);

                              if (context.mounted) {
                                Navigator.pop(context);
                                _loadData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      '✅ Activo actualizado con éxito',
                                    ),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildWarehouseSelector(),
            const SizedBox(height: 10),
            Text(
              'Activos en lista: ${_filteredArticles.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: _filteredArticles.isEmpty
                  ? const Center(child: Text('No hay activos para esta bodega'))
                  : ListView.builder(
                      itemCount: _filteredArticles.length,
                      itemBuilder: (context, index) =>
                          _buildArticleTile(_filteredArticles[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseSelector() {
    return DropdownButtonFormField2<WarehouseModel>(
      isExpanded: true,
      valueListenable: _filterWarehouseNotifier,
      decoration: InputDecoration(
        labelText: 'Filtrar por Bodega',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: _warehouses
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
        setState(() {
          _selectedWarehouse = v;
          _filterWarehouseNotifier.value = v;
        });
      },
      dropdownSearchData: DropdownTemplates.searchData(
        controller: _warehouseFilterSearchController,
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
        if (!isOpen) _warehouseFilterSearchController.clear();
      },
    );
  }

  Widget _buildArticleTile(ArticleModel article) {
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
              onPressed: () => _showTransferForm(article),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
