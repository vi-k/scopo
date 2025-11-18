import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../common/fake_exception.dart';
import '../fake_dependencies/http_client.dart';
import '../fake_dependencies/some_bloc.dart';
import '../fake_dependencies/some_controller.dart';
import '../utils/app_environment.dart';

class HomeDeps implements ScopeDeps {
  final HttpClient httpClient;
  final SomeBloc someBloc;
  final SomeController someController;

  HomeDeps({
    required this.httpClient,
    required this.someBloc,
    required this.someController,
  });

  static Stream<ScopeInitState<double, HomeDeps>> init(
    BuildContext context,
  ) async* {
    HttpClient? httpClient;
    SomeBloc? someBloc;
    SomeController? someController;

    const depsCount = 3;
    var currentDepNum = 0;
    ScopeProgress<double, HomeDeps> nextProgressStep() {
      final progress = ++currentDepNum / depsCount;
      assert(
        progress <= 1.0,
        'currentDepNum ($currentDepNum) > depsCount ($depsCount)',
      );
      return ScopeProgress(progress);
    }

    // Fake error block
    final random = Random();
    final throwFakeError =
        random.nextDouble() < AppEnvironment.probabilityOfHomeRandomError;
    final depWithFakeError = random.nextInt(depsCount);
    // ignore: avoid_print
    print(
      '[$HomeDeps] '
      '${throwFakeError ? 'throw fake error on dep #${depWithFakeError + 1}' : 'no throw fake error'}',
    );
    void randomFakeError(String text) {
      if (throwFakeError && depWithFakeError == currentDepNum) {
        throw FakeException(text);
      }
    }

    try {
      httpClient = HttpClient();
      await httpClient.init();
      randomFakeError('$HttpClient initialization error');
      yield nextProgressStep();

      final someBlocCompleter = Completer<SomeBlocData>();
      someBloc =
          SomeBloc()..add(
            SomeBlocLoad(
              fakeError: throwFakeError && depWithFakeError == currentDepNum,
            ),
          );
      someBloc.stream.listen((state) {
        switch (state) {
          case SomeBlocInitial():
          case SomeBlocInProgress():
            break;
          case SomeBlocSuccess(:final data):
            someBlocCompleter.complete(data);
          case SomeBlocError(:final error, :final stackTrace):
            someBlocCompleter.completeError(error, stackTrace);
        }
      });
      await someBlocCompleter.future;
      yield nextProgressStep();

      someController = SomeController();
      await someController.init();
      randomFakeError('$SomeController initialization error');
      yield nextProgressStep();

      // Показываем пользователю 100%
      await Future<void>.delayed(const Duration(milliseconds: 500));

      yield ScopeReady(
        HomeDeps(
          httpClient: httpClient,
          someBloc: someBloc,
          someController: someController,
        ),
      );
    } on Object {
      await [
        httpClient?.dispose(),
        someBloc?.close(),
        someController?.dispose(),
      ].nonNulls.wait;
      rethrow;
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
