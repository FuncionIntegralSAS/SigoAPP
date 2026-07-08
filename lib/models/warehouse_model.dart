import 'package:equatable/equatable.dart';

// Modelo de datos para una Bodega o Centro de Costos
class WarehouseModel extends Equatable {
  final String bodeCodi; // ID que se usará para filtrar los artículos
  final String bodeDesc;
  final String bodeEsta;

  const WarehouseModel({
    required this.bodeCodi,
    required this.bodeDesc,
    required this.bodeEsta,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      bodeCodi: json['bodeCodi']?.toString() ?? '',
      bodeDesc: json['bodeDesc'] ?? '',
      bodeEsta: json['bodeEsta'] ?? '',
    );
  }

  @override
  List<Object?> get props => [bodeCodi, bodeDesc, bodeEsta];
}
