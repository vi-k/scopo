import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import 'backend.dart';

Widget buildApp(Backend backend) {
  // Cancellation must retain ownership until an in-flight open completes.
  ScopeConfig.defaultInitCancellationTimeout = null;
  return AsyncScopeCoordinator(
    child: MaterialApp(
      title: 'Resource desk',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: _ResourceDesk(backend: backend),
    ),
  );
}

enum _View { home, resource, closing }

class _ResourceDesk extends StatefulWidget {
  const _ResourceDesk({required this.backend});

  final Backend backend;

  @override
  State<_ResourceDesk> createState() => _ResourceDeskState();
}

class _ResourceDeskState extends State<_ResourceDesk> {
  // This lane survives navigation and retries within this app instance.
  final _resourceLane = Object();
  _View _view = _View.home;
  String _selectedId = 'a';
  int _generation = 0;

  void _open() => setState(() {
        _selectedId = 'a';
        _generation++;
        _view = _View.resource;
      });

  void _leave() => setState(() => _view = _View.home);

  void _retry() => setState(() => _generation++);

  void _switch() => setState(() {
        _selectedId = _selectedId == 'a' ? 'b' : 'a';
        _generation++;
      });

  Future<void> _close() async {
    if (_view != _View.resource) return;
    setState(() => _view = _View.closing);
    // Finish the frame that unmounts ResourceChild and its owning scope.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await AsyncScopeCoordinator.waitForChildren(
      context,
      timeout: ScopeTimeout.none,
    );
    if (mounted) setState(() => _view = _View.home);
  }

  Widget _button(String name, String label, VoidCallback onPressed) =>
      TextButton(
        key: ValueKey<String>(name),
        onPressed: onPressed,
        child: Text(label),
      );

  Widget _loading(String id) => Column(
        key: const ValueKey<String>('loading'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Loading $id'),
          _button('leave', 'Leave', _leave),
        ],
      );

  Widget _resource() {
    final id = _selectedId;
    return AsyncDataScope<Resource>(
      key: ValueKey<int>(_generation),
      scopeKey: _resourceLane,
      // Ownership must remain exclusive even when an operation takes a long time.
      scopeKeyTimeout: ScopeTimeout.none,
      disposeScopeTimeout: ScopeTimeout.none,
      waitForChildrenTimeout: ScopeTimeout.none,
      initData: (context, ctx) async {
        try {
          return await widget.backend.open(id);
        } on Object {
          // A failed open owns nothing. Accept cancellation after departure;
          // otherwise let the scope display the original acquisition error.
          ctx.check();
          rethrow;
        }
      },
      disposeData: (resource) => resource.close(),
      waitingBuilder: (context) => _loading(id),
      progressBuilder: (context, progress) => _loading(id),
      errorBuilder: (context, error, stackTrace, progress) => Column(
        key: const ValueKey<String>('error'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Open failed $id'),
          Text('$error'),
          _button('retry', 'Retry', _retry),
          _button('leave', 'Leave', _leave),
        ],
      ),
      builder: (context, resource) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResourceChild(resource: resource),
          _button('leave', 'Leave', _leave),
          _button('switch', 'Switch', _switch),
          _button('close', 'Close', _close),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Resource desk')),
        body: Center(
          child: switch (_view) {
            _View.home => Column(
                key: const ValueKey<String>('home'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Resource desk'),
                  _button('open', 'Open', _open),
                ],
              ),
            _View.resource => _resource(),
            _View.closing => const Text(
                'Closing',
                key: ValueKey<String>('closing'),
              ),
          },
        ),
      );
}
