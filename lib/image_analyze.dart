import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
Future<String> analyzeImageWithGemini(String imagePath) async {
  final uri = Uri.parse(
    'https://gemini-backend-rm59.onrender.com/analyze-image',
  );

  final file = File(imagePath);
  final fileSizeKB = await file.length() / 1024;

  // 🔍 Local debug
  debugPrint("📤 Sending image to Gemini:");
  debugPrint("   Path: $imagePath");
  debugPrint("   Size: ${fileSizeKB.toStringAsFixed(1)} KB");

  final request = http.MultipartRequest('POST', uri);

  request.fields['prompt'] =
      'Identify the food item you see in this image,and tell me about them';

  request.files.add(
    await http.MultipartFile.fromPath(
      'image',
      imagePath,
    ),
  );

  // ⏱️ Timeout protection
  final streamedResponse =
      await request.send().timeout(const Duration(seconds: 30));

  final responseBody =
      await streamedResponse.stream.bytesToString();

  // 🔥 IMPORTANT: expose backend error
  if (streamedResponse.statusCode != 200) {
    debugPrint("❌ Gemini backend error:");
    debugPrint(responseBody);

    throw Exception(
      "Gemini analysis failed "
      "(HTTP ${streamedResponse.statusCode}): $responseBody",
    );
  }

  final decoded = jsonDecode(responseBody);

  if (!decoded.containsKey('output')) {
    throw Exception("Invalid Gemini response: $responseBody");
  }

  return decoded['output'];
}
