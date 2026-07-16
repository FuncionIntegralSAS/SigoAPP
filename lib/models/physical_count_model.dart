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
      'fecha': fecha.toIso8601String().split(
        '.',
      )[0], // Formato: YYYY-MM-DDTHH:mm:ss
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

class AsignacionConteoRequest extends Equatable {
  final String empresa;
  final String bodega;
  final DateTime fechaConteo;
  final List<UsuarioAsignacion> usuarios;

  const AsignacionConteoRequest({
    required this.empresa,
    required this.bodega,
    required this.fechaConteo,
    required this.usuarios,
  });

  Map<String, dynamic> toJson() {
    return {
      'empresa': empresa,
      'bodega': bodega,
      'fechaConteo': fechaConteo.toUtc().toIso8601String(),
      'usuarios': usuarios.map((u) => u.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [empresa, bodega, fechaConteo, usuarios];
}

class UsuarioAsignacion extends Equatable {
  final String documento;
  final String nombre;
  final String email;

  const UsuarioAsignacion({
    required this.documento,
    required this.nombre,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {'documento': documento, 'nombre': nombre, 'email': email};
  }

  @override
  List<Object?> get props => [documento, nombre, email];
}

class PendienteArticuloResponse extends Equatable {
  final int numeroConteo;
  final String? codigoQr;
  final double cantidadContada;
  final String? estado;
  final String? idBodega;
  final int idArticulo;
  final int? idUsuario;

  // Sugerencias de campos complementarios para el backend
  final String? nombreArticulo;

  const PendienteArticuloResponse({
    required this.numeroConteo,
    this.codigoQr,
    required this.cantidadContada,
    this.estado,
    this.idBodega,
    required this.idArticulo,
    this.idUsuario,
    this.nombreArticulo,
  });

  factory PendienteArticuloResponse.fromJson(Map<String, dynamic> json) {
    return PendienteArticuloResponse(
      numeroConteo: json['numeroConteo'] ?? 0,
      codigoQr: json['codigoQr'] as String?,
      cantidadContada: (json['cantidadContada'] as num?)?.toDouble() ?? 0.0,
      estado: json['estado'] as String?,
      idBodega: json['idBodega'] as String?,
      idArticulo: json['idArticulo'] ?? 0,
      idUsuario: json['idUsuario'] as int?,
      nombreArticulo: json['nombreArticulo'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    numeroConteo,
    codigoQr,
    cantidadContada,
    estado,
    idBodega,
    idArticulo,
    idUsuario,
    nombreArticulo,
  ];

  get descripcion => null;
}
