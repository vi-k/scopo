import 'package:flutter/material.dart';

import 'scope_model_example1.dart';
import 'scope_model_example2.dart';
import 'scope_model_example3.dart';

class ScopeModelDemo extends StatelessWidget {
  const ScopeModelDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(child: ScopeModelExample1()),
        Divider(),
        Expanded(child: ScopeModelExample2()),
        Divider(),
        Expanded(child: ScopeModelExample3()),
      ],
    );
  }
}
