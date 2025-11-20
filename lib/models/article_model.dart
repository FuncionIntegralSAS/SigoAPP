// Modelo de datos para un Artículo o Activo
class ArticleModel {
  final String code;
  final String licensePlate; // Placa
  final String name;
  final String responsible; // Responsable
  final String costCenter; // Centro de Costos / Bodega ID
  // PROPIEDADES DE GEOLOCALIZACIÓN
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
  // Usamos el código, la placa y AHORA la ubicación como datos de trazabilidad
  String get qrData {
    // Incluir la ubicación en el QR para trazabilidad.
    final lat = latitude?.toStringAsFixed(4) ?? 'N/A';
    final lon = longitude?.toStringAsFixed(4) ?? 'N/A';
    return 'Código:$code|Placa:$licensePlate|CC:$costCenter|Lat:$lat|Lon:$lon';
  }

  // Opcional: Para poder imprimir el objeto en la consola
  @override
  String toString() {
    return 'ArticleModel(Code: $code, Plate: $licensePlate, Name: $name)';
  }

  // MÉTODO copyWith ACTUALIZADO para recibir CUALQUIER campo
  ArticleModel copyWith({
    String? code,
    String? licensePlate,
    String? name,
    String? responsible,
    String? costCenter,
    double? latitude,
    double? longitude,
  }) {
    return ArticleModel(
      code: code ?? this.code,
      costCenter: costCenter ?? this.costCenter,
      licensePlate: licensePlate ?? this.licensePlate,
      name: name ?? this.name,
      responsible: responsible ?? this.responsible,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
  
  // FIX: Anulamos el operador == y hashCode. 
  // Ahora, dos ArticleModel se consideran iguales si su 'code' y 'costCenter' coinciden.
  // Esto resuelve el error del DropdownButtonFormField cuando el objeto se actualiza
  // con copyWith() en _getLocation().
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