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
    WarehouseModel(
      codigoBodega: 'BOG001',
      descripcionBodega: 'Almacén Central',
      estadoBodega: 'ac',
    ),
    WarehouseModel(
      codigoBodega: 'MED002',
      descripcionBodega: 'Taller de Mantenimiento',
      estadoBodega: 'ac',
    ),
    WarehouseModel(
      codigoBodega: 'CC003',
      descripcionBodega: 'Oficinas Administrativas',
      estadoBodega: 'ia',
    ),
  ];

  // Base de datos simulada de artículos
  final List<ArticleModel> _articles = [
    const ArticleModel(
      id: 1,
      codigoActivo: 'PC001',
      nombre: 'Portátil Prueba',
      placa: 'ABC-123',
      bodega: 'BOG001',
      responsable: 'Responsable Test',
      estado: 'Operativo',
    ),
    const ArticleModel(
      id: 2,
      codigoActivo: 'A1002',
      nombre: 'Rack de Paletas P-20',
      placa: 'RK-20-01',
      bodega: 'BOG001',
      responsable: 'Maria López',
      estado: 'Operativo',
    ),
    const ArticleModel(
      id: 3,
      codigoActivo: 'A1003',
      nombre: 'Mesa de Trabajo',
      placa: 'MT-01',
      bodega: 'BOG001',
      responsable: 'Juan Pérez',
      estado: 'Operativo',
    ),
    const ArticleModel(
      id: 4,
      codigoActivo: 'A2001',
      nombre: 'Compresor Industrial',
      placa: 'CI-2001',
      bodega: 'MED002',
      responsable: 'Carlos Ruiz',
      estado: 'En Mantenimiento',
      comentarios: 'Fuga de aceite detectada en válvula principal.',
    ),
    const ArticleModel(
      id: 5,
      codigoActivo: 'A2002',
      nombre: 'Herramienta Neumática',
      placa: 'HN-01',
      bodega: 'MED002',
      responsable: 'Carlos Ruiz',
      estado: 'Operativo',
    ),
  ];

  /// Retorna la lista completa de artículos registrados localmente.
  List<ArticleModel> getArticles() => List.unmodifiable(_articles);

  /// Retorna la lista de bodegas disponibles.
  List<WarehouseModel> getWarehouses() => _warehouses;

  /// Mapa de bodegas asignadas por responsable (simulación de autorización en cascada)
  static const Map<String, List<String>> _responsibleWarehouseCodes = {
    'Juan Pérez': ['BOG001', 'CC003'],
    'Maria López': ['BOG001', 'MED002'],
    'Carlos Ruiz': ['MED002', 'CC003'],
    'Andrés Felipe Restrepo': ['BOG001', 'MED002', 'CC003'],
  };

  /// Retorna las bodegas asignadas a un responsable específico.
  List<WarehouseModel> getWarehousesForResponsible(String responsable) {
    final codes = _responsibleWarehouseCodes[responsable];
    if (codes == null || codes.isEmpty) {
      return _warehouses;
    }
    return _warehouses.where((w) => codes.contains(w.codigoBodega)).toList();
  }

  /// **Obtener artículos filtrados por ID de Bodega**
  List<ArticleModel> getArticlesByWarehouseId(String idBodega) {
    return _articles
        .where((article) => article.bodega == idBodega)
        .toList();
  }

  /// **Lógica para registrar un nuevo activo**
  /// Maneja la validación de duplicados y la persistencia asíncrona simulada.
  Future<ArticleModel> registerNewArticle({
    required String name,
    required String plate,
    required String idBodega,
    String? responsable,
    String? status,
    String? comentarios,
    String? rutaFoto,
  }) async {
    // 1. Validación de placa única (Case Insensitive)
    final normalizedPlate = plate.trim().toUpperCase();
    if (_articles.any((a) => a.placa.toUpperCase() == normalizedPlate)) {
      throw Exception('La placa $plate ya está registrada en el sistema.');
    }

    // 2. Preparar datos para la simulación de red
    final Map<String, dynamic> data = {
      'name': name,
      'placa': normalizedPlate,
      'idBodega': idBodega,
      'responsable': responsable,
      'status': status,
      'comentarios': comentarios,
      'rutaFoto': rutaFoto,
    };

    // 3. Llamada simulada al cliente de red (Capa de Infraestructura)
    final response = await _networkClient.postCreateArticle(data);

    // 4. Mapeo al ArticleModel con los nuevos campos
    // Nota: Usamos 'initialValue' semántico para el estado si viene nulo
    final newArticle = ArticleModel(
      id: response['id'] != null ? int.tryParse(response['id'].toString()) : _articles.length + 1,
      codigoActivo: response['codigoActivo']?.toString() ?? response['artiCodi']?.toString() ?? response['id']?.toString() ?? 'ART${_articles.length + 1}',
      nombre: response['name'],
      placa: response['placa'],
      bodega: response['costCenterId'] ?? response['bodega'] ?? '',
      responsable: response['responsable'],
      estado: status ?? 'Operativo',
      comentarios: comentarios,
      rutaFoto: rutaFoto,
    );

    _articles.add(newArticle);
    return newArticle;
  }

  /// **Actualiza la instancia de un artículo**
  /// Utiliza la comparación de Equatable para localizar el activo por su código.
  void updateArticle(ArticleModel updatedArticle) {
    final index = _articles.indexWhere((a) => a.codigoActivo == updatedArticle.codigoActivo);
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
        .where((r) => r.estado == TransferStatus.pending)
        .toList();
  }

  //Aprobación de Transferencias
  void approveTransferRequest(String requestId) {
    final index = _transferRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final request = _transferRequests[index];

    _transferRequests[index] = TransferRequest(
      id: request.id,
      idArticulo: request.idArticulo,
      nombreArticulo: request.nombreArticulo,
      responsableActual: request.responsableActual,
      responsablePropuesto: request.responsablePropuesto,
      bodegaActual: request.bodegaActual,
      bodegaPropuesta: request.bodegaPropuesta,
      motivoSolicitud: request.motivoSolicitud,
      fechaSolicitud: request.fechaSolicitud,
      estado: TransferStatus.approved,
    );
  }

  void rejectTransferRequest({
    required String requestId,
    required String motivoRechazo,
  }) {
    final index = _transferRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final request = _transferRequests[index];

    _transferRequests[index] = TransferRequest(
      id: request.id,
      idArticulo: request.idArticulo,
      nombreArticulo: request.nombreArticulo,
      responsableActual: request.responsableActual,
      responsablePropuesto: request.responsablePropuesto,
      bodegaActual: request.bodegaActual,
      bodegaPropuesta: request.bodegaPropuesta,
      motivoSolicitud: request.motivoSolicitud,
      fechaSolicitud: request.fechaSolicitud,
      estado: TransferStatus.rejected,
      motivoRechazo: motivoRechazo,
    );
  }

  void applyApprovedTransfer(TransferRequest request) {
    // Validar estado
    if (request.estado != TransferStatus.pending) {
      throw Exception('El traspaso ya fue procesado (${request.estado.name}).');
    }

    // Buscar el activo
    final articleIndex = _articles.indexWhere((a) => a.codigoActivo == request.idArticulo);

    if (articleIndex == -1) {
      throw Exception('No se encontró el activo asociado al traspaso.');
    }

    final currentArticle = _articles[articleIndex];

    // Aplicar cambios al activo
    final updatedArticle = currentArticle.copyWith(
      responsable: request.responsablePropuesto,
      bodega: request.bodegaPropuesta,
    );

    _articles[articleIndex] = updatedArticle;

    // Actualizar estado del traspaso
    final requestIndex = _transferRequests.indexWhere(
      (r) => r.id == request.id,
    );

    if (requestIndex != -1) {
      _transferRequests[requestIndex] = request.copyWith(
        estado: TransferStatus.approved,
      );
    }

    //Lista privada de solicitudes de traspaso
  }

  void rejectTransfer(TransferRequest request, String motivoRechazo) {
    final index = _transferRequests.indexWhere((r) => r.id == request.id);
    if (index == -1) return;

    _transferRequests[index] = request.copyWith(
      estado: TransferStatus.rejected,
      motivoRechazo: motivoRechazo,
    );
  }
}
