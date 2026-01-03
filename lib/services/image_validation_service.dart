import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_keys.dart';

class ImageValidationService {
  static const String _apiKey = ApiKeys.googleVisionApiKey;
  static const String _visionApiUrl =
      'https://vision.googleapis.com/v1/images:annotate?key=$_apiKey';

  // List of non-wearable categories to reject with high priority
  static const List<String> _rejectedCategories = [
    'car',
    'vehicle',
    'automobile',
    'truck',
    'van',
    'motorcycle',
    'motorbike',
    'scooter',
    'bike',
    'bicycle',
    'motor vehicle',
    'automotive',
    'transport',
    'wheel',
    'tire',
    'engine',
    'house',
    'building',
    'home',
    'property',
    'architecture',
    'furniture',
    'table',
    'chair',
    'sofa',
    'couch',
    'bed',
    'electronics',
    'television',
    'tv',
    'computer',
    'laptop',
    'phone',
    'appliance',
    'refrigerator',
    'washing machine',
    'microwave',
    'food',
    'meal',
    'dish',
    'drink',
    'beverage',
    'plant',
    'tree',
    'flower',
    'garden',
    'tool',
    'equipment',
    'machinery',
    'animal',
    'pet',
    'dog',
    'cat',
  ];

  // High-priority rejections (vehicles, buildings, furniture, appliances) - always reject these
  static const List<String> _alwaysRejectCategories = [
    // Vehicles
    'car',
    'vehicle',
    'automobile',
    'truck',
    'van',
    'motorcycle',
    'motorbike',
    'scooter',
    'motor vehicle',
    'automotive',
    'bicycle',
    // Buildings/Property
    'house',
    'home',
    'building',
    'property',
    'real estate',
    'architecture',
    'apartment',
    'residence',
    'room',
    'interior',
    // Furniture
    'furniture',
    'table',
    'chair',
    'sofa',
    'couch',
    'bed',
    'desk',
    'cabinet',
    'shelf',
    'drawer',
    'wardrobe',
    'closet',
    'mattress',
    'bookshelf',
    'stool',
    'bench',
    'ottoman',
    'recliner',
    'armchair',
    // Home Appliances
    'appliance',
    'refrigerator',
    'fridge',
    'washing machine',
    'dryer',
    'microwave',
    'oven',
    'stove',
    'dishwasher',
    'air conditioner',
    'heater',
    'fan',
    'vacuum',
    'blender',
    'toaster',
    'coffee maker',
    'television',
    'tv',
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
    'hanger',
    'clothing hanger',
    'coat hanger',
    'mannequin',
    'model',
    'person',
    'human',
    'worn',
    'outfit',
  ];

