import 'dart:async';

final class _Owner<T extends Object> {
  final T instance;
  final Completer<void> lifecycleCompleter = Completer<void>();

  _Owner(this.instance);
}

/// Контроллер, позволяющий одновременно работать только одному объекту,
/// владеющему контроллером.
final class LifecycleCoordinator<T extends Object> {
  final Duration? timeout;
  final void Function(T owner)? onTimeout;
  var _queueSize = 0;

  _Owner<T>? _owner;

  LifecycleCoordinator({
    this.timeout,
    this.onTimeout,
  });

  bool get isEmpty => _queueSize == 0;

  bool get isNotEmpty => _queueSize != 0;

  /// Ожидает освобождения контроллера предыдущим владельцем (владельцами)
  /// и захватывает контроллер.
  ///
  /// В случае зависания предыдущего владельца (вышло время ожидания) либо
  /// завершается исключением [TimeoutException], либо вызывает [onTimeout],
  /// если он задан. В последнем случае новый владелец форсированно освобождает
  /// контроллер от предыдущего владельца и захватывает его.
  Future<void> acquire(T instance) async {
    _queueSize++;

    // Учитываем ситуацию, когда несколько новых владельцев пытаются
    // захватить контроллер. Запускаем их по одному в порядке очереди.
    for (var previousOwner = _owner;
        previousOwner != null;
        previousOwner = _owner) {
      try {
        var future = previousOwner.lifecycleCompleter.future;
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

        onTimeout(previousOwner.instance);

        // В случае зависания предыдущего владельца необходимо вручную
        // освободить и захватить контроллер, но в этом месте могут оказаться
        // несколько новых владельцев: захватываем контроллер только в случае,
        // если он не был захвачен новым владельцем.
        final currentOwner = _owner;
        if (currentOwner == null ||
            identical(currentOwner.instance, previousOwner.instance)) {
          break;
        }
      }
    }

    // Захватываем контроллер.
    _owner = _Owner(instance);
  }

  void release(T instance) {
    _queueSize--;

    // Учитываем ситуацию, когда новый владелец не дождался завершения текущего
    // владельца и захватил контроллер.
    final currentOwner = _owner;
    if (currentOwner != null && identical(currentOwner.instance, instance)) {
      _owner = null;
      currentOwner.lifecycleCompleter.complete();
    }
  }
}
