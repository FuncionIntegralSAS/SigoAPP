import 'package:equatable/equatable.dart';

class CompanyModel extends Equatable {
  final String codigo;
  final String descripcion;
  final String nit;
  final String estado;

  const CompanyModel({
    required this.codigo,
    required this.descripcion,
    required this.nit,
    required this.estado,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      codigo: json['codigo'] as String,
      descripcion: json['descripcion'] as String,
      nit: json['nit'] as String,
      estado: json['estado'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'descripcion': descripcion,
      'nit': nit,
      'estado': estado,
    };
  }

  @override
  List<Object?> get props => [codigo, descripcion, nit, estado];
}
