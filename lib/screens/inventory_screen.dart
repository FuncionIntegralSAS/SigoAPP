import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/article_model.dart';
import '../models/warehouse_model.dart';
import '../services/mock_inventory_service.dart';
import '../services/mock_auth_service.dart';
import '../widgets/transfer_form_widget.dart'; // Importamos el widget del formulario

const WarehouseModel _allWarehousesFilter = WarehouseModel(
  id: 'ALL',
  name: 'Todas las Bodegas (Inventario Total)',
);

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final MockInventoryService _service = MockInventoryService();
  final Color primaryColor = Colors.orange.shade700;

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!mounted) return;
    setState(() {
      _allArticles = List.from(_service.getArticles());
      if (_warehouses.isEmpty) {
        _warehouses = [_allWarehousesFilter, ..._service.getWarehouses()];
        _selectedWarehouse = _allWarehousesFilter;
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
        _selectedWarehouse!.id == _allWarehousesFilter.id) {
      return _allArticles;
    }
    return _allArticles
        .where((a) => a.warehouse == _selectedWarehouse!.id)
        .toList();
  }

  /// MÉTODO PARA MOSTRAR EL FORMULARIO DE TRASPASO
  void _showTransferForm(ArticleModel article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.white, // Permite ver el diseño redondeado del widget
      builder: (context) =>
          TransferFormWidget(article: article, users: _responsibles),
    );
  }

  void _showEditArticleForm(ArticleModel article) {
    final nameController = TextEditingController(text: article.name);
    final plateController = TextEditingController(text: article.licensePlate);
    final commentsController = TextEditingController(
      text: article.comments ?? '',
    );

    String? selectedResponsible = article.responsible;
    String? selectedStatus = article.status ?? 'Operativo';
    String? photoPath = article.photoPath;

    WarehouseModel? selectedWh = _service.getWarehouses().firstWhere(
      (w) => w.id == article.warehouse,
      orElse: () => _service.getWarehouses().first,
    );

    double? currentLat = article.latitude;
    double? currentLon = article.longitude;
    bool isLocating = false;
    bool isSaving = false;

    showModalBottomSheet(
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
              photoPath =
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
              bottom: MediaQuery.of(context).viewInsets.bottom,
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
                    'Editar Activo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Activo',
                      prefixIcon: Icon(Icons.inventory),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: plateController,
                    decoration: const InputDecoration(
                      labelText: 'Placa / Identificador',
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<WarehouseModel>(
                    initialValue: selectedWh,
                    decoration: const InputDecoration(
                      labelText: 'Bodega de Destino',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    items: _service
                        .getWarehouses()
                        .map(
                          (w) =>
                              DropdownMenuItem(value: w, child: Text(w.name)),
                        )
                        .toList(),
                    onChanged: (v) => setModalState(() => selectedWh = v),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            prefixIcon: Icon(Icons.info_outline),
                          ),
                          items: _statusOptions
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setModalState(() => selectedStatus = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedResponsible,
                          decoration: const InputDecoration(
                            labelText: 'Responsable',
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: _responsibles
                              .map(
                                (r) =>
                                    DropdownMenuItem(value: r, child: Text(r)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setModalState(() => selectedResponsible = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: commentsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Comentarios adicionales',
                      prefixIcon: Icon(Icons.comment),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            photoPath == null ? 'TOMAR FOTO' : 'CAMBIAR FOTO',
                          ),
                        ),
                      ),
                      if (photoPath != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ],
                  ),
                  const SizedBox(height: 15),

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
                              'Geolocalización Registrada',
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
                                    icon: const Icon(
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

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            if (nameController.text.isEmpty ||
                                plateController.text.isEmpty ||
                                selectedWh == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Por favor llene los campos obligatorios.',
                                  ),
                                ),
                              );
                              return;
                            }
                            setModalState(() => isSaving = true);
                            try {
                              final updatedArticle = article.copyWith(
                                name: nameController.text,
                                licensePlate: plateController.text,
                                warehouse: selectedWh!.id,
                                responsible: selectedResponsible,
                                latitude: currentLat,
                                longitude: currentLon,
                                status: selectedStatus,
                                comments: commentsController.text,
                                photoPath: photoPath,
                              );

                              _service.updateArticle(updatedArticle);

                              if (context.mounted) {
                                Navigator.pop(context);
                                _loadData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
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
                      backgroundColor: Colors.blue.shade700,
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
  }

  void _showAddArticleForm() {
    final nameController = TextEditingController();
    final plateController = TextEditingController();
    final commentsController = TextEditingController();

    String? selectedResponsible;
    String? selectedStatus = 'Operativo';
    String? photoPath;
    WarehouseModel? selectedWh;
    double? currentLat;
    double? currentLon;
    bool isLocating = false;
    bool isSaving = false;

    showModalBottomSheet(
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
              photoPath =
                  'path/to/local/storage/new_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Foto capturada (Cámara exclusiva)'),
                ),
              );
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
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
                    'Registrar Nuevo Activo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Activo',
                      prefixIcon: Icon(Icons.inventory),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: plateController,
                    decoration: const InputDecoration(
                      labelText: 'Placa / Identificador',
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<WarehouseModel>(
                    decoration: const InputDecoration(
                      labelText: 'Bodega de Destino',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    items: _service
                        .getWarehouses()
                        .map(
                          (w) =>
                              DropdownMenuItem(value: w, child: Text(w.name)),
                        )
                        .toList(),
                    onChanged: (v) => setModalState(() => selectedWh = v),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            prefixIcon: Icon(Icons.info_outline),
                          ),
                          items: _statusOptions
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setModalState(() => selectedStatus = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Responsable',
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: _responsibles
                              .map(
                                (r) =>
                                    DropdownMenuItem(value: r, child: Text(r)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setModalState(() => selectedResponsible = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: commentsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Comentarios adicionales',
                      prefixIcon: Icon(Icons.comment),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  OutlinedButton.icon(
                    onPressed: takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      photoPath == null ? 'TOMAR FOTO' : 'FOTO CAPTURADA',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: photoPath != null
                          ? Colors.green
                          : primaryColor,
                    ),
                  ),
                  const SizedBox(height: 15),

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
                              'Geolocalización Actual',
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
                                    icon: const Icon(
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameController.text.isEmpty ||
                                plateController.text.isEmpty ||
                                selectedWh == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Por favor llene los campos obligatorios.',
                                  ),
                                ),
                              );
                              return;
                            }
                            setModalState(() => isSaving = true);
                            try {
                              await _service.registerNewArticle(
                                name: nameController.text,
                                plate: plateController.text,
                                warehouseId: selectedWh!.id,
                                responsible: selectedResponsible,
                                status: selectedStatus,
                                comments: commentsController.text,
                                photoPath: photoPath,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                _loadData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '✅ Activo registrado con éxito',
                                    ),
                                    backgroundColor: Colors.green,
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
                            'GUARDAR ACTIVO',
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
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = MockAuthService.instance.currentUser.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de Activos'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Text(
              'Hola, ${currentUser?.name ?? '...'}  ',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => MockAuthService.instance.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddArticleForm,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
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
    return DropdownButtonFormField<WarehouseModel>(
      initialValue: _selectedWarehouse,
      decoration: InputDecoration(
        labelText: 'Filtrar por Bodega',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: _warehouses
          .map((w) => DropdownMenuItem(value: w, child: Text(w.name)))
          .toList(),
      onChanged: (v) => setState(() => _selectedWarehouse = v),
    );
  }

  Widget _buildArticleTile(ArticleModel article) {
    Color statusColor;
    switch (article.status) {
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
          article.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Placa: ${article.licensePlate} • Resp: ${article.responsible ?? 'N/A'}',
            ),
            if (article.comments != null && article.comments!.isNotEmpty)
              Text(
                article.comments!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            Text(
              'Estado: ${article.status ?? "Operativo"}',
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