  // Core fabric/material terms that suggest wearable items
  static const List<String> _fabricIndicators = [
    'clothing',
    'fabric',
    'textile',
    'garment',
    'apparel',
    'shirt',
    'top',
    'dress',
    'pants',
    'jacket',
    'coat',
    'sleeve',
    'collar',
    'wear',
    'fashion',
    // Bag materials
    'leather',
    'canvas',
    'nylon',
    'bag',
    'handbag',
    'backpack',
    'purse',
    'tote',
    'luggage',
    // Shoe materials
    'shoe',
    'footwear',
    'sneaker',
    'boot',
    // Accessories
    'accessory',
    'jewelry',
    'watch',
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
      final objects =
          data['responses'][0]['localizedObjectAnnotations'] as List? ?? [];

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

      // CRITICAL: Check for fabric/clothing indicators FIRST
      // Must have fabric/material detection to proceed
      bool hasFabricDetection = false;
      for (var item in detectedItems) {
        for (var fabric in _fabricIndicators) {
          if (item.contains(fabric) || fabric.contains(item)) {
            hasFabricDetection = true;
            break;
          }
        }
        if (hasFabricDetection) break;
      }

      // Check for visual context (hanger, mannequin, person)
      bool hasValidContext = false;
      for (var item in detectedItems) {
        for (var cue in _visualCues) {
          if (item.contains(cue) || cue.contains(item)) {
            hasValidContext = true;
            break;
          }
        }
        if (hasValidContext) break;
      }

      print('Has fabric: $hasFabricDetection, Has context: $hasValidContext');

      // FIRST: Check for high-priority rejections (vehicles) - ALWAYS reject these
      for (int i = 0; i < detectedItems.length; i++) {
        final item = detectedItems[i];
        final score = detectedScores.length > i ? detectedScores[i] : 0.0;

        for (var rejected in _alwaysRejectCategories) {
          if (item == rejected || item.contains(rejected) || rejected.contains(item)) {
            // Reject vehicles with any reasonable confidence (> 0.5) in top 10 results
            if (score > 0.5 || i < 10) {
              return {
                'isValid': false,
                'message':
                    'This appears to be a ${item}. Please only post clothing, shoes, bags, or accessories.',
                'detectedItem': item,
              };
            }
          }
        }
      }

      // Calculate wearable confidence score FIRST
      double wearableScore = 0.0;
      int wearableMatches = 0;
      double maxWearableScore = 0.0;

      for (int i = 0; i < detectedItems.length; i++) {
        final item = detectedItems[i];
        final score = detectedScores.length > i ? detectedScores[i] : 0.7;

        // Check for wearable items
        for (var allowed in _allowedCategories) {
          if (item.contains(allowed) || allowed.contains(item)) {
            wearableScore += score;
            wearableMatches++;
            if (score > maxWearableScore) maxWearableScore = score;
            break;
          }
        }
      }

      print(
          'Wearable score: $wearableScore, Matches: $wearableMatches, Max score: $maxWearableScore');

      // If we have ANY wearable detection, be more lenient
      bool hasWearableDetection = wearableMatches >= 1 && maxWearableScore > 0.4;

      // Check for rejected categories with HIGH confidence first
      for (int i = 0; i < detectedItems.length; i++) {
        final item = detectedItems[i];
        final score = detectedScores.length > i ? detectedScores[i] : 0.0;

        for (var rejected in _rejectedCategories) {
          if (item == rejected ||
              item.contains(rejected) ||
              rejected.contains(item)) {
            // Only reject if HIGH confidence AND no wearable detection
            if (score > 0.7 && i < 3 && !hasWearableDetection) {
              return {
                'isValid': false,
                'message':
                    'This appears to be a ${item}. Please only post clothing, shoes, bags, or accessories.',
                'detectedItem': item,
              };
            }
          }
        }
      }

      // Accept if we have wearable detection
      if (hasWearableDetection) {
        return {
          'isValid': true,
          'message': 'Image validated successfully!',
          'detectedItems': detectedItems,
          'wearableScore': wearableScore,
          'wearableMatches': wearableMatches,
        };
      }

      // Accept if fabric/context detected (even without strong wearable score)
      if (hasFabricDetection || hasValidContext) {
        return {
          'isValid': true,
          'message': 'Image validated successfully!',
          'detectedItems': detectedItems,
          'wearableScore': wearableScore,
          'wearableMatches': wearableMatches,
        };
      }

      // No wearable indicators found - check if it's clearly a rejected item
      for (var item in detectedItems) {
        for (var rejected in _rejectedCategories) {
          if (item == rejected || item.contains(rejected)) {
            return {
              'isValid': false,
              'message':
                  'This appears to be a ${item}, not a wearable item. Please only post clothing, shoes, bags, or accessories.',
              'detectedItem': item,
            };
          }
        }
      }

      // If nothing clearly identified, give benefit of the doubt
      // Only reject if we're confident it's NOT a wearable
      if (detectedItems.isNotEmpty && wearableScore == 0.0) {
        return {
          'isValid': false,
          'message':
              'Unable to identify this as a wearable item. Please ensure your photo clearly shows clothing, shoes, bags, or accessories.',
        };
      }

      // Default to accepting unclear images
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
