import 'package:flutter/material.dart';

import 'examples/example.dart';

class ScopeStreamInitializerTab extends StatefulWidget {
  const ScopeStreamInitializerTab({super.key});

  @override
  State<ScopeStreamInitializerTab> createState() =>
      _ScopeStreamInitializerTabState();
}

class _ScopeStreamInitializerTabState extends State<ScopeStreamInitializerTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView(
      padding: const EdgeInsets.all(8),
      children: const [
        ScopeStreamInitializerExample(),
        SizedBox(height: 32),
      ],
    );
  }
}
