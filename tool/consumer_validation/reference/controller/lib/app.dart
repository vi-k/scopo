import 'dart:async';

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
    child: MaterialApp(home: _ResourceDesk(backend: backend)),
  );
}

final class _ResourceController extends ScopeController {
  _ResourceController(this.backend, this.id);

  final Backend backend;
  final String id;
  Resource? _resource;

  Resource get resource => _resource!;

  @override
  Future<void> init() async {
    // Keep the acquisition even if the scope left while open was pending.
    // The scope releases this controller when the late init returns.
    try {
      _resource = await backend.open(id);
    } on Object {
      // Nobody is left to show a failure that arrives after Leave.
      if (!mounted) return;
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    await _resource?.close();
  }
}

final class _ResourceDesk extends StatefulWidget {
  const _ResourceDesk({required this.backend});

  final Backend backend;

  @override
  State<_ResourceDesk> createState() => _ResourceDeskState();
}

final class _ResourceDeskState extends State<_ResourceDesk> {
  final _resourceSlot = Object();
  String? _selected;
  int _attempt = 0;

  void _open() {
    setState(() {
      _selected = 'a';
      _attempt++;
    });
  }

  void _leave() => setState(() => _selected = null);

  void _retry() => setState(() => _attempt++);

  void _switch() {
    setState(() {
      _selected = _selected == 'a' ? 'b' : 'a';
      _attempt++;
    });
  }

  /// Closing in place: the scope shows `closingBuilder` in place of its child,
  /// which goes first, and the future completes once the controller has been
  /// disposed. Only then does the desk go home.
  Future<void> _close(BuildContext scopeContext) async {
    await AsyncControllerScope.of<_ResourceController>(
      scopeContext,
      listen: false,
    ).close();
    if (!mounted) return;
    setState(() => _selected = null);
  }

  Widget _button(String name, String caption, VoidCallback action) =>
      TextButton(
        key: ValueKey<String>(name),
        onPressed: action,
        child: Text(caption),
      );

  Widget _loading(String id) => Column(
        key: const ValueKey<String>('loading'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Loading $id'),
          _button('leave', 'Leave', _leave),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final id = _selected;
    final Widget content;
    if (id == null) {
      content = Column(
        key: const ValueKey<String>('home'),
        mainAxisSize: MainAxisSize.min,
        children: [_button('open', 'Open', _open)],
      );
    } else {
      content = AsyncControllerScope<_ResourceController>(
        key: ValueKey<int>(_attempt),
        scopeKey: _resourceSlot,
        createController: (_) => _ResourceController(widget.backend, id),
        closingBuilder: (_) =>
            const Text('Closing', key: ValueKey<String>('closing')),
        waitingBuilder: (_) => _loading(id),
        progressBuilder: (_) => _loading(id),
        errorBuilder: (_, error, stackTrace) => Column(
          key: const ValueKey<String>('error'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Open failed $id'),
            Text('$error'),
            _button('retry', 'Retry', _retry),
            _button('leave', 'Leave', _leave),
          ],
        ),
        builder: (scopeContext, controller) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ResourceChild(resource: controller.resource),
            _button('leave', 'Leave', _leave),
            _button('switch', 'Switch', _switch),
            _button(
              'close',
              'Close',
              () => unawaited(_close(scopeContext)),
            ),
          ],
        ),
      );
    }
    return Scaffold(body: Center(child: content));
  }
}
