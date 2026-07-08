import 'package:equatable/equatable.dart';

class PhysicalCountRequest extends Equatable {
  final String empresa;
  final String bodega; // Puede ser 'All' o ID específico
  final String? bodegaLogica;
  final DateTime fecha;
  final String articulo; // Puede ser 'All' o ID específico
  final bool verificarExistencia;

  const PhysicalCountRequest({
    required this.empresa,
    required this.bodega,
    this.bodegaLogica = '.',
    required this.fecha,
    required this.articulo,
    required this.verificarExistencia,
  });

  Map<String, dynamic> toJson() {
    return {
      'empresa': empresa,
      'bodega': bodega == 'All' ? '%' : bodega,
      if (bodegaLogica != null) 'bodegaLogica': bodegaLogica,
      'articulo': articulo == 'All' ? '%' : articulo,
      'fecha': fecha.toIso8601String().split('.')[0], // Formato: YYYY-MM-DDTHH:mm:ss
      'verificarExistencia': verificarExistencia ? 'S' : 'N',
    };
  }

  @override
  List<Object?> get props => [
    empresa,
    bodega,
    bodegaLogica,
    fecha,
    articulo,
    verificarExistencia,
  ];
}
