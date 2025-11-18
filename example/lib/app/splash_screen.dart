import 'package:flutter/material.dart';

import '../common/animated_progress_indicator.dart';

class SplashScreen extends StatelessWidget {
  final double progress;

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
        padding: EdgeInsets.all(8),
        child: Center(
          child: SizedBox(
            width: 100,
            child: AnimatedProgressIndicator(
              value: progress,
              builder:
                  (value) =>
                      LinearProgressIndicator(value: value == 0 ? null : value),
            ),
          ),
        ),
      ),
    );
  }
}
