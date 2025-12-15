import 'dart:async';
import 'dart:math';

import 'package:scopo/scopo.dart';

import '../common/data/fake_services/http_client.dart';
import '../common/data/fake_services/some_bloc.dart';
import '../common/data/fake_services/some_controller.dart';
import '../common/domain/fake_exception.dart';
import '../utils/app_environment.dart';
import 'home.dart';

/// Dependencies for [Home] scope.
///
/// They are initialized asynchronously in the [init] stream.
class HomeDeps implements ScopeDeps {
  final HttpClient httpClient;
  final SomeBloc someBloc;
  final SomeController someController;

  HomeDeps({
    required this.httpClient,
    required this.someBloc,
    required this.someController,
  });

  /// Method uses [DoubleProgressIterator] to track and report granular
  /// initialization progress ([double] 0.0 to 1.0).
  ///
  /// It simulates random initialization errors using [AppEnvironment]
  /// probabilities.
  static Stream<ScopeInitState<double, HomeDeps>> init() async* {
    HttpClient? httpClient;
    SomeBloc? someBloc;
    SomeController? someController;
    var isInitialized = false;

    final progressIterator = DoubleProgressIterator(count: 3);

    // Fake error block
    final random = Random();
    final throwFakeError =
        random.nextDouble() < AppEnvironment.probabilityOfHomeRandomError;
    final depWithFakeError = random.nextInt(progressIterator.count);
    // ignore: avoid_print
    print(
      '[$HomeDeps] '
      '${throwFakeError ? 'throw fake error on dep #${depWithFakeError + 1}' : 'no throw fake error'}',
    );
    void randomFakeError(String text) {
      if (throwFakeError && depWithFakeError == progressIterator.currentStep) {
        throw FakeException(text);
      }
    }

    try {
      httpClient = const HttpClient();
      await httpClient.init();
      randomFakeError('$HttpClient initialization error');
      yield ScopeProgress(progressIterator.nextProgress());

      final someBlocCompleter = Completer<void>();
      someBloc = SomeBloc()
        ..add(
          SomeBlocLoad(
            fakeError: throwFakeError &&
                depWithFakeError == progressIterator.currentStep,
          ),
        );
      someBloc.stream.listen((state) {
        switch (state) {
          case SomeBlocInitial():
          case SomeBlocInProgress():
            break;
          case SomeBlocSuccess():
            someBlocCompleter.complete();
          case SomeBlocError():
            someBlocCompleter.complete();
        }
      });
      await someBlocCompleter.future;
      yield ScopeProgress(progressIterator.nextProgress());

      someController = SomeController();
      await someController.init();
      randomFakeError('$SomeController initialization error');
      yield ScopeProgress(progressIterator.nextProgress());

      yield ScopeReady(
        HomeDeps(
          httpClient: httpClient,
          someBloc: someBloc,
          someController: someController,
        ),
      );

      isInitialized = true;
    } finally {
      if (!isInitialized) {
        await [
          httpClient?.dispose(),
          someBloc?.close(),
          someController?.dispose(),
        ].nonNulls.wait;
      }
    }
  }

  @override
  Future<void> dispose() async {
    await [
      httpClient.dispose(),
      someBloc.close(),
      someController.dispose(),
    ].wait;
  }
}
