import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'image_analyze.dart';
import 'result_screen.dart';

class GalleryUploadScreen extends StatefulWidget {
  const GalleryUploadScreen({super.key});

  @override
  State<GalleryUploadScreen> createState() =>
      _GalleryUploadScreenState();
}

class _GalleryUploadScreenState extends State<GalleryUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _pickAndAnalyzeImage() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 📂 Pick image from gallery
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final File imageFile = File(pickedFile.path);

      debugPrint("📤 Selected image: ${imageFile.path}");
      debugPrint("📦 Size: ${await imageFile.length()} bytes");

      // 🔥 Send to Gemini
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
      debugPrint("❌ Gallery upload error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Food Image"),
      ),
      body: Stack(
        children: [
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text("Pick Image from Gallery"),
              onPressed: _isProcessing ? null : _pickAndAnalyzeImage,
            ),
          ),

          // ⏳ Loader overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
