class Analytics {
  const Analytics();

  Future<void> init() async {
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  Future<void> dispose() async {
    //
  }
}
