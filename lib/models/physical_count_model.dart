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
    return {
      'documento': documento,
      'nombre': nombre,
      'email': email,
    };
  }

  @override
  List<Object?> get props => [documento, nombre, email];
}
