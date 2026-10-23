import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';
import 'backend.dart';

/// The backend promises no bound on how long it takes, and the task promises
/// one live resource and an awaited release all the same. Every default limit
/// of the package is three seconds, and an expired one gives up the wait it
/// bounds -- a second owner then overlaps the first -- so a solution removes
/// them. The README section `scopeKey` sets these before `runApp`; the tests
/// enter through [buildApp], so that is where they are set here.
void _removeTimeLimits() {
  ScopeConfig.defaultScopeKeyTimeout = null;
  ScopeConfig.defaultInitCancellationTimeout = null;
  ScopeConfig.defaultDisposeScopeTimeout = null;
  ScopeConfig.defaultWaitForChildrenTimeout = null;
}

Widget buildApp(Backend backend) {
  _removeTimeLimits();
  return AsyncScopeCoordinator(
    child: MaterialApp(home: _Desk(backend: backend)),
  );
}

final class _Desk extends StatefulWidget {
  const _Desk({required this.backend});
  final Backend backend;

  @override
  State<_Desk> createState() => _DeskState();
}

final class _DeskState extends State<_Desk> {
  final Object _ownership = Object();
  String? _id;
  int _attempt = 0;
  bool _closing = false;

  void _leave() => setState(() => _id = null);

  Future<void> _close() async {
    setState(() => _closing = true);
    // The frame removes the scope and its ordinary resource user first.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await AsyncScopeCoordinator.waitForChildren(context);
    if (!mounted) return;
    setState(() {
      _id = null;
      _closing = false;
    });
  }

  Widget _button(String key, String text, VoidCallback action) => TextButton(
        key: ValueKey(key),
        onPressed: action,
        child: Text(text),
      );

  Widget _loading(String id) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Loading $id', key: const ValueKey('loading')),
          _button('leave', 'Leave', _leave),
        ],
      );

  Widget _error(String id, Object error) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Open failed $id', key: const ValueKey('error')),
          Text('$error'),
          _button('retry', 'Retry', () => setState(() => _attempt++)),
          _button('leave', 'Leave', _leave),
        ],
      );

  Widget _ready(Resource resource) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResourceChild(resource: resource),
          _button('leave', 'Leave', _leave),
          _button('switch', 'Switch', () {
            setState(() {
              _id = _id == 'a' ? 'b' : 'a';
              _attempt++;
            });
          }),
          _button('close', 'Close', _close),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final id = _id;
    return Scaffold(
      body: Center(
        child: _closing
            ? const Text('Closing', key: ValueKey('closing'))
            : id == null
                ? Column(
                    key: const ValueKey('home'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _button('open', 'Open', () {
                        setState(() {
                          _id = 'a';
                          _attempt++;
                        });
                      }),
                    ],
                  )
                : AsyncDataScope<Resource>(
                    key: ValueKey((id, _attempt)),
                    scopeKey: _ownership,
                    initData: (context, ctx) async {
                      try {
                        return await widget.backend.open(id);
                      } on Object {
                        // A failure after Leave ends as the cancellation
                        // it followed; a current one shows the error.
                        ctx.check();
                        rethrow;
                      }
                    },
                    disposeData: (resource) => resource.close(),
                    progressBuilder: (context, progress) => _loading(id),
                    errorBuilder: (context, error, stack, progress) =>
                        _error(id, error),
                    builder: (context, resource) => _ready(resource),
                  ),
      ),
    );
  }
}
