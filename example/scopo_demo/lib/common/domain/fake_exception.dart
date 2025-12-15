final class FakeException implements Exception {
  final String message;

  FakeException(this.message);

  @override
  String toString() => '$FakeException($message)';
}
