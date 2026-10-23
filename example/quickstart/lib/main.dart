import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

void main() => runApp(const QuickstartApp());

class LocalResource {
  final int id;
  static final events = <String>[];

  LocalResource(this.id);

  static Future<LocalResource> open(int id) async {
    _record('opening $id');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _record('opened $id');
    return LocalResource(id);
  }

  Future<void> close() async {
    _record('closing $id');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _record('closed $id');
  }

  static void _record(String event) {
    events.add(event);
    debugPrint(event);
  }
}

class QuickstartApp extends StatefulWidget {
  const QuickstartApp({super.key});

  @override
  State<QuickstartApp> createState() => _QuickstartAppState();
}

class _QuickstartAppState extends State<QuickstartApp> {
  int _generation = 1;

  @override
  Widget build(BuildContext context) {
    final id = _generation;
    return AsyncScopeCoordinator(
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('scopo quickstart')),
          body: Center(
            child: AsyncDataScope<LocalResource>(
              key: ValueKey(id),
              // A new widget, but the same resource: wait for the old release.
              scopeKey: LocalResource,
              initData: (context, ctx) async {
                ctx.progress('Loading $id');
                return LocalResource.open(id);
              },
              disposeData: (resource) => resource.close(),
              progressBuilder: (context, progress) =>
                  Text(progress?.toString() ?? 'Waiting for previous resource'),
              errorBuilder: (context, error, stack, progress) => Text('$error'),
              builder: (context, resource) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ready ${resource.id}'),
                  ElevatedButton(
                    onPressed: () => setState(() => _generation++),
                    child: const Text('Recreate scope'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
