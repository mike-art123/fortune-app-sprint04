/// Exceptions are used only at infrastructure boundaries; application and
/// presentation layers consume [AppFailure] instead (doc 51 §23).
class AppException implements Exception {
  const AppException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException($message)';
}

class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

class ParsingException extends AppException {
  const ParsingException(super.message, {super.cause});
}
