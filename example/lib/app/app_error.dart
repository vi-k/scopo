import 'package:flutter/material.dart';

import '../common/fake_exception.dart';

class AppError extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;

  const AppError(this.error, this.stackTrace, {super.key});

  @override
  Widget build(BuildContext context) {
    Object? message;
    try {
      message = (error as dynamic).message;
    } on NoSuchMethodError {
      message = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Somethimg went wrong'),
        backgroundColor: Colors.deepOrange,
      ),
      backgroundColor: Colors.deepOrangeAccent,
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${message ?? error}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (error case FakeException()) ...[
                SizedBox(height: 20),
                Text('~ This is a fake error. Restart the application ~'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
