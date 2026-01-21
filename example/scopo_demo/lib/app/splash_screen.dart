import 'package:flutter/material.dart';

/// The screen shows the progress of dependency initialization.
class SplashScreen extends StatelessWidget {
  final String? progress;

  const SplashScreen({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$SplashScreen'),
        backgroundColor: Colors.lightBlue,
      ),
      backgroundColor: Colors.lightBlueAccent,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(progress ?? ''),
        ),
      ),
    );
  }
}
