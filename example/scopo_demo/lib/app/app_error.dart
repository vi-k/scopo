import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../common/domain/fake_exception.dart';

/// A widget demonstrates how [Scope] handles errors.
class AppError extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;

  const AppError(this.error, this.stackTrace, {super.key});

  @override
  Widget build(BuildContext context) {
    Object? message;
    try {
      message = (error as dynamic).message;
      // ignore: avoid_catching_errors
    } on NoSuchMethodError {
      message = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Something went wrong'),
        backgroundColor: Colors.deepOrange,
      ),
      backgroundColor: Colors.deepOrangeAccent,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${message ?? error}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (error case FakeException()) ...[
                const SizedBox(height: 20),
                const Text('~ This is a fake error. Restart the application ~'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
