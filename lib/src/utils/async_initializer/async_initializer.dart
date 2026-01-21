import 'async_initializer_mixin.dart';

abstract base class AsyncInitializer with AsyncInitializerMixin {
  AsyncInitializer() {
    initInitializer(); // ignore: discarded_futures
  }

  void dispose() {
    disposeInitializer(); // ignore: discarded_futures
  }

  @override
  Future<void> onInit();

  @override
  Future<void> onDispose();
}
