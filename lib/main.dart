import 'package:flutter/material.dart';
import 'camera_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CameraApp());
}

/// Root widget
class CameraApp extends StatelessWidget {
  const CameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CameraScreen(),
    );
  }
}


