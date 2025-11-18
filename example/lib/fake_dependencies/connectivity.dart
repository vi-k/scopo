import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../utils/app_environment.dart';

class Connectivity extends ValueNotifier<bool> {
  late final Random _random;
  StreamSubscription<void>? _subscription;

  Connectivity() : super(true);

  Future<void> init() async {
    assert(_subscription == null, '$Connectivity can only be initialized once');

    _random = Random();

    _subscription = _fakeIsConnectedGenerator().listen((isConnected) {
      value = isConnected;
    });

    await Future<void>.delayed(const Duration(seconds: 1));
  }

  Stream<bool> _fakeIsConnectedGenerator() async* {
    var isConnected = true;
    while (true) {
      final (min, max) =
          isConnected
              ? AppEnvironment.enabledConnectionDuration
              : AppEnvironment.disabledConnectionDuration;
      final duration = _random.nextInt(max - min) + min;
      // ignore: avoid_print
      print(
        '[connectivity] ${isConnected ? 'connected' : 'disconnected'}'
        ' for $duration sec',
      );
      await Future<void>.delayed(Duration(seconds: duration));

      yield isConnected = !isConnected;
    }
  }

  @override
  Future<void> dispose() async {
    assert(_subscription != null, '$Connectivity is not initialized');
    await _subscription?.cancel();

    super.dispose();
  }
}
