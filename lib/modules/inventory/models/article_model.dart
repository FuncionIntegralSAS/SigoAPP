import 'package:equatable/equatable.dart';

/// Modelo de datos para representar un Activo/Artículo del inventario.
/// Implementa [Equatable] para facilitar las comparaciones y pruebas unitarias.
class ArticleModel extends Equatable {
  final int? id; // PK de la base de datos (ACFIIDIN)
  final String codigoActivo; // Antiguo id, código comúnmente usado (ACFIARTI)
  final String nombre;
  final String placa;
  final String bodega; // ID de la bodega/centro de costos
  final String? responsable;
  final String? estado; // Estado del activo (Operativo, Dañado, etc.)

  // Ubicación GPS (opcional, se llena al generar el QR o al consultar)
  final double? latitud;
  final double? longitud;

  // ATRIBUTOS PARA REGISTRO ADICIONAL
  final String? comentarios; // Comentarios o notas adicionales
  final String? rutaFoto; // Ruta local de la fotografía en el dispositivo

  // ESTADO DE TRÁMITE Y COMPATIBILIDAD
  final bool enTramite;
  final String? centroInformacion;
  final String? tercero;

  const ArticleModel({
    this.id,
    required this.codigoActivo,
    required this.nombre,
    required this.placa,
    required this.bodega,
    this.responsable,
    this.latitud,
    this.longitud,
    this.estado,
    this.comentarios,
    this.rutaFoto,
    this.enTramite = false,
    this.centroInformacion,
    this.tercero,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      // PK numérica de la base de datos (ACFIIDIN). Exclusiva de json['id'].
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,

      // Código de negocio del activo (ACFIARTI).
      // Lee prioritariamente el nuevo contrato 'artiCodi' y mantiene fallbacks de otros módulos.
      codigoActivo:
          json['artiCodi']?.toString() ??
          json['codigoActivo']?.toString() ??
          json['activeCode']?.toString() ??
          '',

      // Descripción del activo.
      // Lee prioritariamente 'artiDesc' y mantiene compatibilidad con otros módulos.
      nombre:
          json['artiDesc']?.toString() ??
          json['nombre']?.toString() ??
          json['name']?.toString() ??
          '',

      // Placa del activo (ACFIPLAC).
      // Lee prioritariamente 'artiPlac' y mantiene compatibilidad con otros esquemas.
      placa:
          json['artiPlac']?.toString() ??
          json['acfiPlac']?.toString() ??
          json['placa']?.toString() ??
          '',
      bodega:
          json['bodeCodi']?.toString() ??
          json['codigoBodega']?.toString() ??
          json['warehouse']?.toString() ??
          json['bodega']?.toString() ??
          '',
      responsable:
          json['responsable']?.toString() ?? json['responsible']?.toString(),
      enTramite:
          json['enTramite'] == true ||
          json['enTramite'] == 1 ||
          json['enTramite']?.toString().toLowerCase() == 'true',
      centroInformacion: json['centroInformacion']?.toString().trim(),
      tercero: json['tercero']?.toString().trim(),
    );
  }

  /// Retorna los datos que se codificarán en el QR.
  /// NOTA: Por seguridad y optimización, los campos de comentarios, estado
  /// y ruta de foto NO se incluyen en el código QR.
  String get qrData {
    if (latitud != null && longitud != null) {
      final latStr = latitud!.toStringAsFixed(6);
      final lonStr = longitud!.toStringAsFixed(6);
      return 'Código:$codigoActivo|Placa:$placa|Nombre:$nombre|Lat:$latStr|Lon:$lonStr';
    }
    return 'Código:$codigoActivo|Placa:$placa|Nombre:$nombre';
  }

  /// Método para crear una copia del modelo con campos actualizados.
  ArticleModel copyWith({
    int? id,
    String? codigoActivo,
    String? nombre,
    String? placa,
    String? bodega,
    String? responsable,
    double? latitud,
    double? longitud,
    String? estado,
    String? comentarios,
    String? rutaFoto,
    bool? enTramite,
    String? centroInformacion,
    String? tercero,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      codigoActivo: codigoActivo ?? this.codigoActivo,
      nombre: nombre ?? this.nombre,
      placa: placa ?? this.placa,
      bodega: bodega ?? this.bodega,
      responsable: responsable ?? this.responsable,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      estado: estado ?? this.estado,
      comentarios: comentarios ?? this.comentarios,
      rutaFoto: rutaFoto ?? this.rutaFoto,
      enTramite: enTramite ?? this.enTramite,
      centroInformacion: centroInformacion ?? this.centroInformacion,
      tercero: tercero ?? this.tercero,
    );
  }

  @override
  List<Object?> get props => [
    id,
    codigoActivo,
    placa,
    bodega,
    enTramite,
    centroInformacion,
    tercero,
  ];
}
