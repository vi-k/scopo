import 'manifest.dart';

/// The blocks of the `base` topic.
const baseTopic = DocManifest(
  'doc/base.md',
  support: _support,
  {
    'the-widget/ScopeInheritedWidget': DocEnvironment.skip(
      'API signature excerpt: child omits the private placeholder default.',
    ),
    'the-element/ScopeInheritedElement': DocEnvironment('', ''),
    'finding-a-scope/scopecontext-maybeof-w-c-conte': DocEnvironment(
      'void example<W extends ScopeInheritedWidget, '
          'C extends ScopeContext<W>, V>(BuildContext context, '
          'V Function(C) selector) {',
      '}',
    ),
    'finding-a-scope/final-config-scopewidgetbase-o': _body,
    'listen-and-what-it-costs/onpressed-scopemodel-of-cart-c': DocEnvironment(
      'void example(BuildContext context) {\nTextButton(',
      'child: const Text("Clear"),\n);\n}',
    ),
    'what-select-actually-does/final-username-scopemodel-sele': _body,
    'accessors-and-editor-templates/App': DocEnvironment(_appSupport, ''),
  },
);

const _body = DocEnvironment('void example(BuildContext context) {', '}');
const _support = '''
import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

final class ApiConfig extends ScopeWidgetBase<ApiConfig> {
  const ApiConfig({super.key});
  String get apiKey => 'key';
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class Cart {
  void clear() {}
}

class Session {
  String get userName => 'Ada';
}
''';

const _appSupport = '''
class AppDependencies implements ScopeDependencies {
  @override
  void onUnmount() {}
  @override
  void dispose() {}
}

final class AppState extends ScopeState<App, AppDependencies, AppState> {
  int get counter => 0;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

late BuildContext context;
''';
