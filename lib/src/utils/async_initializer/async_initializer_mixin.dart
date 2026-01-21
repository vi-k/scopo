import 'dart:async';

import 'package:flutter/foundation.dart';

import '../lifecycle_coordinator/lifecycle_coordinator.dart';
import 'async_initializer_state.dart';

final _exclusiveCoordinators = <Object, LifecycleCoordinator<Object>>{};
LifecycleCoordinator<Object> exclusiveCoordinatorByKey(Object key) =>
    _exclusiveCoordinators[key] ??= LifecycleCoordinator<Object>();

final _disposeCoordinators = <Object, LifecycleCoordinator<Object>>{};
LifecycleCoordinator<Object> disposeCoordinatorByKey(Object key) =>
    _disposeCoordinators[key] ??= LifecycleCoordinator<Object>();

mixin AsyncInitializerMixin implements Listenable {
  LifecycleCoordinator<Object>? get exclusiveCoordinator => null;
  LifecycleCoordinator<Object>? get disposeCoordinator => null;

  final _initCompleter = Completer<void>();

  final ValueNotifier<AsyncInitializerState> _state =
      ValueNotifier<AsyncInitializerState>(const AsyncInitializerInitial());

  var _isClosed = false;

  AsyncInitializerState get state => _state.value;

  bool get isClosed => _isClosed;

  bool get isInitialized => _state is AsyncInitializerInitializedStates;

  bool get isDisposed => _state is AsyncInitializerDisposed;

  bool get hasError => _state is AsyncInitializerFailedStates;

  Object get error => switch (_state.value) {
        AsyncInitializerFailedStates(:final error) => error,
        AsyncInitializerSuccessStates() => throw StateError('No error'),
      };

  StackTrace get stackTrace => switch (_state.value) {
        AsyncInitializerSuccessStates() => throw StateError('No error'),
        AsyncInitializerFailedStates(:final stackTrace) => stackTrace,
      };

  @protected
  Future<void> onInit();

  @protected
  Future<void> onDispose();

  @override
  void addListener(VoidCallback listener) {
    _state.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _state.removeListener(listener);
  }

  @protected
  Future<void> initInitializer() async {
    assert(_state.value is AsyncInitializerInitial);

    if (exclusiveCoordinator case final exclusiveCoordinator?) {
      if (exclusiveCoordinator.isNotEmpty) {
        _state.value = const AsyncInitializerWaitingForInitialization();
      }
      await exclusiveCoordinator.acquire(this);
    }

    try {
      _state.value = const AsyncInitializerInitializing();
      await onInit();
      _state.value = const AsyncInitializerInitialized();
    } on Object catch (error, stackTrace) {
      _state.value = AsyncInitializerInitializationFailed(error, stackTrace);
    } finally {
      _initCompleter.complete();
    }
  }

  @protected
  Future<void> disposeInitializer() async {
    _isClosed = true;

    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }

    final disposeCoordinator = this.disposeCoordinator;

    try {
      if (_state.value case AsyncInitializerInitialized()) {
        if (disposeCoordinator != null) {
          if (disposeCoordinator.isNotEmpty) {
            _state.value = const AsyncInitializerWaitingForDisposal();
          }
          await disposeCoordinator.acquire(this);
        }

        _state.value = const AsyncInitializerDisposing();
        await onDispose();
        _state.value = const AsyncInitializerDisposed();
      }
    } on Object catch (e, s) {
      _state.value = AsyncInitializerDisposalFailed(e, s);
    } finally {
      _state.dispose();

      if (disposeCoordinator != null) {
        disposeCoordinator.release(this);

        // Если это был внутренний координатор и очередь на его захват пуста,
        // удаляем его из списка.
        if (disposeCoordinator.isEmpty) {
          Object? disposeCoordinatorKey;

          for (final e in _disposeCoordinators.entries) {
            if (identical(e.value, disposeCoordinator)) {
              disposeCoordinatorKey = e.key;
              break;
            }
          }

          if (disposeCoordinatorKey != null) {
            _disposeCoordinators.remove(disposeCoordinatorKey);
          }
        }
      }

      if (exclusiveCoordinator case final exclusiveCoordinator?) {
        exclusiveCoordinator.release(this);

        // Если это был внутренний координатор и очередь на его захват пуста,
        // удаляем его из списка.
        if (exclusiveCoordinator.isEmpty) {
          Object? exclusiveCoordinatorKey;

          for (final e in _exclusiveCoordinators.entries) {
            if (identical(e.value, exclusiveCoordinator)) {
              exclusiveCoordinatorKey = e.key;
              break;
            }
          }

          if (exclusiveCoordinatorKey != null) {
            _exclusiveCoordinators.remove(exclusiveCoordinatorKey);
          }
        }
      }
    }
  }
}
