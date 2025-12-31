import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_keys.dart';
class ImageValidationService {
  static const String _apiKey = ApiKeys.googleVisionApiKey;
  static const String _visionApiUrl = 
      'https://vision.googleapis.com/v1/images:annotate?key=$_apiKey';

  // List of non-wearable categories to reject
  static const List<String> _rejectedCategories = [
    'car', 'vehicle', 'automobile', 'truck', 'motorcycle', 'bike',
    'house', 'building', 'home', 'property', 'real estate',
    'furniture', 'table', 'chair', 'sofa', 'couch',
    'electronics', 'television', 'tv', 'computer', 'laptop',
    'appliance', 'refrigerator', 'washing machine',
    'pet', 'dog', 'cat', 'animal',
    'food', 'meal', 'dish',
  ];

  // Wearable/fashion categories we allow
  static const List<String> _allowedCategories = [
    'clothing', 'fashion', 'apparel', 'shirt', 'pants', 'dress',
    'shoe', 'footwear', 'sneaker', 'boot', 'sandal',
    'bag', 'handbag', 'backpack', 'purse', 'wallet',
    'accessory', 'jewelry', 'watch', 'necklace', 'bracelet',
    'hat', 'cap', 'beanie', 'sunglasses', 'belt', 'scarf',
    'jacket', 'coat', 'sweater', 'hoodie', 'jeans',
  ];

  /// Validates if an image contains wearable items
  /// Returns a Map with 'isValid' (bool) and 'message' (String)
  Future<Map<String, dynamic>> validateImage(XFile imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Prepare API request
      final requestBody = {
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 20},
              {'type': 'OBJECT_LOCALIZATION', 'maxResults': 10},
            ],
          }
        ]
      };

      // Call Vision API
      final response = await http.post(
        Uri.parse(_visionApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        return {
          'isValid': false,
          'message': 'Failed to validate image. Please try again.',
        };
      }

      final data = jsonDecode(response.body);
      final labels = data['responses'][0]['labelAnnotations'] as List? ?? [];
      final objects = data['responses'][0]['localizedObjectAnnotations'] as List? ?? [];

      // Extract all detected labels and objects
      final detectedItems = <String>[];
      
      for (var label in labels) {
        detectedItems.add((label['description'] as String).toLowerCase());
      }
      
      for (var object in objects) {
        detectedItems.add((object['name'] as String).toLowerCase());
      }

      print('Detected items: $detectedItems'); // For debugging

      // Check if any rejected category is detected
      for (var item in detectedItems) {
        for (var rejected in _rejectedCategories) {
          if (item.contains(rejected) || rejected.contains(item)) {
            return {
              'isValid': false,
              'message': 'This item is not a wearable product. Please only post clothing, shoes, bags, or accessories.',
              'detectedItem': item,
            };
          }
        }
      }

      // Check if at least one allowed category is detected
      bool hasWearableItem = false;
      for (var item in detectedItems) {
        for (var allowed in _allowedCategories) {
          if (item.contains(allowed) || allowed.contains(item)) {
            hasWearableItem = true;
            break;
          }
        }
        if (hasWearableItem) break;
      }

      if (!hasWearableItem) {
        return {
          'isValid': false,
          'message': 'Unable to identify this as a wearable item. Please ensure your photo clearly shows clothing, shoes, bags, or accessories.',
        };
      }

      return {
        'isValid': true,
        'message': 'Image validated successfully!',
        'detectedItems': detectedItems,
      };

    } catch (e) {
      print('Image validation error: $e');
      return {
        'isValid': false,
        'message': 'Error validating image: $e',
      };
    }
  }

  /// Validates multiple images
  Future<Map<String, dynamic>> validateImages(List<XFile> imageFiles) async {
    for (int i = 0; i < imageFiles.length; i++) {
      final result = await validateImage(imageFiles[i]);
      if (!result['isValid']) {
        return {
          'isValid': false,
          'message': 'Image ${i + 1}: ${result['message']}',
        };
      }
    }

    return {
      'isValid': true,
      'message': 'All images validated successfully!',
    };
  }
}