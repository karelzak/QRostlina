import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class LocalImageService {
  static Future<String?> saveImageLocally(File imageFile, String speciesId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/species_images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Use species ID and timestamp to ensure uniqueness and help with debugging
      final extension = p.extension(imageFile.path);
      final fileName = '${speciesId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final localFile = File('${imagesDir.path}/$fileName');

      await imageFile.copy(localFile.path);
      
      // Return the relative path or just the filename to keep it portable
      // Store 'species_images/filename' in the database
      return 'species_images/$fileName';
    } catch (e) {
      print('Error saving image locally: $e');
      return null;
    }
  }

  static Future<File?> getLocalFile(String storedPath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fullPath = '${directory.path}/$storedPath';
      final file = File(fullPath);
      
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      print('Error getting local file: $e');
    }
    return null;
  }

  static bool isRemoteUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }
}
