import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A widget that renders its [child] once, captures a screenshot of it,
/// and then replaces the child with the captured image.
class ScreenshotReplacer extends StatefulWidget {
  /// The widget to be screenshot.
  final Widget child;

  /// Creates a [ScreenshotReplacer].
  const ScreenshotReplacer({required this.child, super.key});

  @override
  State<ScreenshotReplacer> createState() => _ScreenshotReplacerState();
}

class _ScreenshotReplacerState extends State<ScreenshotReplacer> {
  final GlobalKey _globalKey = GlobalKey();
  ui.Image? _image;
  bool _isCaptured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    if (!mounted) return;
    try {
      final boundary =
          _globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      if (boundary.debugNeedsPaint) {
        // Wait for the next frame if the boundary needs paint.
        // This might happen if the child is not yet ready.
        // However, in initState postFrameCallback, it *should* be ready.
        // We can retry after a short delay or schedule another post frame callback.
        // For simplicity, let's try waiting for the end of the frame again.
        WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
        return;
      }

      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      if (mounted) {
        setState(() {
          _image = image;
          _isCaptured = true;
        });
      }
    } on Object catch (e) {
      debugPrint('Error capturing screenshot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCaptured && _image != null) {
      return RawImage(
        image: _image,
        scale: MediaQuery.of(context).devicePixelRatio,
        // This ensures the image respects the parent constraints if needed,
        // though specific sizing behavior might depend on use case.
        // RawImage defaults to the image size.
      );
    }

    return RepaintBoundary(key: _globalKey, child: widget.child);
  }
}
