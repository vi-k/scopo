import 'dart:async';

import 'package:scopo/src/environment/scope_config.dart';

import '../type_to_string.dart';

final class _Owner<T extends Object> {
  final T instance;
  final Completer<void> completer = Completer<void>();

  _Owner(this.instance);
}

/// Sequencer, позволяющий одновременно работать только одному объекту,
/// владеющему sequencer-ом.
abstract final class ExclusiveSequencerOld<T extends Object> {
  factory ExclusiveSequencerOld({
    Duration? timeout,
    void Function(T owner, T acquirer)? onTimeout,
  }) = _ExclusiveSequencer;

  static ExclusiveSequencerOld<Object> forKey(Object key) =>
      _DeferredExclusiveSequencer(key);

  bool get isEmpty;

  bool get isNotEmpty;

  Future<void> enter(T instance);

  void exit(T instance);
}

/// Реально существующий sequencer, созданный пользователем.
final class _ExclusiveSequencer<T extends Object>
    implements ExclusiveSequencerOld<T> {
  final Duration? timeout;
  final void Function(T owner, T acquirer)? onTimeout;
  var _queueSize = 0;
  _Owner<T>? _owner;

  _ExclusiveSequencer({
    this.timeout,
    this.onTimeout,
  });

  @override
  bool get isEmpty => _queueSize == 0;

  @override
  bool get isNotEmpty => _queueSize != 0;

  /// Ожидает освобождения sequencer-а предыдущим владельцем (владельцами)
  /// и захватывает sequencer.
  ///
  /// В случае зависания предыдущего владельца (вышло время ожидания) либо
  /// завершается исключением [TimeoutException], либо вызывает [onTimeout],
  /// если он задан. В последнем случае новый владелец форсированно освобождает
  /// sequencer от предыдущего владельца и захватывает его.
  @override
  Future<void> enter(T instance) async {
    _queueSize++;

    // Учитываем ситуацию, когда несколько новых владельцев пытаются
    // захватить sequencer. Запускаем их по одному в порядке очереди.
    for (var previousOwner = _owner;
        previousOwner != null;
        previousOwner = _owner) {
      try {
        var future = previousOwner.completer.future;
        if (timeout case final timeout?) {
          future = future.timeout(timeout);
        }
        await future;
      } on TimeoutException {
        final onTimeout = this.onTimeout;
        if (onTimeout == null) {
          _queueSize--;
          rethrow;
        }

        onTimeout(previousOwner.instance, instance);

        // В случае зависания предыдущего владельца необходимо вручную
        // освободить и захватить sequencer, но в этом месте могут оказаться
        // несколько новых владельцев: захватываем sequencer только в случае,
        // если он ещё не был захвачен.
        final currentOwner = _owner;
        if (currentOwner == null ||
            identical(currentOwner.instance, previousOwner.instance)) {
          break;
        }
      }
    }

    // Захватываем sequencer.
    _owner = _Owner(instance);
  }

  @override
  void exit(T instance) {
    _queueSize--;

    // Учитываем ситуацию, когда новый владелец не дождался завершения текущего
    // владельца и захватил sequencer.
    final currentOwner = _owner;
    if (currentOwner != null && identical(currentOwner.instance, instance)) {
      _owner = null;
      currentOwner.completer.complete();
    }
  }
}

/// Отложенный sequencer.
///
/// Работает с реальным sequencer-ом, который создаёт при необходимости,
/// и размещает в кеше. Или берёт из кеша уже созданный.
final class _DeferredExclusiveSequencer
    implements ExclusiveSequencerOld<Object> {
  static final _cache = <Object, _ExclusiveSequencer<Object>>{};

  final Object key;

  _DeferredExclusiveSequencer(this.key);

  @override
  bool get isEmpty => _cache[key]?.isEmpty ?? true;

  @override
  bool get isNotEmpty => _cache[key]?.isNotEmpty ?? false;

  /// Создаёт sequencer или берёт уже созданный из кеша.
  @override
  Future<void> enter(Object instance) async {
    final sequencer = _cache.putIfAbsent(key, () {
      d(
        () => '${typeToShortString(ExclusiveSequencerOld)}[$key]',
        () => 'created',
      );
      return _ExclusiveSequencer<Object>();
    });

    await sequencer.enter(instance);
  }

  @override
  void exit(Object instance) {
    final sequencer = _cache[key];
    if (sequencer == null) {
      throw StateError('Sequencer not acquired');
    }

    sequencer.exit(instance);

    if (sequencer.isEmpty) {
      d(
        () => '${typeToShortString(ExclusiveSequencerOld)}[$key]',
        () => 'removed',
      );
      final cachedSequencer = _cache.remove(key);
      assert(cachedSequencer != null, 'Sequencer not found in the cache');
    }
  }
}
