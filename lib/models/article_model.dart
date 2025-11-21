// Modelo de datos para un Artículo o Activo
class ArticleModel {
  final String id;
  final String licensePlate; // Placa
  final String name;
  final String? responsible; // Responsable
  final String warehouse; // Centro de Costos / Bodega ID
  // PROPIEDADES DE GEOLOCALIZACIÓN
  final double? latitude;
  final double? longitude;

  ArticleModel({
    required this.id,
    required this.licensePlate,
    required this.name,
    required this.warehouse,
    this.responsible,
    this.latitude,
    this.longitude,
  });

  // Método que genera la cadena que se codificará en el QR
  // Usamos el código, la placa y AHORA la ubicación como datos de trazabilidad
  String get qrData {
    return 'Código:$id|Placa:$licensePlate|CC:$warehouse';
  }

  // Opcional: Para poder imprimir el objeto en la consola
  @override
  String toString() {
    return 'ArticleModel(Code: $id, Plate: $licensePlate, Name: $name)';
  }

  // MÉTODO copyWith ACTUALIZADO para recibir CUALQUIER campo
  ArticleModel copyWith({
    String? code,
    String? licensePlate,
    String? name,
    String? responsible,
    String? warehouse,
    double? latitude,
    double? longitude,
  }) {
    return ArticleModel(
      id: code ?? id,
      warehouse: warehouse ?? this.warehouse,
      licensePlate: licensePlate ?? this.licensePlate,
      name: name ?? this.name,
      responsible: responsible ?? this.responsible,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
  
  // Dos ArticleModel se consideran iguales si su 'id' y 'warehouse' coinciden.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArticleModel &&
        other.id == id &&
        other.warehouse == warehouse;
  }

  @override
  int get hashCode => id.hashCode ^ warehouse.hashCode;
}