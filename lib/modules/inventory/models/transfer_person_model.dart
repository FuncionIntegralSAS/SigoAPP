import 'package:equatable/equatable.dart';

/// Modelo que representa un colaborador/responsable asociado a una bodega
/// obtenido del endpoint `GET /api/v1/traspasos/personas`.
class TransferPersonModel extends Equatable {
  final String cedula;
  final String nombre;
  final String apellido;

  const TransferPersonModel({
    required this.cedula,
    required this.nombre,
    required this.apellido,
  });

  /// Retorna el nombre completo concatenado y sin espacios sobrantes.
  String get nombreCompleto => '$nombre $apellido'.trim();

  factory TransferPersonModel.fromJson(Map<String, dynamic> json) {
    return TransferPersonModel(
      cedula: (json['cedula'] ?? json['persona'] ?? json['id'] ?? '').toString().trim(),
      nombre: (json['nombre'] ?? '').toString().trim(),
      apellido: (json['apellido'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'cedula': cedula,
        'nombre': nombre,
        'apellido': apellido,
      };

  @override
  List<Object?> get props => [cedula, nombre, apellido];

  @override
  String toString() => '$nombreCompleto ($cedula)';
}
