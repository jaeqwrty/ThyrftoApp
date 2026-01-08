import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_keys.dart';

class ImageValidationService {
  static const String _apiKey = ApiKeys.googleVisionApiKey;
  static const String _visionApiUrl =
      'https://vision.googleapis.com/v1/images:annotate?key=$_apiKey';

  // CRITICAL: High-priority rejections - ALWAYS reject regardless of other detections
  // These are items that should NEVER be accepted even if wearable items are also detected
  static const List<String> _absoluteRejectCategories = [
    // Vehicles - strict matching
    'motorcycle',
    'motorbike',
    'motor scooter',
    'scooter',
    'moped',
    'dirt bike',
    'chopper',
    'harley',
    'vespa',
    'car',
    'automobile',
    'truck',
    'van',
    'suv',
    'sedan',
    'vehicle',
    'motor vehicle',
    'land vehicle',
    'automotive',
    'bicycle',
    'bike',
    'cycling',
    'bmx',
    'mountain bike',
    // Vehicle parts that indicate vehicle photos
    'wheel',
    'tire',
    'exhaust',
    'headlight',
    'taillight',
    'bumper',
    'engine',
    'handlebar',
    'speedometer',
    'dashboard',
    'windshield',
    'license plate',
    'fender',
    'chassis',
    'fuel tank',
  ];

  // Food & Beverage - very strict rejection
  static const List<String> _foodRejectCategories = [
    'food',
    'meal',
    'dish',
    'cuisine',
    'recipe',
    'cooking',
    'baked goods',
    'fast food',
    'junk food',
    'street food',
    'snack',
    'snack food',
    'breakfast',
    'lunch',
    'dinner',
    'brunch',
    // Specific food items
    'wrap',
    'food wrap',
    'tortilla wrap',
    'burrito',
    'taco',
    'sandwich',
    'sub sandwich',
    'burger',
    'hamburger',
    'cheeseburger',
    'hot dog',
    'pizza',
    'pasta',
    'noodles',
    'rice',
    'sushi',
    'salad',
    'soup',
    'stew',
    'bread',
    'toast',
    'bagel',
    'croissant',
    'pastry',
    'donut',
    'doughnut',
    'muffin',
    'cake',
    'pie',
    'cookie',
    'biscuit',
    'dessert',
    'ice cream',
    'candy',
    'chocolate',
    'fruit',
    'vegetable',
    'meat',
    'chicken',
    'beef',
    'pork',
    'fish',
    'seafood',
    'egg',
    'cheese',
    'dairy',
    // Drinks
    'drink',
    'beverage',
    'coffee',
    'tea',
    'juice',
    'soda',
    'soft drink',
    'smoothie',
    'milkshake',
    'alcohol',
    'beer',
    'wine',
    'cocktail',
    // Food-related
    'ingredient',
    'produce',
    'grocery',
    'edible',
    'consumable',
    'plate',
    'platter',
    'bowl',
    'cup',
    'glass',
    'mug',
    'tableware',
    'cutlery',
    'utensil',
    'fork',
    'spoon',
    'knife',
    'napkin',
    'restaurant',
    'cafe',
    'diner',
    'kitchen',
  ];

  // General rejection categories
  static const List<String> _rejectedCategories = [
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
    'exterior',
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
    // Electronics
    'electronics',
    'computer',
    'laptop',
    'phone',
    'smartphone',
    'tablet',
    'camera',
    'monitor',
    'screen',
    'keyboard',
    'mouse',
    'speaker',
    'headphones',
    // Nature/Plants
    'plant',
    'tree',
    'flower',
    'garden',
    'grass',
    'nature',
    'landscape',
    // Animals
    'animal',
    'pet',
    'dog',
    'cat',
    'bird',
    'fish',
    'mammal',
    'reptile',
    // Tools/Equipment
    'tool',
    'equipment',
    'machinery',
    'instrument',
    'device',
    // Sports equipment (not wearable) - excluding 'ball' as it causes false positives with shoes
    'racket',
    'bat',
    'goal',
    'net',
    'gym equipment',
    'dumbbell',
    'barbell',
    'treadmill',
    // Other
    'toy',
    'game',
    'book',
    'document',
    'paper',
    'artwork',
    'painting',
    'sculpture',
    'money',
    'currency',
    'cash',
  ];

