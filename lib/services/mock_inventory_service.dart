import '../models/article_model.dart';
import '../models/warehouse_model.dart';

class MockInventoryService {
  // --- Datos Mock de Bodegas ---
  static final List<WarehouseModel> _warehouses = [
    WarehouseModel(id: 'BOG001', name: 'Bodega Central Bogotá'),
    WarehouseModel(id: 'MED002', name: 'Almacén Medellín Norte'),
  ];

  // --- Datos Mock de Artículos/Activos ---
  static final List<ArticleModel> _articles = [
    // 3 Artículos para la Bodega de Bogotá (BOG001)
    ArticleModel(
      code: 'PC001',
      licensePlate: 'ABC-123',
      name: 'Portátil Lenovo T490',
      responsible: 'Juan Pérez',
      costCenter: 'BOG001',
      
    ),
    ArticleModel(
      code: 'MON010',
      licensePlate: 'DEF-456',
      name: 'Monitor Curvo 27"',
      responsible: 'Ana López',
      costCenter: 'BOG001',
    ),
    ArticleModel(
      code: 'IMP050',
      licensePlate: 'GHI-789',
      name: 'Impresora 3D Industrial',
      responsible: 'Ing. Carlos Ruiz',
      costCenter: 'BOG001',
    ),

    // 2 Artículos para la Bodega de Medellín (MED002)
    ArticleModel(
      code: 'SERV005',
      licensePlate: 'JKL-012',
      name: 'Servidor Rack Dell R440',
      responsible: 'María Soto',
      costCenter: 'MED002',
    ),
    ArticleModel(
      code: 'TEL001',
      licensePlate: 'MNO-345',
      name: 'Teléfono Satelital',
      responsible: 'Pedro Gómez',
      costCenter: 'MED002',
    ),
  ];

  // --- Métodos de Acceso a Datos ---

  // Obtiene todas las bodegas
  List<WarehouseModel> getWarehouses() {
    return _warehouses;
  }

  // Obtiene los artículos asociados a una bodega específica
  List<ArticleModel> getArticlesByWarehouseId(String warehouseId) {
    return _articles
        .where((article) => article.costCenter == warehouseId)
        .toList();
  }
}