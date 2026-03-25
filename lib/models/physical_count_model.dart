import 'package:equatable/equatable.dart';

class PhysicalCountRequest extends Equatable {
  final String companyId;
  final String warehouseId; // Puede ser 'All' o ID específico
  final String? logicalWarehouseId;
  final DateTime date;
  final String articleId; // Puede ser 'All' o ID específico
  final bool verifyExistence;

  const PhysicalCountRequest({
    required this.companyId,
    required this.warehouseId,
    this.logicalWarehouseId,
    required this.date,
    required this.articleId,
    required this.verifyExistence,
  });

  Map<String, dynamic> toJson() {
    return {
      'empresa': companyId,
      'bodega': warehouseId == 'All' ? '%' : warehouseId,
      if (logicalWarehouseId != null) 'bodegaLogica': logicalWarehouseId,
      'articulo': articleId == 'All' ? '%' : articleId,
      'fecha': date.toIso8601String().split('.')[0], // Formato: YYYY-MM-DDTHH:mm:ss
      'verificarExistencia': verifyExistence ? 'S' : 'N',
    };
  }

  @override
  List<Object?> get props => [
    companyId,
    warehouseId,
    logicalWarehouseId,
    date,
    articleId,
    verifyExistence,
  ];
}
