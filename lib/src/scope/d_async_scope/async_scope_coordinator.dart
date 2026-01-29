part of '../scope.dart';

final class AsyncScopeCoordinator extends ScopeWidgetCore<AsyncScopeCoordinator,
    AsyncScopeCoordinatorElement> {
  const AsyncScopeCoordinator({
    super.key,
    super.child,
  });

  @override
  AsyncScopeCoordinatorElement createScopeElement() =>
      AsyncScopeCoordinatorElement(this);
}

final class AsyncScopeCoordinatorElement extends ScopeWidgetElementBase<
    AsyncScopeCoordinator, AsyncScopeCoordinatorElement> {
  AsyncScopeCoordinatorElement(super.widget);

  @override
  Widget buildChild() => widget.child;
}

final class AsyncScopeEntry {
  _AsyncScopeCoordinatorController? _controller;
  final _completer = Completer<void>();

  AsyncScopeEntry();

  bool get isCompleted => _completer.isCompleted;

  /// Покинуть очередь.
  void exit() {
    _checkController()._exit(this);
  }

  _AsyncScopeCoordinatorController _checkController() =>
      _controller ?? (throw StateError('$AsyncScopeEntry is not attached'));
}

final class _AsyncScopeCoordinatorController {
  final String debugName;
  final _entries = <AsyncScopeEntry>{};

  _AsyncScopeCoordinatorController(this.debugName);

  bool get isEmpty => _entries.isEmpty;

  bool get isNotEmpty => _entries.isNotEmpty;

  int get length => _entries.length;

  void close() {
    final errors = <AsyncError>[];
    for (final entry in _entries) {
      try {
        _exit(entry);
      } on Object catch (error, stackTrace) {
        errors.add(AsyncError(error, stackTrace));
      }
    }

    if (errors.isNotEmpty) {
      throw ParallelWaitError(<void>[], errors);
    }
  }

  Future<AsyncScopeEntry> enter({
    AsyncScopeEntry? entry,
    Duration? timeout,
  }) async {
    entry ??= AsyncScopeEntry();

    assert(entry._controller == null, 'Entry is already attached');
    assert(!entry._completer.isCompleted, 'Entry is already completed');

    final previous = List.of(_entries);

    entry._controller = this;
    _entries.add(entry);

    if (previous.isEmpty) {
      return entry;
    }

    // Ждем, пока все предыдущие владельцы освободят контроллер,
    // ИЛИ пока текущий не будет отменён.
    var future = Future.any([
      previous.map((entry) => entry._completer.future).wait,
      entry._completer.future,
    ]);
    if (timeout != null) {
      future = future.timeout(timeout);
    }

    // Если вышло время ожидания, то сообщаем об ошибке и разрешаем владельцу
    // войти.
    try {
      await future;
    } on TimeoutException catch (error, stackTrace) {
      final uncompletedCount =
          previous.where((e) => !e._completer.isCompleted).length;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'scopo',
          context: ErrorDescription(
            'The previous $uncompletedCount entries'
            ' did not complete within $timeout.',
          ),
        ),
      );
    }

    return entry;
  }

  void _exit(AsyncScopeEntry entry) {
    assert(
      identical(entry._controller, this),
      'Entry is not attached to this controller',
    );
    assert(!entry._completer.isCompleted, 'Entry is already completed');

    _entries.remove(entry);
    entry._controller = null;
    entry._completer.complete();
  }

  @override
  String toString() => debugName;
}
