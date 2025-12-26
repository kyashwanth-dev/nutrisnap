import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

import 'image_analyze.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  int _cameraIndex = 0;

  bool _isProcessing = false;
  FlashMode _flashMode = FlashMode.off;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    _cameras = await availableCameras();

    _controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.low, // keep for stability
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
  // CAMERA FRAME CAPTURE (UNCHANGED, STABLE)
  // --------------------------------------------------
  Future<void> _captureFrame() async {
    if (_isProcessing) return;
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final CameraImage frame = await _getStableFrame();
      final File jpegFile = await _convertYuvToJpeg(frame);

      final String analysis =
          await analyzeImageWithGemini(jpegFile.path);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imageFile: jpegFile,
            geminiResponse: analysis,
          ),
        ),
      );
    } catch (e) {
      debugPrint("❌ Camera error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --------------------------------------------------
  // GALLERY PICK + ANALYZE
  // --------------------------------------------------
  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);

      if (picked == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final File imageFile = File(picked.path);

      final String analysis =
          await analyzeImageWithGemini(imageFile.path);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imageFile: imageFile,
            geminiResponse: analysis,
          ),
        ),
      );
    } catch (e) {
      debugPrint("❌ Gallery error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --------------------------------------------------
  // GET STABLE FRAME
  // --------------------------------------------------
  Future<CameraImage> _getStableFrame() async {
    final completer = Completer<CameraImage>();
    int frameCount = 0;

    await _controller!.startImageStream((CameraImage image) {
      frameCount++;

      if (frameCount < 10) return;

      if (!completer.isCompleted) {
        completer.complete(image);
        _controller!.stopImageStream();
      }
    });

    return completer.future;
  }

  // --------------------------------------------------
  // YUV → JPEG
  // --------------------------------------------------
  Future<File> _convertYuvToJpeg(CameraImage image) async {
    final img.Image rgb =
        img.Image(width: image.width, height: image.height);

    final y = image.planes[0].bytes;
    final u = image.planes[1].bytes;
    final v = image.planes[2].bytes;

    int index = 0;

    for (int yPos = 0; yPos < image.height; yPos++) {
      for (int xPos = 0; xPos < image.width; xPos++) {
        final uvIndex =
            (yPos ~/ 2) * image.planes[1].bytesPerRow +
                (xPos ~/ 2);

        int yp = y[index];
        int up = u[uvIndex];
        int vp = v[uvIndex];

        int r = (yp + 1.402 * (vp - 128)).round();
        int g =
            (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128))
                .round();
        int b = (yp + 1.772 * (up - 128)).round();

        rgb.setPixelRgba(
          xPos,
          yPos,
          r.clamp(0, 255),
          g.clamp(0, 255),
          b.clamp(0, 255),
          255,
        );
        index++;
      }
    }

    final cropSize = (rgb.width * 0.7).toInt();
    final cropped = img.copyCrop(
      rgb,
      x: (rgb.width - cropSize) ~/ 2,
      y: (rgb.height - cropSize) ~/ 2,
      width: cropSize,
      height: cropSize,
    );

    final rotated = img.copyRotate(cropped, angle: 90);
    final resized = img.copyResize(rotated, width: 640);

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/frame_${DateTime.now().millisecondsSinceEpoch}.jpg',
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
      body: Stack(
        children: [
          CameraPreview(_controller!),

          // ⏳ Loader
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),

      // 👇 CUSTOM BOTTOM BUTTONS
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 🖼 Gallery button (LEFT)
            FloatingActionButton(
              heroTag: "gallery",
              onPressed: _isProcessing ? null : _pickFromGallery,
              child: const Icon(Icons.photo_library),
            ),

            // 📸 Camera button (CENTER)
            FloatingActionButton(
              heroTag: "camera",
              onPressed: _isProcessing ? null : _captureFrame,
              child: const Icon(Icons.camera),
            ),
          ],
        ),
      ),
    );
  }
}
