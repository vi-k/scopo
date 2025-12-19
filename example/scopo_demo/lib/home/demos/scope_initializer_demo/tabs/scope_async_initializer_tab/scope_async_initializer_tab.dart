import 'package:flutter/material.dart';

import 'examples/scope_async_initializer_example.dart';

class ScopeAsyncInitializerTab extends StatefulWidget {
  const ScopeAsyncInitializerTab({super.key});

  @override
  State<ScopeAsyncInitializerTab> createState() =>
      _ScopeAsyncInitializerTabState();
}

class _ScopeAsyncInitializerTabState extends State<ScopeAsyncInitializerTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView(
      padding: const EdgeInsets.all(8),
      children: const [ScopeAsyncInitializerExample(), SizedBox(height: 32)],
    );
  }
}
