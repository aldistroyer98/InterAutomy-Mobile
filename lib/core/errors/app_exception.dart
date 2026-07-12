sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class ValidationException extends AppException {
  const ValidationException(super.message);
}

final class NetworkException extends AppException {
  const NetworkException(super.message);
}

final class StorageException extends AppException {
  const StorageException(super.message);
}
