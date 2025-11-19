import 'package:flutter/widgets.dart';

import 'scope.dart';
import 'scope_deps.dart';

mixin ScopeConsumer<S extends Scope<S, P, D, C>, P extends Object?,
    D extends ScopeDeps, C extends ScopeContent<S, P, D, C>> {
  C? _scope;
  C get scope => _scope ??= Scope.of<S, P, D, C>(context);

  BuildContext get context;
}
