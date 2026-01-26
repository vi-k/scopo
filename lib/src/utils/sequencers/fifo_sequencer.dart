part of 'sequencer.dart';

/// [FifoSequencer] организует FIFO-очередь, позволяет дождаться завершения
/// работы всех, кто вошёл раньше.
///
/// Вход в очередь осуществляется через метод [enter], который возвращает
/// [SequencerEntry]. В нужный момент владелец с помощью
/// [SequencerEntry.wait] может дождаться завершения работы тех, кто вошёл
/// в очередь ранее, выполнить свою работу и вызвать [SequencerEntry.exit]
/// для выхода из [FifoSequencer] и удаления себя из очереди, тем самым
/// освобождая тех, кто находится в очереди перед ним.
///
/// Пример ниже показывает, как организовать асинхронную утилизацию в классах,
/// когда необходимо, чтобы она проходила строго в порядке, соответствующем
/// порядку инициализации.
///
/// ```dart
/// final FifoSequencer _disposeSequencer;
/// late final SequencerEntry _disposeSequencerEntry;
///
/// void init() {
///   _disposeSequencerEntry = _disposeSequencer.enter();
/// }
///
/// Future<void> dispose() async {
///   await _disposeSequencerEntry.wait();
///
///   // dispose
///
///   _disposeSequencerEntry.exit();
/// }
/// ```
///
/// Владелец может выйти из [FifoSequencer] не вызывая
/// [SequencerEntry.wait] и не дожидаясь своей очереди.
abstract final class FifoSequencer implements Sequencer {
  factory FifoSequencer() = _FifoSequencer;

  static Sequencer forKey(Object key) =>
      _DeferredSequencer(key, _FifoSequencer.new);
}

final class _FifoSequencer implements FifoSequencer {
  final List<SequencerEntry> _queue = [];

  _FifoSequencer();

  @override
  bool get isEmpty => _queue.isEmpty;

  @override
  bool get isNotEmpty => _queue.isNotEmpty;

  @override
  SequencerEntry enter() {
    final entry = SequencerEntry._(this, Completer<void>());
    _queue.add(entry);
    return entry;
  }

  @override
  int queueLength(SequencerEntry entry) {
    final index = _queue.indexOf(entry);
    return index < 0 ? 0 : index;
  }

  @override
  Future<void> wait(
    SequencerEntry entry, {
    Duration? timeout,
    void Function()? onTimeout,
  }) async {
    final index = _queue.indexOf(entry);
    if (index >= 1) {
      var future = _queue[index - 1]._completer.future;
      if (timeout != null) {
        future = future.timeout(timeout);
      }
      try {
        await future;
      } on TimeoutException {
        onTimeout?.call();
      }
    }
  }

  @override
  void exit(SequencerEntry entry) {
    entry._completer.complete();
    _queue.remove(entry);
  }

  @override
  String toString() => '$FifoSequencer(#${identityHashCode(this)})';
}