  // Wearable/fashion categories (expanded list)
  static const List<String> _allowedCategories = [
    // Clothing
    'clothing', 'fashion', 'apparel', 'shirt', 'pants', 'dress',
    'top', 't-shirt', 'tshirt', 'tee', 'blouse', 'polo',
    'jacket', 'coat', 'sweater', 'hoodie', 'jeans', 'shorts',
    'skirt', 'suit', 'blazer', 'vest', 'cardigan', 'pullover',
    'sleeve', 'collar', 'garment', 'outfit', 'wear', 'sweatshirt',
    'knit', 'knitwear', 'knitted', 'button-up', 'zipper',

    // Footwear
    'shoe', 'footwear', 'sneaker', 'boot', 'sandal',
    'heel', 'loafer', 'slipper', 'cleat', 'slide', 'clog',
    'flip-flop', 'mule', 'espadrille',

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

  // Helper method for word boundary matching
  static bool _matchesWithWordBoundary(String item, String pattern) {
    if (item == pattern) return true;
    final itemWords = item.split(RegExp(r'[\s\-_/]'));
    final patternWords = pattern.split(RegExp(r'[\s\-_/]'));
    for (var word in patternWords) {
      if (word.length > 2 && itemWords.contains(word)) return true;
    }
    if (pattern.length > 3) {
      return RegExp(r'\b' + RegExp.escape(pattern) + r'\b').hasMatch(item);
    }
    return false;
  }

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
              {'type': 'LABEL_DETECTION', 'maxResults': 30},
              {'type': 'OBJECT_LOCALIZATION', 'maxResults': 20},
              {'type': 'FACE_DETECTION', 'maxResults': 10},
            ],
          }
        ]
      };

      // Call Vision API
      final response = await http
          .post(
            Uri.parse(_visionApiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('Vision API Response Status: ${response.statusCode}');
      print('Vision API Response Body: ${response.body}');

      if (response.statusCode != 200) {
        print('Vision API Error: ${response.body}');
        return {
          'isValid': false,
          'message':
              'Failed to validate image. Please check your internet connection and try again.',
        };
      }

      final data = jsonDecode(response.body);

      // Check for API errors
      if (data['responses'] == null || data['responses'].isEmpty) {
        print('Vision API returned no responses');
        return {
          'isValid': false,
          'message':
              'Image validation service unavailable. Please try again later.',
        };
      }

      final firstResponse = data['responses'][0];
      if (firstResponse.containsKey('error')) {
        print('Vision API Error in response: ${firstResponse['error']}');
        return {
          'isValid': false,
          'message': 'Image validation failed. Please try a different image.',
        };
      }

      final labels = firstResponse['labelAnnotations'] as List? ?? [];
      final objects =
          firstResponse['localizedObjectAnnotations'] as List? ?? [];
      final faces = firstResponse['faceAnnotations'] as List? ?? [];

      // ========================================
      // STEP 0: FACE DETECTION CHECK (HIGHEST PRIORITY!)
      // Reject if a face is the focus of the image
      // ========================================
      if (faces.isNotEmpty) {
        print('👤 Detected ${faces.length} face(s)');

        // Check if any face takes up a significant portion of the image
        // or has high detection confidence (indicating it's prominent)
        if (faces.length >= 2) {
          print('❌ FACE REJECTION: Multiple faces detected');
          return {
            'isValid': false,
            'message':
                'Please focus on the item. Photos with multiple people are not suitable.',
            'detectedItem': 'multiple faces',
          };
        }

        for (var face in faces) {
          final confidence =
              (face['detectionConfidence'] as num?)?.toDouble() ?? 0.0;
          final vertices = face['boundingPoly']?['vertices'] as List?;

          if (confidence > 0.85) {
            print('❌ FACE REJECTION: High confidence ($confidence)');
            return {
              'isValid': false,
              'message': 'Please focus on the item, not on faces.',
              'detectedItem': 'face',
            };
          }

          if (vertices != null && vertices.length >= 4) {
            final xs = vertices.map((v) => (v['x'] as num?)?.toDouble() ?? 0.0);
            final ys = vertices.map((v) => (v['y'] as num?)?.toDouble() ?? 0.0);
            final area = (xs.reduce((a, b) => a > b ? a : b) -
                    xs.reduce((a, b) => a < b ? a : b)) *
                (ys.reduce((a, b) => a > b ? a : b) -
                    ys.reduce((a, b) => a < b ? a : b));

            if (confidence > 0.7 || area > 40000) {
              print('❌ FACE REJECTION: Prominent face');
              return {
                'isValid': false,
                'message': 'Please focus on the item, not on faces.',
                'detectedItem': 'face',
              };
            }
          }
        }
      }

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

      print('🔍 Detected items: $detectedItems');
      print('📊 Scores: $detectedScores');

      // ========================================
      // STEP 1: ABSOLUTE REJECTION CHECK (FIRST!)
      // Check for vehicles/motorcycles - ALWAYS reject, no exceptions
      // ========================================
      for (int i = 0; i < detectedItems.length; i++) {
        final item = detectedItems[i];
        final score = detectedScores.length > i ? detectedScores[i] : 0.0;

        for (var rejected in _absoluteRejectCategories) {
          if (_matchesWithWordBoundary(item, rejected) &&
              (score > 0.25 || i < 20)) {
            print(
                '❌ ABSOLUTE REJECTION: Found "$item" matching "$rejected" (score: $score, index: $i)');
            return {
              'isValid': false,
              'message':
                  'Unable to identify suitable item in this image. Please try a different photo.',
              'detectedItem': item,
            };
          }
        }
      }

      // STEP 2: FOOD REJECTION CHECK
      for (int i = 0; i < detectedItems.length; i++) {
        final item = detectedItems[i];
        final score = detectedScores.length > i ? detectedScores[i] : 0.0;

        for (var foodItem in _foodRejectCategories) {
          if (_matchesWithWordBoundary(item, foodItem) &&
              (score > 0.3 || i < 15)) {
            print(
                '❌ FOOD REJECTION: Found "$item" matching "$foodItem" (score: $score, index: $i)');
            return {
              'isValid': false,
              'message':
                  'Unable to identify suitable item in this image. Please try a different photo.',
              'detectedItem': item,
            };
          }
        }
      }

      // STEP 3: GENERAL REJECTION CHECK
      for (int i = 0; i < detectedItems.length; i++) {
        final item = detectedItems[i];
        final score = detectedScores.length > i ? detectedScores[i] : 0.0;

        for (var rejected in _rejectedCategories) {
          if (_matchesWithWordBoundary(item, rejected) &&
              score > 0.5 &&
              i < 10) {
            print(
                '❌ GENERAL REJECTION: Found "$item" matching "$rejected" (score: $score, index: $i)');
            return {
              'isValid': false,
              'message':
                  'Unable to identify suitable item in this image. Please try a different photo.',
              'detectedItem': item,
            };
          }
        }
      }

      // STEP 4: WEARABLE DETECTION
      double maxScore = 0.0;
      int matches = 0;

      for (int i = 0; i < detectedItems.length; i++) {
        final item = detectedItems[i];
        final score = detectedScores.length > i ? detectedScores[i] : 0.0;
        for (var allowed in _allowedCategories) {
          if (item == allowed ||
              item.contains(allowed) ||
              allowed.contains(item)) {
            matches++;
            if (score > maxScore) maxScore = score;
            break;
          }
        }
      }

      print('✅ Wearable matches: $matches, Max score: $maxScore');

      // STEP 5: ACCEPTANCE LOGIC
      if ((matches >= 2 && maxScore > 0.5) ||
          (matches >= 1 && maxScore > 0.6)) {
        print('✅ ACCEPTED');
        return {
          'isValid': true,
          'message': 'Image validated successfully!',
          'detectedItems': detectedItems
        };
      }

      // ========================================
      // STEP 6: REJECTION - Not identified as wearable
      // ========================================
      print('❌ REJECTED: Unable to identify as wearable item');
      return {
        'isValid': false,
        'message':
            'Unable to identify suitable item in this image. Please try a different photo.',
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
