import 'package:flutter/material.dart';

import 'examples/scope_example.dart';

class ScopeDemo extends StatefulWidget {
  const ScopeDemo({super.key});

  @override
  State<ScopeDemo> createState() => _ScopeDemoState();
}

class _ScopeDemoState extends State<ScopeDemo>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView(
      padding: const EdgeInsets.all(8),
      children: const [ScopeExample(), SizedBox(height: 32)],
    );
  }
}
