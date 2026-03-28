import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:firebase_storage/firebase_storage.dart';
import 'service_locator.dart';

class LocalImageService {
  static Future<String?> saveImageLocally(File imageFile, String speciesId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/species_images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final extension = p.extension(imageFile.path);
      final fileName = '${speciesId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final localFile = File('${imagesDir.path}/$fileName');

      await imageFile.copy(localFile.path);
      
      String relativePath = 'species_images/$fileName';

      // If we are in cloud mode, also upload to Firebase Storage
      if (locator.isCloudMode) {
        final cloudUrl = await uploadToCloud(localFile, speciesId);
        if (cloudUrl != null) {
          return cloudUrl;
        }
      }

      return relativePath;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }

  static Future<String?> uploadToCloud(File file, String speciesId) async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      try {
        final fileName = p.basename(file.path);
        final ref = FirebaseStorage.instance.ref().child('species_images/$speciesId/$fileName');
        final uploadTask = await ref.putFile(file);
        return await uploadTask.ref.getDownloadURL();
      } catch (e) {
        debugPrint('Error uploading to Firebase Storage: $e');
        return null;
      }
    }
    return null;
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
      debugPrint('Error getting local file: $e');
    }
    return null;
  }

  static bool isRemoteUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  static Future<void> deleteImage(String path) async {
    try {
      if (isRemoteUrl(path)) {
        if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
          final ref = FirebaseStorage.instance.refFromURL(path);
          await ref.delete();
        }
      } else {
        final file = await getLocalFile(path);
        if (file != null && await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }
}
