import 'dart:async';

import '../../environment/scope_config.dart';

final class ExclusiveSequencerEntry {
  final ExclusiveSequencer _sequencer;
  final Completer<void> _completer;

  ExclusiveSequencerEntry._(this._sequencer, this._completer);

  bool get isCompleted => _completer.isCompleted;

  /// Вход.
  ///
  /// Ожидает освобождения sequencer-а предыдущим владельцем (владельцами)
  /// и захватывает его.
  ///
  /// Если вышло время ожидания [timeout] завершается исключением
  /// [TimeoutException].
  Future<void> enter({Duration? timeout}) =>
      _sequencer._enter(this, timeout: timeout);

  /// Покинуть очередь.
  void exit() => _sequencer._exit(this);
}

sealed class ExclusiveSequencer {
  factory ExclusiveSequencer() = _ExclusiveSequencer;

  factory ExclusiveSequencer.forKey(Object key) = _DeferredExclusiveSequencer;

  ExclusiveSequencer._();

  bool get isEmpty;

  bool get isNotEmpty;

  ExclusiveSequencerEntry createEntry();

  /// Вход.
  Future<void> _enter(
    ExclusiveSequencerEntry entry, {
    Duration? timeout,
  });

  /// Выход.
  void _exit(ExclusiveSequencerEntry entry);
}

final class _ExclusiveSequencer extends ExclusiveSequencer {
  ExclusiveSequencerEntry? _owner;
  var _count = 0;

  _ExclusiveSequencer() : super._();

  @override
  bool get isEmpty => _count == 0;

  @override
  bool get isNotEmpty => _count != 0;

  @override
  ExclusiveSequencerEntry createEntry() =>
      ExclusiveSequencerEntry._(this, Completer<void>());

  /// Ожидает освобождения sequencer-а предыдущим владельцем (владельцами)
  /// и захватывает sequencer.
  ///
  /// Если вышло время ожидания [timeout] завершается исключением
  /// [TimeoutException].
  @override
  Future<void> _enter(
    ExclusiveSequencerEntry entry, {
    Duration? timeout,
  }) async {
    _count++;

    // Учитываем ситуацию, когда несколько новых владельцев пытаются
    // захватить sequencer. Запускаем их по одному в порядке очереди.
    for (var previous = _owner; previous != null; previous = _owner) {
      var future = Future.any([
        previous._completer.future,
        entry._completer.future,
      ]);
      if (timeout case final timeout?) {
        future = future.timeout(timeout);
      }
      await future;

      if (entry._completer.isCompleted) {
        return;
      }
    }

    // Захватываем sequencer.
    _owner = entry;
  }

  @override
  void _exit(ExclusiveSequencerEntry entry) {
    _count--;
    entry._completer.complete();

    if (_owner case final owner? when identical(owner, entry)) {
      _owner = null;
    }
  }

  @override
  String toString() => '$ExclusiveSequencer #$hashCode';
}

final class _DeferredExclusiveSequencer extends ExclusiveSequencer {
  static final _cache = <Object, _ExclusiveSequencer>{};

  final Object _key;

  _DeferredExclusiveSequencer(this._key) : super._();

  _ExclusiveSequencer _cachedSequencer() =>
      _cache[_key] ??
      (throw StateError(
        'Exclusive sequencer with key $_key not found in the cache',
      ));

  @override
  bool get isEmpty => _cache[_key]?.isEmpty ?? true;

  @override
  bool get isNotEmpty => _cache[_key]?.isNotEmpty ?? false;

  @override
  ExclusiveSequencerEntry createEntry() =>
      ExclusiveSequencerEntry._(this, Completer<void>());

  @override
  Future<void> _enter(ExclusiveSequencerEntry entry, {Duration? timeout}) {
    final cachedSequencer = _cache.putIfAbsent(_key, () {
      final sequencer = _ExclusiveSequencer();
      d(sequencer, 'created');
      return sequencer;
    });

    return cachedSequencer._enter(entry, timeout: timeout);
  }

  @override
  void _exit(ExclusiveSequencerEntry entry) {
    final cachedSequencer = _cachedSequencer().._exit(entry);
    if (cachedSequencer.isEmpty) {
      d(cachedSequencer, 'removed from cache');
      _cache.remove(_key);
    }
  }

  @override
  String toString() {
    final cachedSequencer = _cache[_key];
    return '$ExclusiveSequencer($_key)'
        ' ${cachedSequencer == null ? 'absent' : '#${cachedSequencer.hashCode}'}';
  }
}
