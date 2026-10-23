import 'manifest.dart';

/// The blocks of the `LiteScope` topic.
const liteScope = DocManifest(
  'doc/lite_scope.md',
  support: _support,
  {
    'litescope/ScreenScope': DocEnvironment('', ''),
    'the-state/onUnmount': DocEnvironment(
      '$_screenScope\n'
      'final StreamSubscription<void> _subscription = '
      'const Stream<void>.empty().listen((_) {});\n'
      'final _connection = Connection();',
      _stateBuild,
    ),
    'two-initializations/TitleScope': DocEnvironment('', ''),
    'access-from-the-subtree/screenscope-of-context-control': _access,
    'close/await-screenscope-of-context-c': _access,
  },
);

const _access = DocEnvironment(
  '$_screenScope\n$_stateBuild\n'
      'Future<void> example(BuildContext context) async {',
  '}',
);
const _stateBuild = '@override\nWidget build(BuildContext context) => '
    'const SizedBox.shrink();\n}';
const _support = '''
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

class Connection {
  Future<void> close() async {}
}
''';
const _screenScope = '''
final class ScreenScope extends LiteScope<ScreenScope, ScreenScopeState> {
  const ScreenScope({super.key});
  @override
  Widget buildOnWaiting(BuildContext context) => const SizedBox.shrink();
  @override
  ScreenScopeState createState() => ScreenScopeState();
  static ScreenScopeState of(BuildContext context) =>
      LiteScope.of<ScreenScope, ScreenScopeState>(context);
}

final class ScreenScopeState
    extends LiteScopeState<ScreenScope, ScreenScopeState> {
  final controller = ScrollController();
  int get itemCount => 1;
''';
