// Modelo de datos para un Artículo o Activo
class ArticleModel {
  final String code;
  final String licensePlate; // Placa
  final String name;
  final String responsible; // Responsable
  final String costCenter; // Centro de Costos / Bodega ID
  //PROPIEDADES DE GEOLOCALIZACIÓN
  final double? latitude;
  final double? longitude;

  ArticleModel({
    required this.code,
    required this.licensePlate,
    required this.name,
    required this.responsible,
    required this.costCenter,
    this.latitude,
    this.longitude,
  });

  
  // Método que genera la cadena que se codificará en el QR
  // Usamos el código y la placa como datos de identificación
  String get qrData {
    return 'Código:$code|Placa:$licensePlate|Nombre:$name';
  }
  
  // Opcional: Para poder imprimir el objeto en la consola
  @override
  String toString() {
    return 'ArticleModel(Code: $code, Plate: $licensePlate, Name: $name)';
  }

  // Método helper para crear una nueva instancia con una ubicación actualizada
  ArticleModel copyWith({
    double? latitude,
    double? longitude,
  }) {
    return ArticleModel(
      code: code,
      costCenter: costCenter,
      licensePlate: licensePlate,
      name: name,
      responsible: responsible,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // Si el código y el centro de costos coinciden, son el mismo activo.
@override
bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArticleModel &&
        other.code == code &&
        other.costCenter == costCenter;
}

@override
int get hashCode => code.hashCode ^ costCenter.hashCode;
}