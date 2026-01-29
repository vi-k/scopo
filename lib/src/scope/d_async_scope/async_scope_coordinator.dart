part of '../scope.dart';

final class AsyncScopeCoordinator extends ScopeWidgetCore<AsyncScopeCoordinator,
    _AsyncScopeCoordinatorElement> {
  const AsyncScopeCoordinator({
    super.key,
    super.tag,
    required super.child,
  });

  @override
  InheritedElement createScopeElement() => _AsyncScopeCoordinatorElement(this);

  static Future<AsyncScopeCoordinatorEntry> enter(
    BuildContext context,
    Object key, {
    AsyncScopeCoordinatorEntry? entry,
    Duration? timeout,
  }) =>
      ScopeWidgetCore.maybeOf<AsyncScopeCoordinator,
          _AsyncScopeCoordinatorElement>(
        context,
        listen: false,
      )?.enter(key, entry: entry, timeout: timeout) ??
      (throw FlutterError('No `$AsyncScopeCoordinator`.\n'
          'You are trying to use `scopeKey`, but the `$AsyncScopeCoordinator`'
          ' is missing in the context. Add it to the widget tree so that'
          ' all your scopes that need coordination by `scopeKey` can access'
          ' it. The most universal solution is to place it above'
          ' `$MaterialApp`.'));
}

final class _AsyncScopeCoordinatorElement extends ScopeWidgetElementBase<
    AsyncScopeCoordinator, _AsyncScopeCoordinatorElement> {
  _AsyncScopeCoordinatorElement(super.widget);
  static final _controllers = <Object, _AsyncScopeCoordinatorController>{};

  @override
  Widget buildChild() => widget.child;

  Future<AsyncScopeCoordinatorEntry> enter(
    Object key, {
    AsyncScopeCoordinatorEntry? entry,
    Duration? timeout,
  }) {
    final controller = _controllers.putIfAbsent(key, () {
      final controller = _AsyncScopeCoordinatorController(
        key,
        remove: () {
          _controllers.remove(key);
          _d('controller for key [$key] removed');
        },
      );
      _d('controller for key [$key] created');
      return controller;
    });

    return controller.enter(entry: entry, timeout: timeout);
  }

  void _d(Object? message) {
    d(() => '${toStringShort()} #$hashCode', message);
  }
}

final class AsyncScopeCoordinatorEntry {
  _AsyncScopeCoordinatorController? _controller;
  final _completer = Completer<void>();

  AsyncScopeCoordinatorEntry();

  bool get isCompleted => _completer.isCompleted;

  /// Покинуть очередь.
  void exit() {
    _checkController()._exit(this);
  }

  _AsyncScopeCoordinatorController _checkController() =>
      _controller ??
      (throw StateError('$AsyncScopeCoordinatorEntry is not attached'));
}

final class _AsyncScopeCoordinatorController {
  final Object key;
  void Function()? remove;

  final _entries = <AsyncScopeCoordinatorEntry>{};

  _AsyncScopeCoordinatorController(this.key, {this.remove});

  bool get isEmpty => _entries.isEmpty;

  bool get isNotEmpty => _entries.isNotEmpty;

  int get length => _entries.length;

  void close() {
    final errors = <AsyncError>[];
    for (final entry in List.of(_entries)) {
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

  Future<AsyncScopeCoordinatorEntry> enter({
    AsyncScopeCoordinatorEntry? entry,
    Duration? timeout,
  }) async {
    entry ??= AsyncScopeCoordinatorEntry();

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

  void _exit(AsyncScopeCoordinatorEntry entry) {
    assert(
      identical(entry._controller, this),
      'Entry is not attached to this controller',
    );
    assert(!entry._completer.isCompleted, 'Entry is already completed');

    _entries.remove(entry);
    entry._completer.complete();
    entry._controller = null;

    if (_entries.isEmpty) {
      remove?.call();
      remove = null;
    }
  }

  @override
  String toString() => '$_AsyncScopeCoordinatorController($key)';
}
