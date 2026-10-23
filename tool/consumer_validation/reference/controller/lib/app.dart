import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import 'backend.dart';

Widget buildApp(Backend backend) => AsyncScopeCoordinator(
      child: MaterialApp(home: _ResourceDesk(backend: backend)),
    );

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
    _resource = await backend.open(id);
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
  bool _closing = false;

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

  Future<void> _close() async {
    setState(() {
      _closing = true;
      _selected = null;
    });
    // Removing the scope unmounts its child before scopo starts release.
    // Wait until that removal happened before snapshotting the registry.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await AsyncScopeCoordinator.waitForChildren(context);
    if (!mounted) return;
    setState(() => _closing = false);
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
    if (_closing) {
      content = const Text('Closing', key: ValueKey<String>('closing'));
    } else if (id == null) {
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
        builder: (_, controller) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ResourceChild(resource: controller.resource),
            _button('leave', 'Leave', _leave),
            _button('switch', 'Switch', _switch),
            _button('close', 'Close', () => unawaited(_close())),
          ],
        ),
      );
    }
    return Scaffold(body: Center(child: content));
  }
}
