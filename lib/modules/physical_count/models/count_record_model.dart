class CountRecordModel {
  final String? localId; // SQLite Auto-increment PK
  final String physicalCountId;
  final String idBodega;
  final String financialArticleId;
  final String counterUserId;
  final int countNumber; // 1, 2, or 3
  final String barcode;
  final double countedQuantity;
  final DateTime countDate; // Fecha de captura real
  final DateTime? fechaSincronizacion; // Cuando viaja al backend
  final String estado; // 'PENDIENTE', 'CONTADO', 'VALIDADO'
  final String isSynced; // 'S' o 'N'

  CountRecordModel({
    this.localId,
    required this.physicalCountId,
    required this.idBodega,
    required this.financialArticleId,
    required this.counterUserId,
    required this.countNumber,
    required this.barcode,
    required this.countedQuantity,
    required this.countDate,
    this.fechaSincronizacion,
    required this.estado,
    this.isSynced = 'N',
  });

  Map<String, dynamic> toMap() {
    return {
      if (localId != null) 'localId': localId,
      'physicalCountId': physicalCountId,
      'warehouseId': idBodega,
      'financialArticleId': financialArticleId,
      'counterUserId': counterUserId,
      'countNumber': countNumber,
      'barcode': barcode,
      'countedQuantity': countedQuantity,
      'countDate': countDate.toIso8601String(),
      'syncDate': fechaSincronizacion?.toIso8601String(),
      'status': estado,
      'isSynced': isSynced,
    };
  }

  factory CountRecordModel.fromMap(Map<String, dynamic> map) {
    return CountRecordModel(
      localId: map['localId']?.toString(), // En caso de que sql lo devuelva numérico
      physicalCountId: map['physicalCountId']?.toString() ?? '',
      idBodega: (map['warehouseId'] ?? map['idBodega'])?.toString() ?? '',
      financialArticleId: map['financialArticleId']?.toString() ?? '',
      counterUserId: map['counterUserId']?.toString() ?? '',
      countNumber: (map['countNumber'] as num?)?.toInt() ?? 1,
      barcode: map['barcode']?.toString() ?? '',
      countedQuantity: (map['countedQuantity'] as num?)?.toDouble() ?? 0.0,
      countDate: DateTime.parse(map['countDate'].toString()),
      fechaSincronizacion: (map['syncDate'] ?? map['fechaSincronizacion']) != null 
          ? DateTime.parse((map['syncDate'] ?? map['fechaSincronizacion']).toString()) 
          : null,
      estado: map['status']?.toString() ?? map['estado']?.toString() ?? '',
      isSynced: map['isSynced']?.toString() ?? 'N',
    );
  }

  /// Convierte al formato JSON exacto estandarizado (camelCase) para el backend Spring Boot.
  Map<String, dynamic> toJsonApi() {
    return {
      'idConteoFisico': physicalCountId,
      'idBodega': idBodega,
      'idArticuloSistemaFinanciero': financialArticleId,
      'idUsuarioContador': counterUserId,
      'numeroDeConteo': countNumber,
      'codigoBarras': barcode,
      'cantidadContada': countedQuantity,
      'fechaConteo': countDate.toIso8601String(),
      'fechaSincronizacion': fechaSincronizacion?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'estado': estado,
      'sincronizado': isSynced,
    };
  }
}
