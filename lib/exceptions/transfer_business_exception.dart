class TransferBusinessException implements Exception {
  final String message;

  TransferBusinessException(this.message);

  @override
  String toString() => message;
}