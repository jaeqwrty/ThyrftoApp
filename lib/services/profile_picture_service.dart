import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ProfileImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Upload profile image to Firebase Storage with detailed error handling
  Future<String?> uploadProfileImage(XFile imageFile, String userId) async {
    try {
      print('📄 Starting profile image upload for user: $userId');
      
      // Validate file
      if (!await imageFile.length().then((len) => len > 0)) {
        print('❌ Error: Image file is empty');
        return null;
      }

      // Get file extension
      String ext = path.extension(imageFile.name).toLowerCase();
      if (ext.isEmpty) {
        ext = '.jpg';
        print('⚠️ No extension found, using .jpg');
      }
      
      final fileName = 'profile_$userId$ext';
      // FIXED: Changed from 'profiles/$userId/$fileName' to 'profile_images/$userId/$fileName'
      final storageRef = _storage.ref().child('profile_images/$userId/$fileName');
      
      print('📍 Upload path: profile_images/$userId/$fileName');
      
      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      print('📊 Image size: ${bytes.length} bytes');
      
      if (bytes.isEmpty) {
        print('❌ Error: Image bytes are empty');
        return null;
      }
      
      // Determine content type
      final contentType = _getContentType(imageFile.name);
      print('📝 Content type: $contentType');
      
      // Upload with proper content type and metadata
      print('⬆️ Starting upload...');
      final uploadTask = await storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedBy': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      print('✅ Upload completed');
      
      // Get and return download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('🔗 Download URL obtained: ${downloadUrl.substring(0, 50)}...');
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('❌ Firebase Error uploading profile image:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Details: ${e.stackTrace}');
      return null;
    } catch (e, stackTrace) {
      print('❌ Error uploading profile image: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Delete profile image from Firebase Storage
  Future<bool> deleteProfileImage(String userId) async {
    try {
      print('🗑️ Deleting profile images for user: $userId');
      
      // FIXED: Changed from 'profiles/$userId' to 'profile_images/$userId'
      final profileFolder = _storage.ref().child('profile_images/$userId');
      final listResult = await profileFolder.listAll();
      
      print('📁 Found ${listResult.items.length} files to delete');
      
      // Delete all files in the user's profile folder
      for (var item in listResult.items) {
        print('   Deleting: ${item.name}');
        await item.delete();
      }
      
      print('✅ Profile images deleted successfully');
      return true;
    } on FirebaseException catch (e) {
      print('❌ Firebase Error deleting profile image:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      
      // If the folder doesn't exist, that's not really an error
      if (e.code == 'object-not-found') {
        print('ℹ️ No existing images to delete');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error deleting profile image: $e');
      return false;
    }
  }

  /// Get content type based on file extension
  String _getContentType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      default:
        print('⚠️ Unknown extension: $ext, using image/jpeg');
        return 'image/jpeg';
    }
  }

  /// Update profile image and return new URL
  /// If imageFile is null, it will delete the existing image
  Future<String?> updateProfileImage({
    required String userId,
    XFile? imageFile,
    bool deleteExisting = false,
  }) async {
    try {
      print('🔄 Updating profile image for user: $userId');
      print('   Delete existing: $deleteExisting');
      print('   New image provided: ${imageFile != null}');
      
      // Delete existing image if requested
      if (deleteExisting) {
        print('🗑️ Deleting existing image...');
        await deleteProfileImage(userId);
        return '';
      }

      // Upload new image if provided
      if (imageFile != null) {
        // Delete old image first
        print('🗑️ Deleting old image before upload...');
        await deleteProfileImage(userId);
        
        // Upload new image
        print('⬆️ Uploading new image...');
        final newUrl = await uploadProfileImage(imageFile, userId);
        
        if (newUrl == null) {
          print('❌ Upload returned null');
        } else {
          print('✅ Upload successful');
        }
        
        return newUrl;
      }

      print('ℹ️ No changes to profile image');
      return null;
    } catch (e, stackTrace) {
      print('❌ Error updating profile image: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Validate image file before upload
  Future<Map<String, dynamic>> validateImage(XFile imageFile) async {
    try {
      // Check file size (max 5MB)
      final bytes = await imageFile.readAsBytes();
      final sizeInMB = bytes.length / (1024 * 1024);
      
      if (sizeInMB > 5) {
        return {
          'valid': false,
          'message': 'Image size must be less than 5MB (current: ${sizeInMB.toStringAsFixed(2)}MB)'
        };
      }

      // Check file extension
      final ext = path.extension(imageFile.name).toLowerCase();
      final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'];
      
      if (ext.isNotEmpty && !validExtensions.contains(ext)) {
        return {
          'valid': false,
          'message': 'Invalid file type. Please use: ${validExtensions.join(", ")}'
        };
      }

      return {'valid': true, 'message': 'Image is valid'};
    } catch (e) {
      return {'valid': false, 'message': 'Error validating image: $e'};
    }
  }
}