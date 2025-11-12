import '../models/article_model.dart';
import '../models/warehouse_model.dart';

class MockInventoryService {
  // --- Datos Mock de Bodegas ---
  static final List<WarehouseModel> _warehouses = [
    WarehouseModel(id: 'BOG001', name: 'Bodega Central Bogotá'),
    WarehouseModel(id: 'MED002', name: 'Almacén Medellín Norte'),
  ];

  // --- Datos Mock de Artículos/Activos ---
  // Los datos aquí NO tendrán coordenadas inicialmente, solo las tendrán después de pasar por GeneratorScreen.
  static final List<ArticleModel> _articles = [
    // 3 Artículos para la Bodega de Bogotá (BOG001)
    ArticleModel(
      code: 'PC001', // USADO 'code'
      licensePlate: 'ABC-123',
      name: 'Portátil Lenovo T490',
      responsible: 'Juan Pérez',
      costCenter: 'BOG001', // USADO 'costCenter'
    ),
    ArticleModel(
      code: 'MON010', // USADO 'code'
      licensePlate: 'DEF-456',
      name: 'Monitor Curvo 27"',
      responsible: 'Ana López',
      costCenter: 'BOG001', // USADO 'costCenter'
    ),
    ArticleModel(
      code: 'IMP050', // USADO 'code'
      licensePlate: 'GHI-789',
      name: 'Impresora 3D Industrial',
      responsible: 'Ing. Carlos Ruiz',
      costCenter: 'BOG001', // USADO 'costCenter'
    ),

    // 2 Artículos para la Bodega de Medellín (MED002)
    ArticleModel(
      code: 'SERV005', // USADO 'code'
      licensePlate: 'JKL-012',
      name: 'Servidor Rack Dell R440',
      responsible: 'María Soto',
      costCenter: 'MED002', // USADO 'costCenter'
    ),
    ArticleModel(
      code: 'TEL001', // USADO 'code'
      licensePlate: 'MNO-345',
      name: 'Teléfono Satelital',
      responsible: 'Pedro Gómez',
      costCenter: 'MED002', // USADO 'costCenter'
    ),
  ];

  // --- Métodos de Acceso a Datos ---

  // Obtiene todas las bodegas
  List<WarehouseModel> getWarehouses() {
    return _warehouses;
  }

  // Obtiene los artículos asociados a una bodega específica
  List<ArticleModel> getArticlesByWarehouseId(String warehouseId) {
    // Usamos el nuevo nombre del campo: costCenter
    return _articles
        .where((article) => article.costCenter == warehouseId)
        .toList();
  }

  // NUEVO MÉTODO: Actualiza un artículo en la lista mock
  // En un ambiente real, este método haría una llamada PUT o PATCH a una API.
  void updateArticle(ArticleModel updatedArticle) {
    // Buscamos el índice del artículo a actualizar usando su código y centro de costos.
    final index = _articles.indexWhere(
      (article) => article.code == updatedArticle.code && article.costCenter == updatedArticle.costCenter,
    );

    if (index != -1) {
      // Si se encuentra, lo reemplazamos con la nueva instancia (que incluye lat/lon)
      _articles[index] = updatedArticle;
    }
  }
}