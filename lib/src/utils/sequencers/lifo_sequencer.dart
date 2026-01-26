part of 'sequencer.dart';

/// [LifoSequencer] организует LIFO-очередь, позволяет дождаться завершения
/// работы всех, кто вошёл позже.
///
/// Вход в стек осуществляется через метод [enter], который возвращает
/// [SequencerEntry]. В нужный момент владелец с помощью
/// [SequencerEntry.wait] может дождаться завершения работы тех, кто вошёл
/// в стек позже, выполнить свою работу и вызвать [SequencerEntry.exit]
/// для выхода из [LifoSequencer] и удаления себя из стека, тем самым
/// освобождая тех, кто находится в стеке под ним.
///
/// Пример ниже показывает, как организовать асинхронную утилизацию в классах,
/// когда необходимо, чтобы она проходила строго в порядке, обратном порядку
/// инициализации.
///
/// ```dart
/// final LifoSequencer _disposeSequencer;
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
/// Владелец может выйти из [LifoSequencer] не вызывая
/// [SequencerEntry.wait] и не дожидаясь своей очереди.
abstract final class LifoSequencer implements Sequencer {
  factory LifoSequencer() = _LifoSequencer;

  static Sequencer forKey(Object key) =>
      _DeferredSequencer(key, _LifoSequencer.new);
}

final class _LifoSequencer implements LifoSequencer {
  final List<SequencerEntry> _stack = [];

  _LifoSequencer();

  @override
  bool get isEmpty => _stack.isEmpty;

  @override
  bool get isNotEmpty => _stack.isNotEmpty;

  @override
  SequencerEntry enter() {
    final entry = SequencerEntry._(this, Completer<void>());
    _stack.add(entry);
    return entry;
  }

  @override
  int queueLength(SequencerEntry entry) {
    final index = _stack.indexOf(entry);
    return index < 0 ? 0 : _stack.length - index - 1;
  }

  @override
  Future<void> wait(
    SequencerEntry entry, {
    Duration? timeout,
    void Function()? onTimeout,
  }) async {
    final index = _stack.indexOf(entry);
    if (index >= 0 && index < _stack.length - 1) {
      var future = _stack[index + 1]._completer.future;
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
    _stack.remove(entry);
  }

  @override
  String toString() => '$LifoSequencer(#${identityHashCode(this)})';
}
