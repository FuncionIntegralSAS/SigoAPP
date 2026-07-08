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
    final code = json['codigo']?.toString() ?? json['id']?.toString() ?? '';
    return CompanyModel(
      codigo: code,
      descripcion: json['descripcion']?.toString() ?? json['name']?.toString() ?? '',
      nit: json['nit']?.toString() ?? code,
      estado: json['estado']?.toString() ?? code,
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
