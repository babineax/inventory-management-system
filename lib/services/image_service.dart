import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const Uuid _uuid = Uuid();

  /// Uploads a profile image to Firebase Storage and returns the download URL
  static Future<String?> uploadProfileImage(File imageFile) async {
    try {
      // Create a unique filename using UUID
      final String fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';

      // Reference to the file location in Firebase Storage
      final Reference storageRef =
          _storage.ref().child('profile_images/$fileName');

      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(imageFile);

      // Wait for the upload to complete and get the download URL
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  /// Uploads an inventory item image to Firebase Storage and returns the download URL
  static Future<String?> uploadInventoryImage(File imageFile) async {
    try {
      // Create a unique filename using UUID
      final String fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';

      // Reference to the file location in Firebase Storage
      final Reference storageRef =
          _storage.ref().child('inventory_images/$fileName');

      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(imageFile);

      // Wait for the upload to complete and get the download URL
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading inventory image: $e');
      return null;
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
      print('Error deleting image: $e');
      return false;
    }
  }
}
