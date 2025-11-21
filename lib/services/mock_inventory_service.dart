import '../models/article_model.dart';
import '../models/warehouse_model.dart';

// Servicio que simula la interacción con una base de datos o API.
// Mantiene el estado de los artículos y bodegas en memoria (mock data).
class MockInventoryService {
  // Lista estática de Bodegas/Centros de Costos
  final List<WarehouseModel> _warehouses = const [
    // Se usa 'const' porque el constructor de WarehouseModel fue actualizado
    const WarehouseModel(id: 'CC001', name: 'Almacén Central'),
    const WarehouseModel(id: 'CC002', name: 'Taller de Mantenimiento'),
    const WarehouseModel(id: 'CC003', name: 'Oficinas Administrativas'),
  ];

  // Lista estática de Artículos. Debe ser mutable (`List`) para permitir la actualización de ubicación.
  // CORRECCIÓN: Se añade 'final' ya que la referencia de la lista no cambia.
  final List<ArticleModel> _articles = [
    ArticleModel(
        id: 'A1001',
        name: 'Montacargas 5T',
        licensePlate: 'MTG-5001',
        warehouse: 'CC001'),
    ArticleModel(
        id: 'A1002',
        name: 'Rack de Paletas P-20',
        licensePlate: 'RK-20-01',
        warehouse: 'CC001'),
    ArticleModel(
        id: 'A2001',
        name: 'Banco de Pruebas Electrónicas',
        licensePlate: 'BP-EL-05',
        warehouse: 'CC002'),
    ArticleModel(
        id: 'A3001',
        name: 'Servidor Principal',
        licensePlate: 'SRV-P-01',
        warehouse: 'CC003'),
  ];

  // Map interno para búsquedas rápidas (por ID)
  final Map<String, ArticleModel> _articleMap = {};

  MockInventoryService() {
    // Inicializar el Map para búsquedas rápidas al inicio
    _articles.forEach((a) {
      _articleMap[a.id] = a;
    });
  }

  // ------------------------------------
  // MÉTODOS DE ACCESO A DATOS
  // ------------------------------------

  // 1. Retorna todos los artículos sin filtrar (necesario para InventoryScreen)
  List<ArticleModel> getArticles() {
    return _articles;
  }

  // 2. Retorna todas las bodegas
  List<WarehouseModel> getWarehouses() {
    return _warehouses;
  }

  // 3. Retorna los artículos filtrados por Centro de Costos
  List<ArticleModel> getArticlesByCostCenter(String warehouse) {
    return _articles
        .where((article) => article.warehouse == warehouse)
        .toList();
  }

  // 4. Actualiza un artículo existente (usado para registrar Lat/Lon del QR)
  // Utiliza el ID para encontrar y reemplazar el objeto en la lista.
  void updateArticle(ArticleModel updatedArticle) {
    // 4a. Actualizar el Map
    _articleMap[updatedArticle.id] = updatedArticle;

    // 4b. Actualizar la lista _articles
    final index = _articles.indexWhere((a) => a.id == updatedArticle.id);
    if (index != -1) {
      // Reemplaza el objeto antiguo con el nuevo objeto (que contiene la ubicación)
      _articles[index] = updatedArticle;
    }
  }
}