import '../models/article_model.dart';
import '../models/warehouse_model.dart';
import 'network_client.dart';

class MockInventoryService {
  final NetworkClient _networkClient = NetworkClient();

  final List<WarehouseModel> _warehouses = const [
    WarehouseModel(id: 'CC001', name: 'Almacén Central'),
    WarehouseModel(id: 'CC002', name: 'Taller de Mantenimiento'),
    WarehouseModel(id: 'CC003', name: 'Oficinas Administrativas'),
  ];

  final List<ArticleModel> _articles = [
    ArticleModel(
      id: 'A1001', 
      name: 'Montacargas 5T', 
      licensePlate: 'MTG-5001', 
      warehouse: 'CC001', 
      responsible: 'Juan Pérez'
    ),
    ArticleModel(
      id: 'A1002', 
      name: 'Rack de Paletas P-20', 
      licensePlate: 'RK-20-01', 
      warehouse: 'CC001', 
      responsible: 'Maria López'
    ),
    ArticleModel(
      id: 'A2001', 
      name: 'Compresor Industrial', 
      licensePlate: 'CI-2001', 
      warehouse: 'CC002', 
      responsible: 'Carlos Ruiz'
    ),
  ];

  List<ArticleModel> getArticles() => _articles;
  List<WarehouseModel> getWarehouses() => _warehouses;

  /// **Obtener artículos filtrados por ID de Bodega**
  /// Se utiliza el atributo 'warehouse' del modelo ArticleModel.
  List<ArticleModel> getArticlesByWarehouseId(String warehouseId) {
    return _articles.where((article) => article.warehouse == warehouseId).toList();
  }

  /// Lógica para registrar un nuevo activo
  Future<ArticleModel> registerNewArticle({
    required String name,
    required String plate,
    required String warehouseId,
    String? responsible,
  }) async {
    // Validación de placa única local
    if (_articles.any((a) => a.licensePlate.toUpperCase() == plate.toUpperCase())) {
      throw Exception('La placa $plate ya está registrada en el sistema.');
    }

    // Datos para la simulación de red (la API podría seguir usando costCenterId internamente)
    final data = {
      'name': name,
      'licensePlate': plate,
      'costCenterId': warehouseId,
      'responsible': responsible,
    };

    final response = await _networkClient.postCreateArticle(data);

    // Mapeo al nuevo ArticleModel usando el campo 'warehouse'
    final newArticle = ArticleModel(
      id: response['id'],
      name: response['name'],
      licensePlate: response['licensePlate'],
      warehouse: response['costCenterId'], // Mapeamos la respuesta a 'warehouse'
      responsible: response['responsible'],
    );

    _articles.add(newArticle);
    return newArticle;
  }

  /// Actualiza la instancia de un artículo en la lista local
  void updateArticle(ArticleModel updatedArticle) {
    final index = _articles.indexWhere((a) => a.id == updatedArticle.id);
    if (index != -1) {
      _articles[index] = updatedArticle;
    }
  }
}