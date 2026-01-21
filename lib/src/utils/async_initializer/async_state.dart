import 'package:flutter/widgets.dart';

import 'async_initializer_mixin.dart';

abstract base class AsyncState<T extends StatefulWidget> extends State<T>
    with AsyncInitializerMixin {
  @override
  void initState() {
    super.initState();
    initInitializer(); // ignore: discarded_futures
  }

  @override
  void dispose() {
    disposeInitializer(); // ignore: discarded_futures
    super.dispose();
  }

  @override
  Future<void> onInit();

  @override
  Future<void> onDispose();
}
