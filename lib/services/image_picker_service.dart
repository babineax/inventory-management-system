import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Show options to pick image from camera or gallery
  static Future<String?> showImagePickerOptions({
    required Function(String imagePath) onImageSelected,
    required Function() onCancel,
  }) async {
    try {
      // For web, we'll use file picker
      if (kIsWeb) {
        return await _pickImageWeb();
      } else {
        // For mobile, we can use both camera and gallery
        return await _pickImageMobile();
      }
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Pick image from camera
  static Future<String?> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return image.path;
      }
      return null;
    } catch (e) {
      print('Error picking from camera: $e');
      return null;
    }
  }

  /// Pick image from gallery
  static Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return image.path;
      }
      return null;
    } catch (e) {
      print('Error picking from gallery: $e');
      return null;
    }
  }

  /// Pick image for web platform
  static Future<String?> _pickImageWeb() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          // For web, we'll return a data URL or save to local storage
          // For now, return the file name as a placeholder
          return file.name;
        }
      }
      return null;
    } catch (e) {
      print('Error picking image on web: $e');
      return null;
    }
  }

  /// Pick image for mobile platform
  static Future<String?> _pickImageMobile() async {
    // This would typically show a dialog to choose between camera and gallery
    // For now, we'll default to gallery
    return await pickFromGallery();
  }

  /// Get image bytes for web
  static Future<Uint8List?> getImageBytes(String imagePath) async {
    try {
      if (kIsWeb) {
        // For web, we need to handle this differently
        // This is a placeholder implementation
        return null;
      } else {
        final file = File(imagePath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
      return null;
    } catch (e) {
      print('Error getting image bytes: $e');
      return null;
    }
  }

  /// Save image to local directory (for mobile)
  static Future<String?> saveImageToLocal(
      String imagePath, String fileName) async {
    try {
      if (kIsWeb) {
        // For web, we'll handle this differently
        return imagePath;
      } else {
        final file = File(imagePath);
        if (await file.exists()) {
          // In a real app, you'd save to app documents directory
          // For now, return the original path
          return imagePath;
        }
      }
      return null;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  /// Validate image file
  static bool isValidImageFile(String fileName) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final extension =
        fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    return validExtensions.contains(extension);
  }

  /// Get file size in MB
  static Future<double> getFileSizeInMB(String filePath) async {
    try {
      if (!kIsWeb) {
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.length();
          return bytes / (1024 * 1024); // Convert to MB
        }
      }
      return 0.0;
    } catch (e) {
      print('Error getting file size: $e');
      return 0.0;
    }
  }

  /// Compress image if needed
  static Future<String?> compressImage(String imagePath) async {
    try {
      // For now, return the original path
      // In a real app, you'd use image compression libraries
      return imagePath;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }
}
