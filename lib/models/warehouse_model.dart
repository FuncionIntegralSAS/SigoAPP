import 'package:equatable/equatable.dart';

// Modelo de datos para una Bodega o Centro de Costos
class WarehouseModel extends Equatable {
  final String codigoBodega; // ID que se usará para filtrar los artículos
  final String descripcionBodega;
  final String estadoBodega;

  const WarehouseModel({
    required this.codigoBodega,
    required this.descripcionBodega,
    required this.estadoBodega,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      codigoBodega: json['bodeCodi']?.toString() ?? json['codigoBodega']?.toString() ?? json['code']?.toString() ?? '',
      descripcionBodega: json['bodeDesc']?.toString() ?? json['descripcionBodega']?.toString() ?? json['name']?.toString() ?? '',
      estadoBodega: json['bodeEsta']?.toString() ?? json['estadoBodega']?.toString() ?? json['state']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [codigoBodega, descripcionBodega, estadoBodega];
}
