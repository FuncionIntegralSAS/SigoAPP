class GeolocationBusinessException implements Exception {
  final String message;
  final String? code;

  GeolocationBusinessException(this.message, {this.code});

  @override
  String toString() {
    if (code != null) {
      return 'GeolocationBusinessException: $code - $message';
    }
    return 'GeolocationBusinessException: $message';
  }
}
