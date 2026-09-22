import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

import 'utils/settle.dart';

/// The recipe the `AsyncControllerScope` topic shows under "Following what the
/// controller hears".
///
/// The topic makes three promises about it, and each one is a test below: the
/// events reach the subtree, a widget is rebuilt only for the value it reads,
/// and the subscription is closed by a teardown that waits for it.
void main() {
  testWidgets('an event reaches the widget that reads it', (tester) async {
    final api = _Api();
    final builds = <String>[];

    await tester.pumpWidget(_host(api, builds));
    await settle(tester, until: () => builds.isNotEmpty);

    expect(builds, ['-'], reason: 'the ready branch, with nothing heard yet');

    api.emit(const _Track(title: 'one', position: 0));
    await tester.pumpAndSettle();

    expect(builds, ['-', 'one']);

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, until: () => api.closed);
  });

  testWidgets('a value the widget does not read does not rebuild it',
      (tester) async {
    final api = _Api();
    final builds = <String>[];

    await tester.pumpWidget(_host(api, builds));
    await settle(tester, until: () => builds.isNotEmpty);

    api.emit(const _Track(title: 'one', position: 0));
    await tester.pumpAndSettle();

    api.emit(const _Track(title: 'one', position: 5));
    await tester.pumpAndSettle();

    expect(
      builds,
      ['-', 'one'],
      reason: 'the position changed and the title did not, and the title is '
          'what this widget selected',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, until: () => api.closed);
  });

  testWidgets('the teardown waits for the subscription to be cancelled',
      (tester) async {
    final api = _Api();
    final builds = <String>[];

    await tester.pumpWidget(_host(api, builds));
    await settle(tester, until: () => builds.isNotEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, until: () => api.closed);

    expect(
      api.log,
      ['opened', 'unmount', 'cancelled', 'closed'],
      reason: 'onUnmount at once, then an awaited dispose in order',
    );
  });
}

Widget _host(_Api api, List<String> builds) => Directionality(
      textDirection: TextDirection.ltr,
      child: _Player(api: api, builds: builds),
    );

final class _Track {
  final String title;
  final int position;

  const _Track({required this.title, required this.position});
}

/// Stands for whatever the controller talks to.
final class _Api {
  final log = <String>[];
  final _tracks = StreamController<_Track>();
  bool closed = false;

  Stream<_Track> openSession() {
    log.add('opened');

    return _tracks.stream;
  }

  void emit(_Track track) => _tracks.add(track);

  Future<void> closeSession() async {
    log.add('closed');
    closed = true;
    await _tracks.close();
  }
}

final class _PlayerController extends ScopeController with ChangeNotifier {
  final _Api api;

  StreamSubscription<_Track>? _subscription;
  _Track? _track;

  _PlayerController(this.api);

  static V select<V>(
    BuildContext context,
    V Function(_PlayerController controller) selector,
  ) =>
      ScopeNotifier.select<_PlayerController, V>(context, selector);

  String get title => _track?.title ?? '-';

  int get position => _track?.position ?? 0;

  @override
  Future<void> init() async {
    final tracks = api.openSession();
    if (!mounted) {
      return;
    }

    _subscription = tracks.listen((track) {
      _track = track;
      notifyListeners();
    });
  }

  @override
  void onUnmount() {
    api.log.add('unmount');
    unawaited(_subscription?.cancel());
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    api.log.add('cancelled');
    await api.closeSession();
    super.dispose();
  }
}

final class _Player
    extends AsyncControllerScopeBase<_Player, _PlayerController> {
  final _Api api;
  final List<String> builds;

  const _Player({required this.api, required this.builds});

  @override
  _PlayerController createController(BuildContext context) =>
      _PlayerController(api);

  @override
  Widget buildOnProgress(BuildContext context) => const SizedBox.shrink();

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) =>
      const SizedBox.shrink();

  @override
  Widget buildOnReady(BuildContext context, _PlayerController controller) =>
      ScopeNotifier<_PlayerController>.value(
        value: controller,
        builder: (context) => _Title(builds: builds),
      );
}

final class _Title extends StatelessWidget {
  final List<String> builds;

  const _Title({required this.builds});

  @override
  Widget build(BuildContext context) {
    final title = _PlayerController.select(
      context,
      (controller) => controller.title,
    );
    builds.add(title);

    return const SizedBox.shrink();
  }
}
