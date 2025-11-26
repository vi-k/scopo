/// A container for dependencies (e.g., repositories, services).
abstract interface class ScopeDeps {
  Future<void> dispose();
}
