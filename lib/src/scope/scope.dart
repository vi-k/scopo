import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'scope_deps.dart';

part 'scope_config.dart';
part 'scope_content.dart';
part 'scope_deps_state.dart';
part 'scope_log.dart';

typedef ScopeInitFunction<P extends Object, D extends ScopeDeps>
    = Stream<ScopeInitState<P, D>> Function();

typedef ScopeOnInitCallback<P extends Object> = Widget Function(P? progress);

typedef ScopeOnErrorCallback = Widget Function(
    Object error, StackTrace stackTrace);

/// The main widget that creates a scope.
///
/// It manages the lifecycle of dependencies (initialization, error handling,
/// disposal).
///
/// Used to create a subtree in the widget tree that guarantees that all
/// necessary initialized dependencies for widgets will exist.
abstract base class Scope<S extends Scope<S, D, C>, D extends ScopeDeps,
    C extends ScopeContent<S, D, C>> extends StatefulWidget {
  final Object? tag;
  final ScopeInitFunction<Object, D> _init;
  final Duration pauseAfterInitialization;

  const Scope({
    super.key,
    this.tag,
    required final ScopeInitFunction<Object, D> init,
    this.pauseAfterInitialization = Duration.zero,
  }) : _init = init;

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

  /// Method to check whether changes in parameters need to be notified to
  /// those who subscribed using `paramsOf(listened: true)`.
  bool updateParamsShouldNotify(S oldWidget);

  /// Quick access to the scope.
  ///
  /// Returns [ScopeContent]. Dependencies are in [ScopeContent.deps].
  //
  // Insert the following code into your scope for more convenient use:
  //
  // ```dart
  // static YourScopeContent of(BuildContext context) =>
  //     Scope.of<YourScope, YourScopeDeps, YourScopeContent>(context);
  // ```
  static C of<S extends Scope<S, D, C>, D extends ScopeDeps,
          C extends ScopeContent<S, D, C>>(BuildContext context) =>
      maybeOf<S, D, C>(context) ??
      (throw Exception('$C not found in the context'));

  /// Quick access to the scoop, if available.
  static C? maybeOf<S extends Scope<S, D, C>, D extends ScopeDeps,
          C extends ScopeContent<S, D, C>>(BuildContext context) =>
      _Scope.maybeOf<S, D, C>(context, listen: false)?._contentKey.currentState;

  /// Method for constructing a subtree during dependency initialization.
  ///
  /// To avoid specifying the progress type in the definition of [Scope] and
  /// [ScopeContent], the progress type is made universal: [Object]. That is,
  /// it can be any type except `null`.
  ///
  /// [!WARNING] `null` is left for the first run of [Scope.onInit] and must be
  /// handled as a step before initialization begins.
  ///
  /// In the initialization function, the type is specified in the
  /// [ScopeInitState] definition:
  ///
  /// ```dart
  /// Stream<ScopeInitState<double, MyFeatureDeps>> init(BuildContext context) {...}
  /// ```
  ///
  /// However, the [onInit] method cannot automatically accept this type. You
  /// must cast the value to the desired type yourself, remembering the first
  /// `null`:
  ///
  /// ```dart
  /// Widget onInit(Object? progress) =>
  ///     LinearProgressIndicator(value: value as double?)
  /// ```
  Widget onInit(Object? progress);

  /// Method for constructing a subtree in case of initialization error.
  Widget onError(Object error, StackTrace stackTrace);

  /// Method that should create your [ScopeContent].
  C createContent();

  /// Wraps [ScopeContent].
  Widget wrapContent(D deps, Widget child) => child;

  @override
  @nonVirtual
  @visibleForTesting
  State<S> createState() => _ScopeState<S, D, C>();

  @override
  String toStringShort() => '${objectRuntimeType(this, '${Scope<S, D, C>}')}'
      '${tag == null ? '' : '($tag)'}';
}

base class _ScopeState<S extends Scope<S, D, C>, D extends ScopeDeps,
    C extends ScopeContent<S, D, C>> extends State<S> {
  final _contentKey = GlobalKey<C>();
  StreamSubscription<void>? _subscription;
  _ScopeDepsState<Object, D> _state = _ScopeInitial();
  _ScopeDepsState<Object, D>? _pauseState;
  Completer<void>? _closeCompleter;

  String _method(String method) => '${widget.toStringShort()}.$method';

  @override
  void initState() {
    super.initState();

    String method() => _method('init');

    _subscription = widget._init().listen(
      (state) {
        switch (_state) {
          case _ScopeInitial<Object, D>():
          case ScopeProgress<Object, D>():
            break;

          case _ScopeError<Object, D>():
            throw StateError(
              'Initialization of $D has already ended with an error',
            );

          case ScopeReady<Object, D>():
            throw StateError('Initialization of $D has already ended');
        }

        switch (state) {
          case ScopeProgress(:final value):
            _debug(method, () => 'progress=$value');
            setState(() {
              _state = state;
            });

          case ScopeReady():
            _debug(method, '$D is ready');
            if (widget.pauseAfterInitialization.inMilliseconds == 0) {
              setState(() {
                _state = state;
              });
            } else {
              _pauseState = _state;
              _state = state;
              Timer(widget.pauseAfterInitialization, () {
                if (mounted) {
                  setState(() {
                    _pauseState = null;
                  });
                }
              });
            }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _unsubscribe();

        _debugError(
          method,
          'failed',
          error: error,
          stackTrace: stackTrace,
        );

        setState(() {
          _state = _ScopeError(error, stackTrace);
        });
      },
      onDone: () {
        _debug(method, 'done');
      },
    );
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _close() async {
    String method() => '${widget.toStringShort()}.close';

    if (_closeCompleter case final completer?) {
      return completer.future;
    }

    _debug(method, 'start');

    _unsubscribe();

    var completer = Completer();
    _closeCompleter = completer;
    if (mounted) {
      setState(() {});
    }

    if (_state case ScopeReady(:final deps)) {
      try {
        await deps.dispose();
      } on Object catch (e, s) {
        completer.completeError(e, s);
      }
    }

    if (!completer.isCompleted) {
      completer.complete();
    }

    _debug(method, 'done');

    return completer.future;
  }

  @override
  void dispose() {
    scheduleMicrotask(_close);
    super.dispose();
  }

  @override
  Widget build(BuildContext _) {
    return _Scope<S, D, C>(
      scopeState: this,
      child: switch (_pauseState ?? _state) {
        _ScopeInitial(:final value) ||
        ScopeProgress(:final Object? value) =>
          widget.onInit(value),
        _ScopeError(:final error, :final stackTrace) => widget.onError(
            error,
            stackTrace,
          ),
        ScopeReady(:final deps) => widget.wrapContent(
            deps,
            Stack(
              children: [
                _ScopeContent<S, D, C>(
                  key: _contentKey,
                  deps: deps,
                  createContent: widget.createContent,
                ),
                if (_closeCompleter != null)
                  Positioned.fill(
                    child: ColoredBox(
                      color:
                          Theme.of(context).canvasColor.withValues(alpha: 0.5),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
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
