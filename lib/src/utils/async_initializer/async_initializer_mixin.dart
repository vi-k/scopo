import 'dart:async';

import 'package:flutter/foundation.dart';

import '../exclusive_sequencer/exclusive_sequencer_old.dart';
import '../sequencers/sequencer.dart';
import 'async_initializer_state.dart';

mixin AsyncInitializerMixin implements Listenable {
  ExclusiveSequencerOld<Object>? get exclusiveSequencer => null;
  Sequencer? get disposeSequencer => null;

  final _initCompleter = Completer<void>();

  SequencerEntry? _disposeSequencerEntry;

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

    if (exclusiveSequencer case final exclusiveSequencer?) {
      if (exclusiveSequencer.isNotEmpty) {
        _state.value = const AsyncInitializerWaitingForInitialization();
      }
      await exclusiveSequencer.enter(this);
    }

    if (disposeSequencer case final disposeSequencer?) {
      _disposeSequencerEntry = disposeSequencer.enter();
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

    final disposeSequencerEntry = _disposeSequencerEntry;

    try {
      if (_state.value case AsyncInitializerInitialized()) {
        if (disposeSequencerEntry != null) {
          await disposeSequencerEntry.wait();
        }
        _state.value = const AsyncInitializerDisposing();
        await onDispose();
        _state.value = const AsyncInitializerDisposed();
      }
    } on Object catch (e, s) {
      _state.value = AsyncInitializerDisposalFailed(e, s);
    } finally {
      _state.dispose();

      if (disposeSequencerEntry != null) {
        disposeSequencerEntry.exit();
        _disposeSequencerEntry = null;
      }

      if (exclusiveSequencer case final exclusiveSequencer?) {
        exclusiveSequencer.exit(this);
      }
    }
  }
}
