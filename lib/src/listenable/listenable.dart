import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'listen.dart';

/// A widget for building a widget subtree when an [aspect] of [Listenable]
/// changes.
///
/// See [ListenableListenToExtension.listenTo].
class ListenableAspectBuilder<L extends Listenable, T extends Object?>
    extends StatefulWidget {
  final L listenable;
  final T Function(L listenable) aspect;
  final bool Function(T previous, T current)? test;
  final Widget Function(
    BuildContext context,
    L listenable,
    T value,
    Widget? child,
  ) builder;
  final Widget? child;

  /// Creates a builder that responds to [aspect] changes in [listenable].
  const ListenableAspectBuilder({
    super.key,
    required this.listenable,
    required this.aspect,
    this.test,
    required this.builder,
    this.child,
  });

  @override
  State<ListenableAspectBuilder> createState() =>
      _ListenableAspectBuilderState<L, T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Listenable>('listenable', listenable));
  }
}

class _ListenableAspectBuilderState<L extends Listenable, T extends Object?>
    extends State<ListenableAspectBuilder<L, T>> {
  late ListenableToSubscription<T> _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(ListenableAspectBuilder<L, T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.listenable != oldWidget.listenable) {
      _subscription.cancel();
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = widget.listenable.listenTo(
      widget.aspect,
      (_, __) {
        if (!mounted) return;

        setState(() {});
      },
      test: widget.test,
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(
        context,
        widget.listenable,
        _subscription.value,
        widget.child,
      );
}
