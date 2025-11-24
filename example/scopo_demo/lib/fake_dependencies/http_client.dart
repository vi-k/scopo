class HttpClient {
  const HttpClient();

  Future<void> init() async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
  }

  Future<void> dispose() async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
  }
}
