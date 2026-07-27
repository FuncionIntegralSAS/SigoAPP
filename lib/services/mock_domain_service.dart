class MockDomainService {
  /// Simula la consulta al directorio para obtener la URL base 
  /// correspondiente a una llave de cliente extraída de un código QR.
  Future<String> getBaseUrlFromKey(String clientKey) async {
    // Simulamos latencia de red
    await Future.delayed(const Duration(seconds: 1));
    
    if (clientKey.isEmpty) {
      throw Exception('La llave escaneada está vacía.');
    }
    
    // Para cualquier llave válida, devolvemos la URL mock de desarrollo
    // según lo especificado: http://localhost:8082
    return 'http://localhost:8082';
  }
}
