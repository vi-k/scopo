import 'package:flutter/material.dart';

import 'scope_state_builder_example1.dart';

class ScopeStateBuilderDemo extends StatelessWidget {
  const ScopeStateBuilderDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [Expanded(child: ScopeStateBuilderExample1())],
    );
  }
}
