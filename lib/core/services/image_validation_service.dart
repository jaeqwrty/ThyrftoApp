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
  // NOTE: Removed 'leather' as standalone - motorcycles have leather seats
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
    'cardigan',
    'sweater',
    'knit',
    'knitwear',
    'wool',
    'pullover',
    'hoodie',
    'sweatshirt',
    'blouse',
    // Bag-specific (not just material)
    'handbag',
    'backpack',
    'purse',
    'tote bag',
    'clutch bag',
    'satchel',
    // Shoe-specific
    'sneaker',
    'boot',
    'sandal',
    'loafer',
    'heel',
    'footwear',
    // Accessories
    'jewelry',
    'necklace',
    'bracelet',
    'earring',
    'scarf',
    'hat',
    'beanie',
    'cap',
  ];

  // Helper to check if item matches any in a list

  // Strict check - exact or very close match only

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
        for (var face in faces) {
          final boundingPoly = face['boundingPoly'];
          final detectionConfidence =
              (face['detectionConfidence'] as num?)?.toDouble() ?? 0.0;
          final landmarkingConfidence =
              (face['landmarkingConfidence'] as num?)?.toDouble() ?? 0.0;

          print(
              '👤 Face detection confidence: $detectionConfidence, landmarking: $landmarkingConfidence');

          // Calculate face size relative to image (approximate)
          if (boundingPoly != null && boundingPoly['vertices'] != null) {
            final vertices = boundingPoly['vertices'] as List;
            if (vertices.length >= 4) {
              // Get bounding box dimensions
              final xs = vertices
                  .map((v) => (v['x'] as num?)?.toDouble() ?? 0.0)
                  .toList();
              final ys = vertices
                  .map((v) => (v['y'] as num?)?.toDouble() ?? 0.0)
                  .toList();

              final minX = xs.reduce((a, b) => a < b ? a : b);
              final maxX = xs.reduce((a, b) => a > b ? a : b);
              final minY = ys.reduce((a, b) => a < b ? a : b);
              final maxY = ys.reduce((a, b) => a > b ? a : b);

              final faceWidth = maxX - minX;
              final faceHeight = maxY - minY;
              final faceArea = faceWidth * faceHeight;

              print(
                  '👤 Face dimensions: ${faceWidth}x${faceHeight}, area: $faceArea');

              // If face is detected with high confidence OR takes up significant area
              // (Large face area suggests it's a selfie or portrait)
              // Face area > 40000 pixels suggests prominent face (roughly 200x200 or larger)
              if (detectionConfidence > 0.7 || faceArea > 40000) {
                print(
                    '❌ FACE REJECTION: Face is too prominent (confidence: $detectionConfidence, area: $faceArea)');
                return {
                  'isValid': false,
                  'message':
                      'Please focus on the item you\'re selling, not on faces. Take a photo that clearly shows the clothing, shoes, bag, or accessory.',
                  'detectedItem': 'face',
                };
              }
            }
          }

          // Also reject if face detection confidence is very high regardless of size
          if (detectionConfidence > 0.85) {
            print(
                '❌ FACE REJECTION: Very high face confidence ($detectionConfidence)');
            return {
              'isValid': false,
              'message':
                  'Please focus on the item you\'re selling, not on faces. Take a photo that clearly shows the clothing, shoes, bag, or accessory.',
              'detectedItem': 'face',
            };
          }
        }

        // If multiple faces detected, likely not a product photo
        if (faces.length >= 2) {
          print('❌ FACE REJECTION: Multiple faces detected (${faces.length})');
          return {
            'isValid': false,
            'message':
                'Please focus on the item you\'re selling. Photos with multiple people are not suitable for product listings.',
            'detectedItem': 'multiple faces',
          };
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
          // Use strict matching for absolute rejections
          if (item == rejected ||
              item.contains(rejected) ||
              (rejected.length > 3 && item.contains(rejected))) {
            // Very low threshold for vehicles - reject if detected at all in top 20 results
            if (score > 0.25 || i < 20) {
              print(
                  '❌ ABSOLUTE REJECTION: Found "$item" matching "$rejected" (score: $score, index: $i)');
              return {
                'isValid': false,
                'message':
                    'This appears to be a ${_getReadableCategory(rejected)}. Please only post clothing, shoes, bags, or accessories.',
                'detectedItem': item,
              };
            }
          }
        }
      }

      // ========================================
      // STEP 2: FOOD REJECTION CHECK (STRICT!)
      // Check for food items - reject with low threshold
      // ========================================
      for (int i = 0; i < detectedItems.length; i++) {
        final item = detectedItems[i];
        final score = detectedScores.length > i ? detectedScores[i] : 0.0;

        for (var foodItem in _foodRejectCategories) {
          if (item == foodItem ||
              item.contains(foodItem) ||
              (foodItem.length > 3 && item.contains(foodItem))) {
            // Low threshold for food - reject if detected in top 15 results
            if (score > 0.3 || i < 15) {
              print(
                  '❌ FOOD REJECTION: Found "$item" matching "$foodItem" (score: $score, index: $i)');
              return {
                'isValid': false,
                'message':
                    'This appears to be a food/beverage item ($item). Please only post clothing, shoes, bags, or accessories.',
                'detectedItem': item,
              };
            }
          }
        }
      }

      // ========================================
      // STEP 3: GENERAL REJECTION CHECK
      // Check for other non-wearable items
      // ========================================
      for (int i = 0; i < detectedItems.length; i++) {
        final item = detectedItems[i];
        final score = detectedScores.length > i ? detectedScores[i] : 0.0;

        for (var rejected in _rejectedCategories) {
          if (item == rejected || item.contains(rejected)) {
            // Higher threshold for general rejections, but still catch them
            if (score > 0.5 && i < 10) {
              print(
                  '❌ GENERAL REJECTION: Found "$item" matching "$rejected" (score: $score, index: $i)');
              return {
                'isValid': false,
                'message':
                    'This appears to be a ${_getReadableCategory(rejected)}. Please only post clothing, shoes, bags, or accessories.',
                'detectedItem': item,
              };
            }
          }
        }
      }

      // ========================================
      // STEP 4: WEARABLE DETECTION
      // Now check if this IS a wearable item
      // ========================================
      double wearableScore = 0.0;
      int wearableMatches = 0;
      double maxWearableScore = 0.0;
      String bestWearableMatch = '';

      for (int i = 0; i < detectedItems.length; i++) {
        final item = detectedItems[i];
        final score = detectedScores.length > i ? detectedScores[i] : 0.0;

        for (var allowed in _allowedCategories) {
          if (item == allowed ||
              item.contains(allowed) ||
              allowed.contains(item)) {
            wearableScore += score;
            wearableMatches++;
            if (score > maxWearableScore) {
              maxWearableScore = score;
              bestWearableMatch = item;
            }
            break;
          }
        }
      }

      print(
          '✅ Wearable score: $wearableScore, Matches: $wearableMatches, Max: $maxWearableScore, Best: $bestWearableMatch');

      // Check for fabric/clothing indicators
      bool hasFabricDetection = false;
      String fabricMatch = '';
      for (var item in detectedItems) {
        for (var fabric in _fabricIndicators) {
          if (item.contains(fabric) || fabric.contains(item)) {
            hasFabricDetection = true;
            fabricMatch = item;
            break;
          }
        }
        if (hasFabricDetection) break;
      }

      // Check for visual context (hanger, mannequin, person wearing clothes)
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

      print(
          '📋 Has fabric: $hasFabricDetection ($fabricMatch), Has context: $hasValidContext');

      // ========================================
      // STEP 5: ACCEPTANCE LOGIC
      // Require strong wearable evidence to accept
      // ========================================

      // Strong wearable detection - accept
      if (wearableMatches >= 2 && maxWearableScore > 0.5) {
        print('✅ ACCEPTED: Strong wearable detection');
        return {
          'isValid': true,
          'message': 'Image validated successfully!',
          'detectedItems': detectedItems,
          'wearableScore': wearableScore,
          'wearableMatches': wearableMatches,
        };
      }

      // Single strong wearable match with fabric detection
      if (wearableMatches >= 1 &&
          maxWearableScore > 0.6 &&
          hasFabricDetection) {
        print('✅ ACCEPTED: Wearable with fabric detection');
        return {
          'isValid': true,
          'message': 'Image validated successfully!',
          'detectedItems': detectedItems,
          'wearableScore': wearableScore,
          'wearableMatches': wearableMatches,
        };
      }

      // Fabric detection with valid context (person, hanger, etc.)
      if (hasFabricDetection && hasValidContext) {
        print('✅ ACCEPTED: Fabric with valid context');
        return {
          'isValid': true,
          'message': 'Image validated successfully!',
          'detectedItems': detectedItems,
          'wearableScore': wearableScore,
        };
      }

      // Single exact clothing match with decent confidence
      final exactClothingTerms = [
        'shirt',
        'dress',
        'pants',
        'jeans',
        'jacket',
        'coat',
        'sweater',
        'hoodie',
        'blouse',
        'skirt',
        'shorts',
        'suit',
        'blazer',
        'cardigan',
        'shoe',
        'sneaker',
        'boot',
        'sandal',
        'heel',
        'loafer',
        'bag',
        'handbag',
        'backpack',
        'purse',
        'wallet',
        'tote',
        'hat',
        'cap',
        'scarf',
        'belt',
        'watch',
        'jewelry',
        'necklace',
        'bracelet'
      ];

      for (int i = 0; i < detectedItems.length; i++) {
        final item = detectedItems[i];
        final score = detectedScores.length > i ? detectedScores[i] : 0.0;

        if (exactClothingTerms.contains(item) && score > 0.4) {
          print('✅ ACCEPTED: Exact clothing match "$item"');
          return {
            'isValid': true,
            'message': 'Image validated successfully!',
            'detectedItems': detectedItems,
          };
        }
      }

      // ========================================
      // STEP 6: REJECTION - Not identified as wearable
      // ========================================
      print('❌ REJECTED: Unable to identify as wearable item');
      return {
        'isValid': false,
        'message':
            'Unable to identify this as a wearable item. Please ensure your photo clearly shows clothing, shoes, bags, or accessories.',
      };
    } catch (e) {
      print('Image validation error: $e');
      return {
        'isValid': false,
        'message': 'Error validating image: $e',
      };
    }
  }

  // Helper to get readable category name for error messages
  String _getReadableCategory(String category) {
    final categoryMap = {
      'motorcycle': 'motorcycle/vehicle',
      'motorbike': 'motorcycle/vehicle',
      'motor scooter': 'scooter/vehicle',
      'scooter': 'scooter/vehicle',
      'car': 'car/vehicle',
      'automobile': 'vehicle',
      'truck': 'truck/vehicle',
      'bicycle': 'bicycle',
      'bike': 'bike',
      'wheel': 'vehicle',
      'tire': 'vehicle',
      'food': 'food item',
      'meal': 'food item',
      'wrap': 'food item',
      'burrito': 'food item',
      'sandwich': 'food item',
      'snack': 'food item',
      'drink': 'beverage',
      'beverage': 'beverage',
    };
    return categoryMap[category] ?? category;
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
