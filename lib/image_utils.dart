import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

Future<File> resizeImage(File file) async {
  final bytes = await file.readAsBytes();
  final original = img.decodeImage(bytes);

  if (original == null) {
    throw Exception("Failed to decode image");
  }

  // Resize only if large
  final resized = original.width > 1024
      ? img.copyResize(original, width: 1024)
      : original;

  final dir = file.parent;
  final newPath = path.join(
    dir.path,
    "resized_${path.basename(file.path)}",
  );

  final resizedFile = File(newPath)
    ..writeAsBytesSync(
      img.encodeJpg(resized, quality: 80),
    );

  return resizedFile;
}
