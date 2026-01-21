import '../models/article_model.dart';
import '../models/warehouse_model.dart';
import '../models/transfer_request.dart';


import 'network_client.dart';

/// **MOCK INVENTORY SERVICE**
/// 
/// Gestiona la lógica de negocio de los activos, incluyendo los nuevos campos
/// de estado, comentarios y fotografía.
class MockInventoryService {

  static final MockInventoryService _instance =
      MockInventoryService._internal();

  factory MockInventoryService() {
    return _instance;
  }

  MockInventoryService._internal();

  final NetworkClient _networkClient = NetworkClient();

  // Lista de bodegas/centros de costos (Datos maestros)
  final List<WarehouseModel> _warehouses = const [
    WarehouseModel(id: 'CC001', name: 'Almacén Central'),
    WarehouseModel(id: 'CC002', name: 'Taller de Mantenimiento'),
    WarehouseModel(id: 'CC003', name: 'Oficinas Administrativas'),
  ];

  // Base de datos simulada de artículos
  final List<ArticleModel> _articles = [
    ArticleModel(
      id: 'A1001', 
      name: 'Montacargas 5T', 
      licensePlate: 'MTG-5001', 
      warehouse: 'CC001', 
      responsible: 'Juan Pérez',
      status: 'Operativo',
      comments: 'Mantenimiento preventivo al día.',
    ),
    ArticleModel(
      id: 'A1002', 
      name: 'Rack de Paletas P-20', 
      licensePlate: 'RK-20-01', 
      warehouse: 'CC001', 
      responsible: 'Maria López',
      status: 'Operativo',
    ),
    ArticleModel(
      id: 'A2001', 
      name: 'Compresor Industrial', 
      licensePlate: 'CI-2001', 
      warehouse: 'CC002', 
      responsible: 'Carlos Ruiz',
      status: 'En Mantenimiento',
      comments: 'Fuga de aceite detectada en válvula principal.',
    ),
  ];

  /// Retorna la lista completa de artículos registrados localmente.
  List<ArticleModel> getArticles() => List.unmodifiable(_articles);

  /// Retorna la lista de bodegas disponibles.
  List<WarehouseModel> getWarehouses() => _warehouses;

  /// **Obtener artículos filtrados por ID de Bodega**
  List<ArticleModel> getArticlesByWarehouseId(String warehouseId) {
    return _articles.where((article) => article.warehouse == warehouseId).toList();
  }

  /// **Lógica para registrar un nuevo activo**
  /// Maneja la validación de duplicados y la persistencia asíncrona simulada.
  Future<ArticleModel> registerNewArticle({
    required String name,
    required String plate,
    required String warehouseId,
    String? responsible,
    String? status,
    String? comments,
    String? photoPath,
  }) async {
    // 1. Validación de placa única (Case Insensitive)
    final normalizedPlate = plate.trim().toUpperCase();
    if (_articles.any((a) => a.licensePlate.toUpperCase() == normalizedPlate)) {
      throw Exception('La placa $plate ya está registrada en el sistema.');
    }

    // 2. Preparar datos para la simulación de red
    final Map<String, dynamic> data = {
      'name': name,
      'licensePlate': normalizedPlate,
      'warehouseId': warehouseId,
      'responsible': responsible,
      'status': status,
      'comments': comments,
      'photoPath': photoPath,
    };

    // 3. Llamada simulada al cliente de red (Capa de Infraestructura)
    final response = await _networkClient.postCreateArticle(data);

    // 4. Mapeo al ArticleModel con los nuevos campos
    // Nota: Usamos 'initialValue' semántico para el estado si viene nulo
    final newArticle = ArticleModel(
      id: response['id'],
      name: response['name'],
      licensePlate: response['licensePlate'],
      warehouse: response['costCenterId'], 
      responsible: response['responsible'],
      status: status ?? 'Operativo',
      comments: comments,
      photoPath: photoPath,
    );

    _articles.add(newArticle);
    return newArticle;
  }

  /// **Actualiza la instancia de un artículo**
  /// Utiliza la comparación de Equatable para localizar el activo por su ID.
  void updateArticle(ArticleModel updatedArticle) {
    final index = _articles.indexWhere((a) => a.id == updatedArticle.id);
    if (index != -1) {
      _articles[index] = updatedArticle;
    }
  }

  //Simulación de solicitud de traspaso
  final List<TransferRequest> _transferRequests = [];

  void createTransferRequest(TransferRequest request) {
    _transferRequests.add(request);
  }

  List<TransferRequest> get transferRequests =>
    List.unmodifiable(_transferRequests);


  List<TransferRequest> getPendingTransferRequests() {
    return _transferRequests
        .where((r) => r.status == TransferStatus.pending)
        .toList();
  }

  //Aprobación de Transferencias
  void approveTransferRequest(String requestId) {
  final index = _transferRequests.indexWhere((r) => r.id == requestId);
  if (index == -1) return;

  final request = _transferRequests[index];

  _transferRequests[index] = TransferRequest(
      id: request.id,
      articleId: request.articleId,
      articleName: request.articleName,
      currentResponsible: request.currentResponsible,
      proposedResponsible: request.proposedResponsible,
      currentWarehouse: request.currentWarehouse,
      proposedWarehouse: request.proposedWarehouse,
      requestReason: request.requestReason,
      requestDate: request.requestDate,
      status: TransferStatus.approved,
    );
  }

  void rejectTransferRequest({
    required String requestId,
    required String rejectionReason,
  }) {
    final index = _transferRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final request = _transferRequests[index];

    _transferRequests[index] = TransferRequest(
      id: request.id,
      articleId: request.articleId,
      articleName: request.articleName,
      currentResponsible: request.currentResponsible,
      proposedResponsible: request.proposedResponsible,
      currentWarehouse: request.currentWarehouse,
      proposedWarehouse: request.proposedWarehouse,
      requestReason: request.requestReason,
      requestDate: request.requestDate,
      status: TransferStatus.rejected,
      rejectionReason: rejectionReason,
    );
  }

  void applyApprovedTransfer(TransferRequest request) {
    // Validar estado
    if (request.status != TransferStatus.pending) {
      throw Exception(
        'El traspaso ya fue procesado (${request.status.name}).',
      );
    }

    // Buscar el activo
    final articleIndex =
        _articles.indexWhere((a) => a.id == request.articleId);

    if (articleIndex == -1) {
      throw Exception(
        'No se encontró el activo asociado al traspaso.',
      );
    }

    final currentArticle = _articles[articleIndex];

    // Aplicar cambios al activo 
    final updatedArticle = currentArticle.copyWith(
      responsible: request.proposedResponsible,
      warehouse: request.proposedWarehouse,
    );

    _articles[articleIndex] = updatedArticle;

    // Actualizar estado del traspaso
    final requestIndex =
        _transferRequests.indexWhere((r) => r.id == request.id);

    if (requestIndex != -1) {
      _transferRequests[requestIndex] =
          request.copyWith(status: TransferStatus.approved);
    }

    //Lista privada de solicitudes de traspaso
    
  }

  void rejectTransfer(
  TransferRequest request,
  String rejectionReason,
  ) {
    final index = _transferRequests.indexWhere((r) => r.id == request.id);
    if (index == -1) return;

    _transferRequests[index] = request.copyWith(
      status: TransferStatus.rejected,
      rejectionReason: rejectionReason,
    );
  }


}