import 'dart:async';

import '../../environment/scope_config.dart';

/// Запускает поток в защищённой среде до получения первой ошибки.
///
/// - Если [streamFactory] выбросит исключение, то оно будет передано в
///   результирующий поток: функция вернёт [Stream.error].
/// - Во время работы при получении из потока ошибки обработка завершается:
///   подписка на поток отменяется, результирующий поток закрывается.
/// - Все ошибки, полученные после завершения обработки, т.е. после получения
///   ошибки или после отмены подписки на результирующий поток, будут переданы
///   в [onPostCancelError].
///
/// Если поток закроется без ошибки, то [onPostCancelError] не будет вызван.
/// Если поток закроется с ошибкой, то [onPostCancelError] будет вызван.
/// Если поток будет отменён, то [onPostCancelError] будет вызван.
Stream<T> runStreamGuarded<T>(
  Stream<T> Function() streamFactory,
  void Function(Object, StackTrace) onPostCancelError, {
  String? debugName,
}) {
  final Stream<T> stream;

  try {
    stream = streamFactory();
  } on Object catch (error, stackTrace) {
    return Stream.error(error, stackTrace);
  }

  final controller = StreamController<T>();
  StreamSubscription<T>? subscription;
  Completer<void>? cancelCompleter;

  String source() =>
      'runStreamGuarded${debugName == null ? '' : '($debugName)'}';

  void pause() {
    subscription?.pause();
  }

  void resume() {
    subscription?.resume();
  }

  /// Отменяет все подписки, ждёт их завершения и передаёт возникшие
  /// ошибки.
  Future<void> cancel() async {
    d(source, 'cancel');

    var innerCompleter = cancelCompleter;
    if (innerCompleter == null) {
      controller.close(); // ignore: unawaited_futures

      innerCompleter = Completer<void>();
      cancelCompleter = innerCompleter;

      try {
        d(source, 'await subscription.cancel()');
        await subscription?.cancel();
        d(source, 'await subscription.cancel() done');
        // ignore: avoid_catching_errors
      } on Object catch (error, stackTrace) {
        d(source, 'onPostCancelError($error)');
        onPostCancelError(error, stackTrace);
      } finally {
        subscription = null;
        innerCompleter.complete();
      }
    }

    await innerCompleter.future;
    d(source, 'cancel done');
  }

  controller
    ..onPause = pause
    ..onResume = resume
    ..onCancel = cancel
    ..onListen = () {
      subscription = stream.listen(
        controller.add,
        onError: (Object error, StackTrace stacktrace) {
          d(source, 'controller.addError($error)');
          controller.addError(error, stacktrace);
          cancel(); // ignore: discarded_futures
        },
        onDone: () {
          d(source, 'subscription.onDone');
          subscription = null;
          controller.close(); // ignore: discarded_futures
        },
      );
    };

  return controller.stream;
}
