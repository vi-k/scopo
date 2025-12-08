final class FakeException {
  final String message;

  FakeException(this.message);

  @override
  String toString() => '$FakeException($message)';
}
