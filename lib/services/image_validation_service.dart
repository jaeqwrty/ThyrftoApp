import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_keys.dart';

class ImageValidationService {
  static const String _apiKey = ApiKeys.googleVisionApiKey;
  static const String _visionApiUrl = 
      'https://vision.googleapis.com/v1/images:annotate?key=$_apiKey';

  // List of non-wearable categories to reject (only when NO wearable detected)
  static const List<String> _rejectedCategories = [
    'car', 'vehicle', 'automobile', 'truck', 'motorcycle',
    'house', 'building', 'home', 'property',
    'furniture', 'table', 'chair', 'sofa', 'couch',
    'electronics', 'television', 'tv', 'computer', 'laptop',
    'appliance', 'refrigerator', 'washing machine',
  ];

  // Wearable/fashion categories (expanded list)
  static const List<String> _allowedCategories = [
    // Clothing
    'clothing', 'fashion', 'apparel', 'shirt', 'pants', 'dress',
    'top', 't-shirt', 'tshirt', 'tee', 'blouse', 'polo',
    'jacket', 'coat', 'sweater', 'hoodie', 'jeans', 'shorts',
    'skirt', 'suit', 'blazer', 'vest', 'cardigan',
    'sleeve', 'collar', 'garment', 'outfit', 'wear',
    
    // Footwear
    'shoe', 'footwear', 'sneaker', 'boot', 'sandal',
    'heel', 'loafer', 'slipper', 'cleat',
    
    // Bags
    'bag', 'handbag', 'backpack', 'purse', 'wallet',
    'tote', 'clutch', 'satchel', 'luggage',
    
    // Accessories
    'accessory', 'jewelry', 'watch', 'necklace', 'bracelet',
    'hat', 'cap', 'beanie', 'sunglasses', 'belt', 'scarf',
    'glove', 'tie', 'bowtie', 'ring', 'earring',
    
    // Related terms
    'textile', 'fabric', 'cotton', 'denim', 'leather',
    'wool', 'silk', 'polyester', 'material',
  ];

  // Visual cues that suggest wearable items
  static const List<String> _visualCues = [
    'hanger', 'clothing hanger', 'coat hanger',
    'mannequin', 'model', 'worn', 'outfit',
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
              {'type': 'LABEL_DETECTION', 'maxResults': 25},
              {'type': 'OBJECT_LOCALIZATION', 'maxResults': 15},
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

      // Extract all detected labels and objects with scores
      final detectedItems = <String>[];
      final detectedScores = <double>[];
      
      for (var label in labels) {
        detectedItems.add((label['description'] as String).toLowerCase());
        detectedScores.add((label['score'] as num?)?.toDouble() ?? 0.0);
      }
      
      for (var object in objects) {
        detectedItems.add((object['name'] as String).toLowerCase());
        detectedScores.add((object['score'] as num?)?.toDouble() ?? 0.0);
      }

      print('Detected items: $detectedItems'); // For debugging

      // Calculate wearable confidence score
      double wearableScore = 0.0;
      int wearableMatches = 0;
      
      for (int i = 0; i < detectedItems.length; i++) {
        final item = detectedItems[i];
        final score = detectedScores.length > i ? detectedScores[i] : 0.7;
        
        // Check for wearable items
        for (var allowed in _allowedCategories) {
          if (item.contains(allowed) || allowed.contains(item)) {
            wearableScore += score;
            wearableMatches++;
            break;
          }
        }
        
        // Check for visual cues (like hangers)
        for (var cue in _visualCues) {
          if (item.contains(cue) || cue.contains(item)) {
            wearableScore += score * 0.5; // Half weight for visual cues
            break;
          }
        }
      }

      print('Wearable score: $wearableScore, Matches: $wearableMatches');

      // More lenient threshold: accept if score > 0.3 OR at least 1 match
      bool hasWearableItem = wearableScore > 0.3 || wearableMatches >= 1;

      // If no wearable item detected, check for clearly rejected categories
      if (!hasWearableItem) {
        bool hasRejectedItem = false;
        String? rejectedItemName;
        
        for (var item in detectedItems) {
          for (var rejected in _rejectedCategories) {
            if (item == rejected || item.contains(rejected)) {
              hasRejectedItem = true;
              rejectedItemName = item;
              break;
            }
          }
          if (hasRejectedItem) break;
        }

        if (hasRejectedItem) {
          return {
            'isValid': false,
            'message': 'This appears to be a ${rejectedItemName ?? "non-wearable item"}. Please only post clothing, shoes, bags, or accessories.',
            'detectedItem': rejectedItemName,
          };
        }

        // No wearable or clearly rejected item found
        return {
          'isValid': false,
          'message': 'Unable to identify this as a wearable item. Please ensure your photo clearly shows clothing, shoes, bags, or accessories.',
        };
      }

      // Wearable item detected - validation passed!
      return {
        'isValid': true,
        'message': 'Image validated successfully!',
        'detectedItems': detectedItems,
        'wearableScore': wearableScore,
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