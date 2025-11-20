import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'scope_deps.dart';

part 'scope_config.dart';
part 'scope_content.dart';
part 'scope_deps_state.dart';
part 'scope_log.dart';

typedef ScopeInitFunction<P extends Object, D extends ScopeDeps>
    = Stream<ScopeInitState<P, D>> Function(BuildContext);

typedef ScopeOnInitCallback<P extends Object> = Widget Function(P? progress);

typedef ScopeOnErrorCallback = Widget Function(
    Object error, StackTrace stackTrace);

/// Scope.
///
/// Used to create a subtree in the widget tree that guarantees that all
/// necessary initialized dependencies for widgets will exist.
abstract base class Scope<S extends Scope<S, D, C>, D extends ScopeDeps,
    C extends ScopeContent<S, D, C>> extends StatefulWidget {
  final ScopeInitFunction<Object, D> _init;

  const Scope({super.key, required final ScopeInitFunction<Object, D> init})
      : _init = init;

  /// Quick access to parameters passed in scope.
  ///
  /// Returns [Scope].
  //
  // Insert the following code into your scope for more convenient use:
  //
  // ```dart
  // static $YourScope paramsOf(BuildContext context, {bool listen = true}) =>
  //     Scope.paramsOf<$YourScope, $YourScopeDeps, $YourScopeContent>(context, listen: listen);
  // ```
  static S paramsOf<S extends Scope<S, D, C>, D extends ScopeDeps,
              C extends ScopeContent<S, D, C>>(BuildContext context,
          {bool listen = true}) =>
      _Scope.maybeOf<S, D, C>(context, listen: listen)?.widget ??
      (throw Exception('$S not found in the context'));

  bool updateParamsShouldNotify(S oldWidget);

  /// Quick access to the scope.
  ///
  /// Returns [ScopeContent]. Dependencies are in [ScopeContent.deps].
  //
  // Insert the following code into your scope for more convenient use:
  //
  // ```dart
  // static $YourScopeContent of(BuildContext context) =>
  //     Scope.of<$YourScope, $YourScopeDeps, $YourScopeContent>(context);
  // ```
  static C of<S extends Scope<S, D, C>, D extends ScopeDeps,
          C extends ScopeContent<S, D, C>>(BuildContext context) =>
      maybeOf<S, D, C>(context) ??
      (throw Exception('$C not found in the context'));

  static C? maybeOf<S extends Scope<S, D, C>, D extends ScopeDeps,
          C extends ScopeContent<S, D, C>>(BuildContext context) =>
      _Scope.maybeOf<S, D, C>(
        context,
        listen: false,
      )?._contentKey.currentState;

  /// Метод для построения виджета прогресса инициализации.
  ///
  /// Чтобы не вносить тип прогресса в определение [Scope] и, соответственно,
  /// всех остальных виджетов, зависящих от него, тип прогресса сделан
  /// универсальным: [Object]. Т.е. может быть любым типом, кроме `null`.
  ///
  /// [!WARNING] `null` оставлен для первого запуска [Scope.onInit]
  /// и обязательно должен быть отработан как этап до начала инициализации.
  ///
  /// В функции инициализации тип указывается в описании класса
  /// [ScopeInitState]:
  ///
  /// ```dart
  /// Stream<ScopeInitState<double, MyDeps>> init(BuildContext context) {...}
  /// ```
  ///
  /// Но метод [onInit] не может автоматически принять этот тип. Необходимо
  /// самостоятельно конвертировать значение в нужный тип, не забывая про
  /// первый `null`:
  ///
  /// ```dart
  /// Widget onInit(Object? progress) =>
  ///     LinearProgressIndicator(value: value as double?)
  ///
  /// ```
  Widget onInit(Object? progress);

  /// Метод для построения виджета ошибки инициализации.
  Widget onError(Object error, StackTrace stackTrace);

  C createContent();

  Widget wrapContent(D deps, Widget child) => child;

  @override
  @nonVirtual
  State<S> createState() => _ScopeState<S, D, C>();

  @override
  String toStringShort() => objectRuntimeType(this, '${Scope<S, D, C>}');
}

base class _ScopeState<S extends Scope<S, D, C>, D extends ScopeDeps,
    C extends ScopeContent<S, D, C>> extends State<S> {
  final _contentKey = GlobalKey<C>();
  StreamSubscription<void>? _subscription;
  _ScopeDepsState<Object, D> _state = _ScopeInitial();

  @override
  void initState() {
    super.initState();

    _subscription = widget._init(context).listen(
      (state) {
        switch (state) {
          case ScopeProgress(:final value):
            _debug('$S.init', value);

          case ScopeReady():
            _unsubscribe();
            _debug('$S.init', '$D is ready');
        }

        setState(() {
          _state = state;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        _unsubscribe();

        _debugError(
          '$S.init',
          'failed',
          error: error,
          stackTrace: stackTrace,
        );

        setState(() {
          _state = _ScopeError(error, stackTrace);
        });
      },
      onDone: () {
        _debug('$S.init', 'done');
      },
    );
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();

    if (_state case ScopeReady(:final deps)) {
      _debug('$S.dispose', 'start');
      deps.dispose().then((_) {
        _debug('$S.dispose', 'done');
      });
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext _) {
    return _Scope<S, D, C>(
      scopeState: this,
      child: switch (_state) {
        _ScopeInitial(:final value) ||
        ScopeProgress(:final Object? value) =>
          widget.onInit(value),
        _ScopeError(:final error, :final stackTrace) => widget.onError(
            error,
            stackTrace,
          ),
        ScopeReady(:final deps) => widget.wrapContent(
            deps,
            _ScopeContent<S, D, C>(
              key: _contentKey,
              deps: deps,
              createContent: widget.createContent,
            ),
          ),
      },
    );
  }

  @override
  String toStringShort() => '${_ScopeState<S, D, C>}(_state: $_state)';
}

class _Scope<S extends Scope<S, D, C>, D extends ScopeDeps,
    C extends ScopeContent<S, D, C>> extends InheritedWidget {
  final _ScopeState<S, D, C> scopeState;
  final S scope;

  _Scope({super.key, required this.scopeState, required super.child})
      : scope = scopeState.widget;

  static _ScopeState<S, D, C>? maybeOf<
              S extends Scope<S, D, C>,
              D extends ScopeDeps,
              C extends ScopeContent<S, D, C>>(BuildContext context,
          {required bool listen}) =>
      listen
          ? context
              .dependOnInheritedWidgetOfExactType<_Scope<S, D, C>>()
              ?.scopeState
          : context
              .getInheritedWidgetOfExactType<_Scope<S, D, C>>()
              ?.scopeState;

  @override
  bool updateShouldNotify(_Scope<S, D, C> oldWidget) =>
      scope.updateParamsShouldNotify(oldWidget.scope);

  @override
  String toStringShort() => '${_Scope<S, D, C>}';
}
