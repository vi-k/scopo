import 'manifest.dart';

/// The blocks of the `AsyncControllerScope` topic.
const asyncControllerScope = DocManifest(
  'doc/async_controller_scope.md',
  support: _support,
  {
    'asynccontrollerscope/asynccontrollerscope-playercon': _widget,
    'asynccontrollerscope/Player': DocEnvironment(_controller, ''),
    'the-controller/PlayerController': DocEnvironment('', ''),
    'the-controller/final-controller-playercontrol':
        DocEnvironment('$_controller\nFuture<void> example() async {', '}'),
    'reading-the-controller-from-th/final-controller-asynccontroll': _widget,
    'reading-the-controller-from-th/final-position-asynccontroller':
        DocEnvironment(
      '$_controller\n$_player}\nvoid example(BuildContext context) {',
      '}',
    ),
    // Two buildOnReady overrides in a row: the StreamBuilder, then the bridge.
    'following-what-the-controller-/buildOnReady': DocEnvironment(
      '$_controller\n$_player',
      '}',
      shared: true,
    ),
    'following-what-the-controller-/PlayerController': DocEnvironment('', ''),
    'following-what-the-controller-/final-title-playercontroller-s': _widget,
  },
);

const _widget = DocEnvironment(
  '$_controller\nvoid example(BuildContext context) {',
  '}',
);
const _player = 'abstract base class Player '
    'extends AsyncControllerScopeBase<Player, PlayerController> {';
const _controller = '''
final class PlayerController extends ScopeController with ChangeNotifier {
  PlayerController({required this.api});
  final Api api;
  Stream<Track> get tracks => const Stream.empty();
  String get title => '';
  int get position => 0;
  static V select<V>(BuildContext context,
      V Function(PlayerController controller) selector) =>
      ScopeNotifier.select<PlayerController, V>(context, selector);
}
''';
const _support = '''
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:scopo/scopo.dart';

class Track {
  String get title => '';
  int get position => 0;
}

class Session {
  Stream<Track> get tracks => const Stream.empty();
}

class Api {
  Future<Session> openSession() async => Session();
  Future<void> closeSession() async {}
}

class FakeApi extends Api {}

void _onTrack(Track track) {}

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class TrackTitle extends StatelessWidget {
  const TrackTitle({super.key, this.title});
  final String? title;
  @override
  Widget build(BuildContext context) => Text(title ?? '');
}
''';
