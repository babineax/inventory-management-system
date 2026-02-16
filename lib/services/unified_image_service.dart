import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class UnifiedImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();
  static const Uuid _uuid = Uuid();

  // Pick image from gallery - returns XFile for cross-platform compatibility
  static Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      return pickedFile;
    } catch (e) {

      return null;
    }
  }

  // Pick image from camera - returns XFile for cross-platform compatibility
  static Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      return pickedFile;
    } catch (e) {

      return null;
    }
  }

  /// Uploads a profile image and returns the base64 data URL
  /// Works with both File (mobile/desktop) and XFile (web) objects
  /// Stores images as base64 in Firestore (compatible with free plan)
  static Future<String?> uploadProfileImage(XFile imageFile) async {
    try {

      // Validate file size (max 2MB for base64 storage)
      final fileSize = await imageFile.length();
      if (fileSize > 2 * 1024 * 1024) {
        throw Exception(
            'Image file is too large. Please select an image smaller than 2MB.');
      }

      // Read image as bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Convert to base64
      final String base64String = base64Encode(imageBytes);

      // Create data URL (compatible with previous implementation)
      final String dataUrl = 'data:image/jpeg;base64,$base64String';


      return dataUrl;
    } catch (e) {

      throw Exception('Failed to process image: $e');
    }
  }

  /// Uploads an inventory item image and returns the base64 data URL
  /// Works with both File (mobile/desktop) and XFile (web) objects
  /// Stores images as base64 in Firestore (compatible with free plan)
  static Future<String?> uploadInventoryImage(XFile imageFile) async {
    try {

      // Validate file size (max 2MB for base64 storage)
      final fileSize = await imageFile.length();
      if (fileSize > 2 * 1024 * 1024) {
        throw Exception(
            'Image file is too large. Please select an image smaller than 2MB.');
      }

      // Read image as bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Convert to base64
      final String base64String = base64Encode(imageBytes);

      // Create data URL (compatible with previous implementation)
      final String dataUrl = 'data:image/jpeg;base64,$base64String';


      return dataUrl;
    } catch (e) {

      throw Exception('Failed to process image: $e');
    }
  }

  /// Deletes an image from Firebase Storage given its URL
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Get reference from the URL
      final Reference storageRef = _storage.refFromURL(imageUrl);

      // Delete the file
      await storageRef.delete();

      return true;
    } catch (e) {

      return false;
    }
  }
}
