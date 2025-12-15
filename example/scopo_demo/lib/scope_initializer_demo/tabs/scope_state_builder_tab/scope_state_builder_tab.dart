import 'package:flutter/material.dart';

import 'examples/example.dart';

class ScopeStateBuilderTab extends StatefulWidget {
  const ScopeStateBuilderTab({super.key});

  @override
  State<ScopeStateBuilderTab> createState() => _ScopeStateBuilderTabState();
}

class _ScopeStateBuilderTabState extends State<ScopeStateBuilderTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView(
      padding: const EdgeInsets.all(8),
      children: const [
        ScopeStateBuilderExample(),
        SizedBox(height: 32),
      ],
    );
  }
}
