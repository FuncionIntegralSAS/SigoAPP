import 'package:equatable/equatable.dart';

// Modelo de datos para una Bodega o Centro de Costos
class WarehouseModel extends Equatable {
  final String codigoBodega; // ID que se usará para filtrar los artículos
  final String descripcionBodega;
  final String estadoBodega;
  final String? tipo; // Tipo de bodega: PE (Personal), FI (Física), etc.

  const WarehouseModel({
    required this.codigoBodega,
    required this.descripcionBodega,
    required this.estadoBodega,
    this.tipo,
  });

  /// Indica si la bodega es de tipo personal [PE] o no tiene tipo especificado.
  bool get isPersonal => tipo == null || tipo!.trim().toUpperCase() == 'PE';

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      codigoBodega: json['bodeCodi']?.toString() ?? json['codigoBodega']?.toString() ?? json['code']?.toString() ?? '',
      descripcionBodega: json['bodeDesc']?.toString() ?? json['descripcionBodega']?.toString() ?? json['name']?.toString() ?? '',
      estadoBodega: json['bodeEsta']?.toString() ?? json['estadoBodega']?.toString() ?? json['state']?.toString() ?? '',
      tipo: json['bodeTipo']?.toString() ?? json['tipoBodega']?.toString() ?? json['tipo']?.toString() ?? json['bode_tipo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'codigoBodega': codigoBodega,
    'descripcionBodega': descripcionBodega,
    'estadoBodega': estadoBodega,
    if (tipo != null) 'tipo': tipo,
  };

  @override
  List<Object?> get props => [codigoBodega, descripcionBodega, estadoBodega, tipo];
}
