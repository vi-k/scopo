class SomeController {
  Future<void> init() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  Future<void> dispose() async {
    //
  }
}
