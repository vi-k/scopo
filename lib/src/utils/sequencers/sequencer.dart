import 'dart:async';

import '../../environment/scope_config.dart';

part 'fifo_sequencer.dart';
part 'lifo_sequencer.dart';

final class SequencerEntry {
  Sequencer _sequencer;
  final Completer<void> _completer;

  SequencerEntry._(this._sequencer, this._completer);

  /// Очередь перед entry.
  int get queueLength => _sequencer.queueLength(this);

  /// Ждать своей очереди.
  Future<void> wait({
    Duration? timeout,
    void Function()? onTimeout,
  }) =>
      _sequencer.wait(this, timeout: timeout, onTimeout: onTimeout);

  /// Покинуть очередь.
  void exit() => _sequencer.exit(this);
}

abstract interface class Sequencer {
  bool get isEmpty;

  bool get isNotEmpty;

  /// Встать в очередь.
  SequencerEntry enter();

  /// Очередь перед entry.
  int queueLength(SequencerEntry entry);

  /// Ждать очереди.
  Future<void> wait(
    SequencerEntry entry, {
    Duration? timeout,
    void Function()? onTimeout,
  });

  /// Покинуть очередь.
  void exit(SequencerEntry entry);
}

final class _DeferredSequencer implements Sequencer {
  static final _cache = <Object, Sequencer>{};

  final Object _key;
  final Sequencer Function() _create;

  _DeferredSequencer(this._key, this._create);

  Sequencer get _sequencer =>
      _cache[_key] ??
      (throw StateError('Sequencer with key $_key not found in the cache'));

  @override
  bool get isEmpty => _cache[_key]?.isEmpty ?? true;

  @override
  bool get isNotEmpty => _cache[_key]?.isNotEmpty ?? false;

  @override
  SequencerEntry enter() {
    final sequencer = _cache.putIfAbsent(_key, () {
      final sequencer = _create();
      d(sequencer, 'created');
      return sequencer;
    });

    return sequencer.enter().._sequencer = this;
  }

  @override
  int queueLength(SequencerEntry entry) =>
      _cache[_key]?.queueLength(entry) ?? 0;

  @override
  Future<void> wait(
    SequencerEntry entry, {
    Duration? timeout,
    void Function()? onTimeout,
  }) async {
    await _sequencer.wait(entry, timeout: timeout, onTimeout: onTimeout);
  }

  @override
  void exit(SequencerEntry entry) {
    final sequencer = _sequencer..exit(entry);
    if (sequencer.isEmpty) {
      d(sequencer, 'removed from cache');
      _cache.remove(_key);
    }
  }

  @override
  String toString() => '$Sequencer(key: $_key)';
}
