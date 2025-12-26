import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'image_analyze.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _controller = CameraController(
      camera,
      ResolutionPreset.low, // 🔥 important for stability
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // MAIN CAPTURE FLOW
  // --------------------------------------------------
  Future<void> _captureFrame() async {
    if (_isProcessing) return;
    if (_controller == null || !_controller!.value.isInitialized) return;

    _isProcessing = true;

    try {
      // ✅ Let autofocus & exposure stabilize
      await Future.delayed(const Duration(milliseconds: 800));

      // ✅ Get a stable frame (skip initial frames)
      final CameraImage frame = await _getStableFrame();

      // ✅ Convert frame to clean JPEG
      final File jpegFile = await _convertYuvToJpeg(frame);

      // ✅ Send to Gemini backend
      final String analysis =
          await analyzeImageWithGemini(jpegFile.path);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Gemini Analysis"),
          content: SingleChildScrollView(
            child: Text(analysis),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Frame capture error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  // --------------------------------------------------
  // GET A STABLE FRAME (SKIP FIRST FRAMES)
  // --------------------------------------------------
  Future<CameraImage> _getStableFrame() async {
    final completer = Completer<CameraImage>();
    int frameCount = 0;

    await _controller!.startImageStream((CameraImage image) {
      frameCount++;

      // 🔥 skip first unstable frames
      if (frameCount < 10) return;

      if (!completer.isCompleted) {
        completer.complete(image);
        _controller!.stopImageStream();
      }
    });

    return completer.future;
  }

  // --------------------------------------------------
  // YUV → JPEG (CROP + ROTATE + RESIZE)
  // --------------------------------------------------
  Future<File> _convertYuvToJpeg(CameraImage image) async {
    final int width = image.width;
    final int height = image.height;

    final img.Image rgbImage =
        img.Image(width: width, height: height);

    final Uint8List yPlane = image.planes[0].bytes;
    final Uint8List uPlane = image.planes[1].bytes;
    final Uint8List vPlane = image.planes[2].bytes;

    int yIndex = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex =
            (y ~/ 2) * image.planes[1].bytesPerRow + (x ~/ 2);

        final int yValue = yPlane[yIndex];
        final int uValue = uPlane[uvIndex];
        final int vValue = vPlane[uvIndex];

        int r = (yValue + 1.402 * (vValue - 128)).round();
        int g = (yValue -
                0.344136 * (uValue - 128) -
                0.714136 * (vValue - 128))
            .round();
        int b = (yValue + 1.772 * (uValue - 128)).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        rgbImage.setPixelRgba(x, y, r, g, b, 255);
        yIndex++;
      }
    }

    // 🎯 center crop (70%)
    final int cropSize = (rgbImage.width * 0.7).toInt();
    final int cx = (rgbImage.width - cropSize) ~/ 2;
    final int cy = (rgbImage.height - cropSize) ~/ 2;

    final img.Image cropped = img.copyCrop(
      rgbImage,
      x: cx,
      y: cy,
      width: cropSize,
      height: cropSize,
    );

    // 🔄 rotate for back camera
    final img.Image rotated =
        img.copyRotate(cropped, angle: 90);

    // 🔽 resize for Gemini
    final img.Image resized =
        img.copyResize(rotated, width: 640);

    final Directory tempDir = await getTemporaryDirectory();
    final File file = File(
      '${tempDir.path}/frame_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await file.writeAsBytes(
      img.encodeJpg(resized, quality: 70),
    );

    return file;
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Frame Camera"),
      ),
      body: CameraPreview(_controller!),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureFrame,
        child: const Icon(Icons.camera),
      ),
    );
  }
}
