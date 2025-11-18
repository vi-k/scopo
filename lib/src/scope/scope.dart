import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'scope_deps.dart';
import 'scope_deps_state.dart';

part 'scope_config.dart';
part 'scope_content.dart';
part 'scope_log.dart';

typedef ScopeOnInitCallback<P extends Object?> = Widget Function(P progress);
typedef ScopeOnErrorCallback = Widget Function(
    Object error, StackTrace stackTrace);

/// Scope.
///
/// Used to create a subtree in the widget tree that guarantees that all
/// necessary initialized dependencies for widgets will exist.
///
/// The final result may look something like this:
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return AppScope(
///     init: AppScopeDeps.init,
///     initialization: (step) => SplashScreen(step),
///     initialized: () => HomeScreen(),
///   );
/// }
///
/// final class AppScopeDeps implements ScopeDeps {
///   final SomeController someController;
///
///   AppScopeDeps({
///     required this.someController,
///   });
///
///   static Stream<ScopeProgress<AppScopeDeps>> init(
///     BuildContext context,
///   ) async* {
///     SomeController? someController;
///     var isInitialized = false;
///
///     try {
///       yield ScopeInit('create $SomeController');
///       someController = SomeController();
///       await someController.init();
///
///       yield ScopeReady(
///         AppScopeDeps(
///           someController: someController,
///         ),
///       );
///
///       isInitialized = true;
///     } finally {
///       if (!isInitialized) {
///         someController?.dispose();
///       }
///     }
///   }
///
///   @override
///   Future<void> dispose() async {
///     await someController.dispose;
///   }
/// }
///
/// class HomeScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final someController = AppScope.of(context).someController;
///     ...
///   }
/// }
/// ```
abstract base class Scope<
    S extends Scope<S, P, D, C>,
    P extends Object?,
    D extends ScopeDeps,
    C extends ScopeContent<S, P, D, C>> extends StatefulWidget {
  final P initialStep;
  final Stream<ScopeInitState<P, D>> Function(BuildContext context) init;

  const Scope({super.key, required this.initialStep, required this.init});

  static C of<
          S extends Scope<S, P, D, C>,
          P extends Object?,
          D extends ScopeDeps,
          C extends ScopeContent<S, P, D, C>>(BuildContext context) =>
      maybeOf<S, P, D, C>(context) ??
      (throw Exception('$C not found in the context'));

  static C? maybeOf<
          S extends Scope<S, P, D, C>,
          P extends Object?,
          D extends ScopeDeps,
          C extends ScopeContent<S, P, D, C>>(BuildContext context) =>
      _Scope.maybeOf<S, P, D, C>(
        context,
        listen: false,
      )?._contentKey.currentState;

  /// Quick access to parameters passed in scope.
  ///
  /// Returns scope widget.
  //
  // Insert the following code into your scope for more convenient use:
  //
  // ```dart
  // static $YourScope of(BuildContext context, {bool listen = true}) =>
  //     Scope.paramsOf<$YourScope, $YourScopeDeps>(context, listen: listen);
  // ```
  static S paramsOf<
              S extends Scope<S, P, D, C>,
              P extends Object?,
              D extends ScopeDeps,
              C extends ScopeContent<S, P, D, C>>(BuildContext context,
          {bool listen = true}) =>
      _Scope.maybeOf<S, P, D, C>(context, listen: listen)?.widget ??
      (throw Exception('$S not found in the context'));

  bool updateParamsShouldNotify(S oldWidget);

  Widget onInit(P progress);

  Widget onError(Object error, StackTrace stackTrace);

  C createContent();

  Widget wrapContent(D deps, Widget child) => child;

  @override
  @nonVirtual
  State<S> createState() => _ScopeState<S, P, D, C>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(
      MessageProperty(
        'initialStep',
        '$initialStep',
        style: DiagnosticsTreeStyle.singleLine,
        level: DiagnosticLevel.info,
      ),
    );
  }

  @override
  String toStringShort() => objectRuntimeType(this, '${Scope<S, P, D, C>}');
}

base class _ScopeState<S extends Scope<S, P, D, C>, P extends Object?,
    D extends ScopeDeps, C extends ScopeContent<S, P, D, C>> extends State<S> {
  final _contentKey = GlobalKey<C>();
  late final StreamSubscription<void> _subscription;
  late ScopeDepsState<P, D> _state;

  @override
  void initState() {
    super.initState();

    _state = ScopeProgress(widget.initialStep);

    _subscription = widget.init(context).listen(
      (state) {
        switch (state) {
          case ScopeProgress<P, D>(:final value):
            _debug('$S.init', value);

          case ScopeReady<P, D>():
            _debug('$S.init', '$D is ready');
        }

        setState(() {
          _state = state;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        _debugError(
          '$S.init',
          'failed',
          error: error,
          stackTrace: stackTrace,
        );

        setState(() {
          _state = ScopeError(error, stackTrace);
        });
      },
      onDone: () {
        _debug('$S.init', 'done');
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
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
    return _Scope<S, P, D, C>(
      scopeState: this,
      child: switch (_state) {
        ScopeProgress(:final value) => widget.onInit(value),
        ScopeError(:final error, :final stackTrace) => widget.onError(
            error,
            stackTrace,
          ),
        ScopeReady(:final deps) => widget.wrapContent(
            deps,
            _ScopeContent<S, P, D, C>(
              key: _contentKey,
              deps: deps,
              createContent: widget.createContent,
            ),
          ),
      },
    );
  }

  @override
  String toStringShort() => '${_ScopeState<S, P, D, C>}(_state: $_state)';
}

class _Scope<
    S extends Scope<S, P, D, C>,
    P extends Object?,
    D extends ScopeDeps,
    C extends ScopeContent<S, P, D, C>> extends InheritedWidget {
  final _ScopeState<S, P, D, C> scopeState;
  final S scope;

  _Scope({super.key, required this.scopeState, required super.child})
      : scope = scopeState.widget;

  static _ScopeState<S, P, D, C>? maybeOf<
              S extends Scope<S, P, D, C>,
              P extends Object?,
              D extends ScopeDeps,
              C extends ScopeContent<S, P, D, C>>(BuildContext context,
          {required bool listen}) =>
      listen
          ? context
              .dependOnInheritedWidgetOfExactType<_Scope<S, P, D, C>>()
              ?.scopeState
          : context
              .getInheritedWidgetOfExactType<_Scope<S, P, D, C>>()
              ?.scopeState;

  @override
  bool updateShouldNotify(_Scope<S, P, D, C> oldWidget) =>
      scope.updateParamsShouldNotify(oldWidget.scope);

  @override
  String toStringShort() => '${_Scope<S, P, D, C>}';
}
