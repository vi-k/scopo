import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'scope_state_manager_base.dart';

abstract base class ScopeStateManager<M extends ScopeStateManager<M, T>,
        T extends Object>
    extends ScopeStateManagerBase<M, ScopeStateManagerState<M, T>, T> {
  const ScopeStateManager({
    super.key,
    super.tag,
    required super.initialState,
  });

  @override
  // ignore: no_logic_in_create_state
  State<M> createState() => ScopeStateManagerState<M, T>();

  @override
  String toStringShort() =>
      '${objectRuntimeType(this, '${ScopeStateManager<M, T>}')}'
      '${tag == null ? '' : '($tag)'}';
}

final class ScopeStateManagerState<M extends ScopeStateManager<M, T>,
        T extends Object>
    extends ScopeStateManagerStateBase<M, ScopeStateManagerState<M, T>, T> {
  @override
  String toStringShort() => '${ScopeStateManagerState<M, T>}(state: $state)';
}
