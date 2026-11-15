import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageService {
  static Future<File?> compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final path = file.absolute.path;
    final outPath = p.join(tempDir.path, 'compressed_${p.basename(path)}');

    final result = await FlutterImageCompress.compressAndGetFile(
      path,
      outPath,
      quality: 70, // 70% quality is usually good enough for mobile apps
      minWidth: 1024,
      minHeight: 1024,
    );

    if (result == null) return null;
    return File(result.path);
  }

  static Future<Uint8List?> compressUint8List(Uint8List list) async {
    final result = await FlutterImageCompress.compressWithList(
      list,
      quality: 70,
      minWidth: 1024,
      minHeight: 1024,
    );
    return result;
  }
}
