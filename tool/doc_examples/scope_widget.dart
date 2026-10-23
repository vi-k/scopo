import 'manifest.dart';

/// The blocks of the `ScopeWidget` topic.
const scopeWidget = DocManifest(
  'doc/scope_widget.md',
  support: _support,
  {
    'scopewidgetbase/ApiConfig': DocEnvironment('', ''),
    'scopewidgetbase/scopewidgetbase-of-apiconfig-c': DocEnvironment(
      'final class ApiConfig extends ScopeWidgetBase<ApiConfig> {\n'
          'const ApiConfig({super.key});\n'
          'String get apiKey => "key";\n'
          '@override\nWidget build(BuildContext context) => '
          'const SizedBox.shrink();\n}\n'
          'void example(BuildContext context) {',
      '}',
    ),
    'the-pair-behind-every-family/MyScope': DocEnvironment('', ''),
    'notifydependents/init': DocEnvironment(
      'abstract base class CounterElement<W extends '
          'ScopeModelCore<W, E, ChangeNotifier>, '
          'E extends ScopeModelElementBase<W, E, ChangeNotifier>>\n'
          'extends ScopeModelElementBase<W, E, ChangeNotifier> {\n'
          'CounterElement(super.widget);',
      '}',
    ),
  },
);

const _support = '''
import 'package:flutter/widgets.dart';
import 'package:scopo/scopo.dart';
''';
