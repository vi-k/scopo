import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../scope_provider/scope_provider.dart';

abstract base class ScopeStateManagerBase<
    M extends ScopeStateManagerBase<M, S, T>,
    S extends ScopeStateManagerStateBase<M, S, T>,
    T extends Object> extends StatefulWidget {
  final Object? tag;
  final T initialState;

  const ScopeStateManagerBase({
    super.key,
    this.tag,
    required this.initialState,
  });

  Widget build(BuildContext context, T state);

  @override
  String toStringShort() =>
      '${objectRuntimeType(this, '${ScopeStateManagerBase<M, S, T>}')}'
      '${tag == null ? '' : '($tag)'}';
}

base class ScopeStateManagerStateBase<
    M extends ScopeStateManagerBase<M, S, T>,
    S extends ScopeStateManagerStateBase<M, S, T>,
    T extends Object> extends State<M> {
  late T _state;
  T get state => _state;
  set state(T value) {
    if (mounted) {
      setState(() {
        _state = value;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    return ScopeProvider<S>.value(
      value: this as S,
      builder: (context) => widget.build(context, state),
    );
  }

  @override
  String toStringShort() =>
      '${ScopeStateManagerStateBase<M, S, T>}(state: $_state)';
}
