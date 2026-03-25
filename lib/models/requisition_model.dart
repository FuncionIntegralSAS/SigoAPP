class RequisitionModel {
  final String id;
  final String articulo;
  final String solicita;
  final int cantidadSolicitada;
  final int cantidadAprobada;
  final int cantidadEntregada;
  final String estado;
  final String empresa;
  final String tipoDocumento;
  final String numero;
  final String fecha;
  final String bodega;
  final String unidad;
  final String observacion;

  RequisitionModel({
    required this.id,
    required this.articulo,
    required this.solicita,
    required this.cantidadSolicitada,
    required this.cantidadAprobada,
    required this.cantidadEntregada,
    required this.estado,
    required this.empresa,
    required this.tipoDocumento,
    required this.numero,
    required this.fecha,
    required this.bodega,
    required this.unidad,
    required this.observacion,
  });

  factory RequisitionModel.fromJson(Map<String, dynamic> json) {
    return RequisitionModel(
      id: json['id'] ?? '',
      articulo: json['articulo'] ?? '',
      solicita: json['solicita'] ?? '',
      cantidadSolicitada: json['cantidadSolicitada'] ?? 0,
      cantidadAprobada: json['cantidadAprobada'] ?? 0,
      cantidadEntregada: json['cantidadEntregada'] ?? 0,
      estado: json['estado'] ?? '',
      empresa: json['empresa'] ?? '',
      tipoDocumento: json['tipoDocumento'] ?? '',
      numero: json['numero'] ?? '',
      fecha: json['fecha'] ?? '',
      bodega: json['bodega'] ?? '',
      unidad: json['unidad'] ?? '',
      observacion: json['observacion'] ?? '',
    );
  }

  String get compositeId =>
      '${empresa}_${tipoDocumento}_${numero}_${bodega}_$articulo';
}
