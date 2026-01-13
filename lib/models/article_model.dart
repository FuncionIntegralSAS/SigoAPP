import 'dart:convert';

// Modelo de datos para representar un Activo o Artículo.
class ArticleModel {
  final String id;
  final String name;
  final String licensePlate; 
  final String warehouse; // Cambiado de costCenterId a warehouse para consistencia
  final String? responsible; 
  final double? latitude;
  final double? longitude;

  ArticleModel({
    required this.id,
    required this.name,
    required this.licensePlate,
    required this.warehouse,
    this.responsible,
    this.latitude,
    this.longitude,
  });

  // Método para crear una copia del objeto
  ArticleModel copyWith({
    String? id,
    String? name,
    String? licensePlate,
    String? warehouse,
    String? responsible,
    double? latitude,
    double? longitude,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      licensePlate: licensePlate ?? this.licensePlate,
      warehouse: warehouse ?? this.warehouse,
      responsible: responsible ?? this.responsible,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // Genera la cadena JSON para el QR usando el campo 'warehouse'
  String get qrData {
    final Map<String, dynamic> data = {
      'id': id,
      'name': name,
      'placa': licensePlate,
      'wh': warehouse,
      if (responsible != null) 'resp': responsible,
      if (latitude != null) 'lat': latitude,
      if (longitude != null) 'lon': longitude,
    };
    return json.encode(data);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArticleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}