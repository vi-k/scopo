import 'dart:async';

import 'package:flutter/material.dart';

/// Navigation node.
final class NavigationNode extends StatefulWidget {
  final bool isRoot;
  final Widget child;
  final GlobalKey<NodeNavigatorState>? navigatorKey;

  const NavigationNode({
    super.key,
    this.navigatorKey,
    this.isRoot = false,
    required this.child,
  });

  @override
  State<NavigationNode> createState() => _NavigationNodeState();
}

final class _NavigationNodeState extends State<NavigationNode> {
  late final _navigatorKey =
      widget.navigatorKey ?? GlobalKey<NodeNavigatorState>();
  late final _observer = _NodeNavigatorObserver(this);

  @override
  Widget build(BuildContext context) => _NodeNavigator(
    key: _navigatorKey,
    node: this,
    pages: [MaterialPage<void>(child: widget.child)],
    onDidRemovePage: (route) {},
  );
}

final class _NodeNavigator extends Navigator {
  final _NavigationNodeState node;

  _NodeNavigator({
    super.key,
    required this.node,
    super.pages,
    super.onDidRemovePage,
  }) : super(observers: [node._observer]);

  @override
  NavigatorState createState() => NodeNavigatorState();
}

final class NodeNavigatorState extends NavigatorState {
  // For the future.
}

extension PreviousNavigatorExtension on NavigatorState {
  NavigatorState? get previous {
    NavigatorState? prevNavigator;

    if (context.mounted) {
      context.visitAncestorElements((element) {
        prevNavigator = Navigator.maybeOf(element);
        return false;
      });
    }

    return prevNavigator;
  }
}

final class _NodeNavigatorObserver extends NavigatorObserver {
  final _NavigationNodeState node;
  Route<void>? _firstRoute;

  _NodeNavigatorObserver(this.node);

  @override
  void didPush(Route<void> route, Route<void>? previousRoute) {
    if (_firstRoute == null) {
      _firstRoute = route;
      if (!node.widget.isRoot && route is ModalRoute<void>) {
        route.addLocalHistoryEntry(
          NavigationNodeFirstEntry(
            onRemove: () {
              scheduleMicrotask(() {
                navigator?.previous?.pop();
              });
            },
          ),
        );
      }
    }
  }
}

final class NavigationNodeFirstEntry extends LocalHistoryEntry {
  NavigationNodeFirstEntry({required super.onRemove});
}
