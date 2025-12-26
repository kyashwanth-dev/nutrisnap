import 'dart:io';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final File imageFile;
  final String geminiResponse;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.geminiResponse,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NutriSnap Analysis")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(imageFile),
            ),
            const SizedBox(height: 16),
            const Text(
              "AI Insights",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(geminiResponse),
          ],
        ),
      ),
    );
  }
}
