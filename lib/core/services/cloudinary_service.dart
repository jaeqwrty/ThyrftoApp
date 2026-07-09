import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Centralized Cloudinary upload service.
///
/// Uses unsigned uploads via an upload preset, so no API secret is stored in
/// the client app. Callers should validate/accept images before calling this.
class CloudinaryService {
  static const String _cloudName = 'gvbvhg42';
  static const String _uploadPreset = 'thryfto_images';

  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Uploads one accepted [XFile] and returns its Cloudinary secure URL.
  Future<String?> uploadImage(
    XFile imageFile, {
    String folder = 'listings',
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: imageFile.name,
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception(
          'Cloudinary upload failed [${response.statusCode}]: ${response.body}',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String?;
    } catch (e) {
      throw Exception('Error uploading to Cloudinary: $e');
    }
  }

  /// Uploads accepted images in sequence and returns their secure URLs.
  Future<List<String>> uploadImages(
    List<XFile> imageFiles, {
    String folder = 'listings',
  }) async {
    final urls = <String>[];

    for (final file in imageFiles) {
      final url = await uploadImage(file, folder: folder);
      if (url != null) {
        urls.add(url);
      }
    }

    return urls;
  }
}
