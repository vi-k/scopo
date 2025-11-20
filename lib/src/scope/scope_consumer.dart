import 'package:flutter/widgets.dart';

import 'scope.dart';
import 'scope_deps.dart';

mixin ScopeConsumer<S extends Scope<S, D, C>, D extends ScopeDeps,
    C extends ScopeContent<S, D, C>> {
  C? _scope;
  C get scope => _scope ??= Scope.of<S, D, C>(context);

  BuildContext get context;
}
