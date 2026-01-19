import 'dart:async';

import 'package:scopo/scopo.dart';

import '../common/data/fake_services/fake_bloc.dart';
import '../common/data/fake_services/fake_controller.dart';
import '../common/data/fake_services/fake_user_http_client.dart';
import 'home.dart';

/// Dependencies for [Home] scope.
///
/// They are initialized asynchronously in the [init] stream.
final class HomeDependencies extends ScopeDependenciesQueue<HomeDependencies> {
  late final FakeUserHttpClient httpClient;
  late final FakeBloc bloc;
  late final FakeController controller;

  HomeDependencies();

  @override
  List<List<ScopeDependencyBase>> queue() => [
        [
          ScopeDependency(
            name: 'httpClient',
            init: () async {
              httpClient = FakeUserHttpClient();
              await httpClient.init();
            },
            dispose: () async {
              await httpClient.close();
            },
          ),
        ],
        [
          ScopeDependency(
            name: 'bloc',
            init: () async {
              final completer = Completer<void>();
              bloc = FakeBloc()..add(FakeBlocLoad());
              bloc.stream.listen((state) {
                switch (state) {
                  case FakeBlocInitial():
                  case FakeBlocInProgress():
                    break;
                  case FakeBlocSuccess():
                    completer.complete();
                  case FakeBlocError(:final error, :final stackTrace):
                    bloc.close().whenComplete(() {
                      completer.completeError(error, stackTrace);
                    });
                }
              });
              await completer.future;
            },
            dispose: () async {
              await bloc.close();
            },
          ),
          ScopeDependency(
            name: 'controller',
            init: () async {
              controller = FakeController();
              await controller.init();
            },
            dispose: () async {
              await controller.dispose();
            },
          ),
        ],
      ];

  static Stream<ScopeInitState<double, HomeDependencies>> init() =>
      HomeDependencies().initQueue();

  @override
  Future<void> dispose() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    await super.dispose();
  }
}
