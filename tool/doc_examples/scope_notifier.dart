import 'manifest.dart';

/// The blocks of the `ScopeNotifier` topic.
const scopeNotifier = DocManifest(
  'doc/scope_notifier.md',
  support: _support,
  {
    'scopenotifier/scopenotifier-counter': DocEnvironment(
      'class CounterText extends StatelessWidget {\n'
          'const CounterText({super.key});\n'
          '@override\nWidget build(BuildContext context) => '
          'const SizedBox.shrink();\n}\nvoid example() {',
      '}',
    ),
    'scopenotifier/CounterText': DocEnvironment('', ''),
    'the-whole-difference/init': DocEnvironment(
      'abstract base class CounterElement<W extends '
          'ScopeModelCore<W, E, Counter>, '
          'E extends ScopeNotifierElementBase<W, E, Counter>>\n'
          'extends ScopeModelElementBase<W, E, Counter> {\n'
          'CounterElement(super.widget);',
      '}',
    ),
    'swapping-the-model/scopenotifier-value-value-curr': DocEnvironment.skip(
      'Schematic constructor call: builder: ... is an expression placeholder.',
    ),
    'state-models/PlayerState': DocEnvironment('', ''),
    'state-models/model': DocEnvironment(
      'void example(ScopeStateWithErrorNotifier<Player> model, '
          'Object failure, StackTrace stackTrace, Player recovered) {',
      '}',
    ),
  },
);

const _support = '''
import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

class Counter extends ChangeNotifier {
  int value = 0;
  void increment() {
    value++;
    notifyListeners();
  }
}

class Player {
  final int id;
  Player(this.id);
}
''';
