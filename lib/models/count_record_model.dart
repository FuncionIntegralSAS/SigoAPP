class CountRecordModel {
  final String? localId; // SQLite Auto-increment PK
  final String physicalCountId;
  final String warehouseId;
  final String financialArticleId;
  final String counterUserId;
  final int countNumber; // 1, 2, or 3
  final String barcode;
  final double countedQuantity;
  final DateTime countDate; // Fecha de captura real
  final DateTime? syncDate; // Cuando viaja al backend
  final String status; // 'PENDIENTE', 'CONTADO', 'VALIDADO'
  final String isSynced; // 'S' o 'N'

  CountRecordModel({
    this.localId,
    required this.physicalCountId,
    required this.warehouseId,
    required this.financialArticleId,
    required this.counterUserId,
    required this.countNumber,
    required this.barcode,
    required this.countedQuantity,
    required this.countDate,
    this.syncDate,
    required this.status,
    this.isSynced = 'N',
  });

  Map<String, dynamic> toMap() {
    return {
      if (localId != null) 'localId': localId,
      'physicalCountId': physicalCountId,
      'warehouseId': warehouseId,
      'financialArticleId': financialArticleId,
      'counterUserId': counterUserId,
      'countNumber': countNumber,
      'barcode': barcode,
      'countedQuantity': countedQuantity,
      'countDate': countDate.toIso8601String(),
      'syncDate': syncDate?.toIso8601String(),
      'status': status,
      'isSynced': isSynced,
    };
  }

  factory CountRecordModel.fromMap(Map<String, dynamic> map) {
    return CountRecordModel(
      localId: map['localId']?.toString(), // En caso de que sql lo devuelva numérico
      physicalCountId: map['physicalCountId'],
      warehouseId: map['warehouseId'],
      financialArticleId: map['financialArticleId'],
      counterUserId: map['counterUserId'],
      countNumber: map['countNumber'],
      barcode: map['barcode'],
      countedQuantity: (map['countedQuantity'] as num).toDouble(),
      countDate: DateTime.parse(map['countDate']),
      syncDate: map['syncDate'] != null ? DateTime.parse(map['syncDate']) : null,
      status: map['status'],
      isSynced: map['isSynced'],
    );
  }

  /// Convierte al formato JSON exacto estandarizado (camelCase) para el backend Spring Boot.
  Map<String, dynamic> toJsonApi() {
    return {
      'idConteoFisico': physicalCountId,
      'idBodega': warehouseId,
      'idArticuloSistemaFinanciero': financialArticleId,
      'idUsuarioContador': counterUserId,
      'numeroDeConteo': countNumber,
      'codigoBarras': barcode,
      'cantidadContada': countedQuantity,
      'fechaConteo': countDate.toIso8601String(),
      'fechaSincronizacion': syncDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'estado': status,
      'sincronizado': isSynced,
    };
  }
}
