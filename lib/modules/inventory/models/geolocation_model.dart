class GeolocationModel {
  final int idRegistro;
  final double latitud;
  final double longitud;
  final String? fechaCreacion;
  final String? usuarioCreacion;
  final String? fechaEdicion;
  final String? usuarioEdicion;

  const GeolocationModel({
    required this.idRegistro,
    required this.latitud,
    required this.longitud,
    this.fechaCreacion,
    this.usuarioCreacion,
    this.fechaEdicion,
    this.usuarioEdicion,
  });

  factory GeolocationModel.fromJson(Map<String, dynamic> json) {
    return GeolocationModel(
      idRegistro: (json['afgeIdre'] ?? json['idRegistro'] ?? 0) as int,
      latitud: ((json['afgeLati'] ?? json['latitud'] ?? 0) as num).toDouble(),
      longitud: ((json['afgeLong'] ?? json['longitud'] ?? 0) as num).toDouble(),
      fechaCreacion: (json['afgeFcre'] ?? json['fechaCreacion']) as String?,
      usuarioCreacion: (json['afgeUcre'] ?? json['usuarioCreacion']) as String?,
      fechaEdicion: (json['afgeFedi'] ?? json['fechaEdicion']) as String?,
      usuarioEdicion: (json['afgeUedi'] ?? json['usuarioEdicion']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'afgeIdre': idRegistro,
      'afgeLati': latitud,
      'afgeLong': longitud,
    };
  }
}
