import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/article_model.dart';
import '../models/warehouse_model.dart';
import '../services/mock_inventory_service.dart';
import '../services/mock_auth_service.dart';

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
  WarehouseModel? _selectedWarehouse;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _allArticles = List.from(_service.getArticles());
      if (_warehouses.isEmpty) {
        _warehouses = [_allWarehousesFilter, ..._service.getWarehouses()];
        _selectedWarehouse = _allWarehousesFilter;
      }
      // Lista de usuarios registrados activos para el selector
      _responsibles = [
        'Juan Pérez',
        'Maria López',
        'Carlos Ruiz',
        'Andrés Felipe Restrepo'
      ];
    });
  }

  List<ArticleModel> get _filteredArticles {
    if (_selectedWarehouse == null || _selectedWarehouse!.id == _allWarehousesFilter.id) {
      return _allArticles;
    }
    return _allArticles.where((a) => a.warehouse == _selectedWarehouse!.id).toList();
  }

  /// **Formulario de registro dentro de un cuadro de diálogo (BottomSheet)**
  void _showAddArticleForm() {
    final nameController = TextEditingController();
    final plateController = TextEditingController();
    
    String? selectedResponsible;
    WarehouseModel? selectedWh;
    double? currentLat;
    double? currentLon;
    bool isLocating = false;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          
          Future<void> captureLocation() async {
            setModalState(() => isLocating = true);
            try {
              LocationPermission permission = await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
              }
              final position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
              );
              setModalState(() {
                currentLat = position.latitude;
                currentLon = position.longitude;
                isLocating = false;
              });
            } catch (e) {
              setModalState(() => isLocating = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error GPS: $e'))
              );
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20, right: 20, top: 20
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Registrar Nuevo Activo', 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: nameController, 
                    decoration: const InputDecoration(labelText: 'Nombre del Activo', prefixIcon: Icon(Icons.inventory))
                  ),
                  const SizedBox(height: 10),
                  
                  TextField(
                    controller: plateController, 
                    decoration: const InputDecoration(labelText: 'Placa / Identificador', prefixIcon: Icon(Icons.badge))
                  ),
                  const SizedBox(height: 10),
                  
                  DropdownButtonFormField<WarehouseModel>(
                    decoration: const InputDecoration(labelText: 'Bodega de Destino', prefixIcon: Icon(Icons.location_on)),
                    items: _service.getWarehouses().map((w) => DropdownMenuItem(value: w, child: Text(w.name))).toList(),
                    onChanged: (v) => setModalState(() => selectedWh = v),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Responsable', prefixIcon: Icon(Icons.person)),
                    items: _responsibles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setModalState(() => selectedResponsible = v),
                  ),
                  const SizedBox(height: 20),

                  // Sección de Geolocalización
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade100)
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Geolocalización Actual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            isLocating 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(
                                  onPressed: captureLocation, 
                                  icon: const Icon(Icons.my_location, color: Colors.blue, size: 20)
                                ),
                          ],
                        ),
                        if (currentLat != null)
                          Text('Lat: $currentLat, Lon: $currentLon', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (nameController.text.isEmpty || plateController.text.isEmpty || selectedWh == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor llene los campos obligatorios.')));
                        return;
                      }
                      setModalState(() => isSaving = true);
                      try {
                        await _service.registerNewArticle(
                          name: nameController.text,
                          plate: plateController.text,
                          warehouseId: selectedWh!.id,
                          responsible: selectedResponsible,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Activo registrado con éxito'), backgroundColor: Colors.green)
                          );
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red)
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, 
                      padding: const EdgeInsets.symmetric(vertical: 15)
                    ),
                    child: isSaving 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('GUARDAR ACTIVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }
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
          Center(child: Text('Hola, ${currentUser?.name ?? '...'}  ', style: const TextStyle(color: Colors.white, fontSize: 12))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => MockAuthService.instance.signOut()),
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
            Text('Activos en lista: ${_filteredArticles.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredArticles.length,
                itemBuilder: (context, index) => _buildArticleTile(_filteredArticles[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseSelector() {
    return DropdownButtonFormField<WarehouseModel>(
      value: _selectedWarehouse,
      decoration: InputDecoration(
        labelText: 'Filtrar por Bodega', 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
      ),
      items: _warehouses.map((w) => DropdownMenuItem(value: w, child: Text(w.name))).toList(),
      onChanged: (v) => setState(() => _selectedWarehouse = v),
    );
  }

  Widget _buildArticleTile(ArticleModel article) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Icon(Icons.qr_code, color: primaryColor),
        title: Text(article.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Placa: ${article.licensePlate}\nResp: ${article.responsible ?? "No asignado"}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}