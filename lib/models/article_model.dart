import 'package:equatable/equatable.dart';

/// Modelo de datos para representar un Activo/Artículo del inventario.
/// Implementa [Equatable] para facilitar las comparaciones y pruebas unitarias.
class ArticleModel extends Equatable {
  final String id;
  final String name;
  final String licensePlate;
  final String warehouse; // ID de la bodega/centro de costos
  final String? responsible;
  final String? status;    // Estado del activo (Operativo, Dañado, etc.)
  
  // Ubicación GPS (opcional, se llena al generar el QR)
  final double? latitude;
  final double? longitude;

  // ATRIBUTOS PARA REGISTRO ADICIONAL
  final String? comments;  // Comentarios o notas adicionales
  final String? photoPath; // Ruta local de la fotografía en el dispositivo

  const ArticleModel({
    required this.id,
    required this.name,
    required this.licensePlate,
    required this.warehouse,
    this.responsible,
    this.latitude,
    this.longitude,
    this.status,
    this.comments,
    this.photoPath,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['artiCodi']?.toString() ?? json['id']?.toString() ?? '',
      name: json['artiDesc']?.toString() ?? json['name']?.toString() ?? '',
      licensePlate: json['artiPlac']?.toString() ?? json['licensePlate']?.toString() ?? '',
      warehouse: json['bodeCodi']?.toString() ?? json['warehouse']?.toString() ?? '',
      responsible: json['responsable']?.toString() ?? json['responsible']?.toString(),
    );
  }

  /// Retorna los datos que se codificarán en el QR.
  /// NOTA: Por seguridad y optimización, los campos de comentarios, estado
  /// y ruta de foto NO se incluyen en el código QR.
  String get qrData {
    if (latitude != null && longitude != null) {
      final latStr = latitude!.toStringAsFixed(6);
      final lonStr = longitude!.toStringAsFixed(6);
      return 'Código:$id|Placa:$licensePlate|Nombre:$name|Lat:$latStr|Lon:$lonStr';
    }
    return 'Código:$id|Placa:$licensePlate|Nombre:$name';
  }

  /// Método para crear una copia del modelo con campos actualizados.
  ArticleModel copyWith({
    String? id,
    String? name,
    String? licensePlate,
    String? warehouse,
    String? responsible,
    double? latitude,
    double? longitude,
    String? status,
    String? comments,
    String? photoPath,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      licensePlate: licensePlate ?? this.licensePlate,
      warehouse: warehouse ?? this.warehouse,
      responsible: responsible ?? this.responsible,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      comments: comments ?? this.comments,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  @override
  List<Object?> get props => [id, warehouse];
}