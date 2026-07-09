import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:thryfto/core/services/cloudinary_service.dart';

class ProfileImageService {
  final CloudinaryService _cloudinary = CloudinaryService();

  /// Upload a profile image to Cloudinary and return the secure URL.
  Future<String?> uploadProfileImage(XFile imageFile, String userId) async {
    try {
      // Validate file is not empty
      final length = await imageFile.length();
      if (length == 0) {
        return null;
      }

      // Upload to Cloudinary under the "profile_images/<userId>" folder
      final url = await _cloudinary.uploadImage(
        imageFile,
        folder: 'profile_images/$userId',
      );

      return url;
    } catch (e) {
      // Return null on failure so callers can handle gracefully
      return null;
    }
  }

  /// Cloudinary does not require explicit deletion for profile images
  /// (old images are simply orphaned and can be cleaned up from the
  /// Cloudinary dashboard). This is a no-op kept for API compatibility.
  Future<bool> deleteProfileImage(String userId) async {
    // No-op: Cloudinary asset management is handled server-side.
    return true;
  }

  /// Update the profile image for [userId].
  ///
  /// - If [deleteExisting] is true the caller wants to clear the image;
  ///   we return an empty string to signal that.
  /// - If [imageFile] is provided the new image is uploaded and its URL
  ///   is returned.
  /// - Returns null if nothing changed.
  Future<String?> updateProfileImage({
    required String userId,
    XFile? imageFile,
    bool deleteExisting = false,
  }) async {
    if (deleteExisting) {
      return '';
    }

    if (imageFile != null) {
      return uploadProfileImage(imageFile, userId);
    }

    return null;
  }

  /// Validate an image file before uploading (max 5 MB, valid extensions).
  Future<Map<String, dynamic>> validateImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final sizeInMB = bytes.length / (1024 * 1024);

      if (sizeInMB > 5) {
        return {
          'valid': false,
          'message':
              'Image size must be less than 5MB (current: ${sizeInMB.toStringAsFixed(2)}MB)',
        };
      }

      final ext = path.extension(imageFile.name).toLowerCase();
      const validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'];

      if (ext.isNotEmpty && !validExtensions.contains(ext)) {
        return {
          'valid': false,
          'message': 'Invalid file type. Please use: ${validExtensions.join(", ")}',
        };
      }

      return {'valid': true, 'message': 'Image is valid'};
    } catch (e) {
      return {'valid': false, 'message': 'Error validating image: $e'};
    }
  }
}