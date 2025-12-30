import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:thryfto/services/api_keys.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate distance between two coordinates in kilometers
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Radius of earth in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distance = earthRadius * c;

    return distance;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  /// Format distance for display
  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m away';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km away';
    } else {
      return '${distanceInKm.round()} km away';
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permissions
  Future<LocationPermission> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Get current device location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check permissions
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Save user's pin location to Firestore (direct fields)
  Future<bool> saveUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'latitude': latitude,
        'longitude': longitude,
        'address': address ?? 'Unknown location',
        'location_updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error saving user location: $e');
      return false;
    }
  }

  /// Get user's saved location - handles both nested and direct field structures
  Future<Map<String, dynamic>?> getUserLocation(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      // Check for direct latitude/longitude fields first (current structure)
      if (data['latitude'] != null && data['longitude'] != null) {
        return {
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'address': data['address'],
        };
      }

      // Fall back to nested location object (old structure)
      if (data['location'] != null) {
        return data['location'] as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print('Error getting user location: $e');
      return null;
    }
  }

  /// Save listing location (seller's location at time of posting)
  Future<bool> saveListingLocation({
    required String listingId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'address': address ?? 'Unknown location',
        },
      });
      return true;
    } catch (e) {
      print('Error saving listing location: $e');
      return false;
    }
  }

  /// Sort listings by distance from user's location
  List<Map<String, dynamic>> sortListingsByDistance({
    required List<Map<String, dynamic>> listings,
    required double userLat,
    required double userLon,
  }) {
    // Calculate distance for each listing
    final listingsWithDistance = listings.map((listing) {
      final location = listing['location'] as Map<String, dynamic>?;

      if (location != null &&
          location['latitude'] != null &&
          location['longitude'] != null) {
        final distance = calculateDistance(
          userLat,
          userLon,
          location['latitude'],
          location['longitude'],
        );

        return {
          ...listing,
          'distance': distance,
          'distance_text': formatDistance(distance),
        };
      } else {
        // If no location, put at the end
        return {
          ...listing,
          'distance': double.infinity,
          'distance_text': null,
        };
      }
    }).toList();

    // Sort by distance
    listingsWithDistance.sort((a, b) {
      final distA = a['distance'] as double;
      final distB = b['distance'] as double;
      return distA.compareTo(distB);
    });

    return listingsWithDistance;
  }

  /// Get readable address from coordinates using Google Geocoding API
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    const String apiKey = ApiKeys.googleMapsApiKey;
    try {
      print('Fetching address for: $latitude, $longitude');

      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey&language=en');

      final response = await http.get(url);

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          final result = data['results'][0];
          final components = result['address_components'] as List;

          String? city;
          String? province;
          String? municipality;

          // Parse address components
          for (var component in components) {
            final types = component['types'] as List;

            if (types.contains('locality')) {
              city = component['long_name'];
            } else if (types.contains('administrative_area_level_2')) {
              municipality = component['long_name'];
            } else if (types.contains('administrative_area_level_1')) {
              province = component['long_name'];
            }
          }

          print(
              'Parsed - City: $city, Municipality: $municipality, Province: $province');

          // Build address string
          if (city != null && province != null) {
            return '$city, $province';
          } else if (city != null) {
            return city;
          } else if (municipality != null && province != null) {
            return '$municipality, $province';
          } else if (municipality != null) {
            return municipality;
          } else if (province != null) {
            return province;
          }

          // Fallback to formatted address (cleaned up)
          String formattedAddress = result['formatted_address'] ?? '';
          // Remove postal code and country from formatted address
          formattedAddress = formattedAddress.replaceAll(', Philippines', '');
          formattedAddress =
              formattedAddress.replaceAll(RegExp(r'\d{4}'), '').trim();

          if (formattedAddress.isNotEmpty) {
            return formattedAddress;
          }
        }
      }

      print('Geocoding failed, returning fallback');
      return 'Philippines';
    } catch (e) {
      print('Error in getAddressFromCoordinates: $e');
      return 'Philippines';
    }
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Calculate distance between user and listing
  Future<String?> getDistanceToListing({
    required String userId,
    required Map<String, dynamic> listing,
  }) async {
    try {
      final userLocation = await getUserLocation(userId);
      if (userLocation == null) return null;

      final listingLocation = listing['location'] as Map<String, dynamic>?;
      if (listingLocation == null) return null;

      final distance = calculateDistance(
        userLocation['latitude'],
        userLocation['longitude'],
        listingLocation['latitude'],
        listingLocation['longitude'],
      );

      return formatDistance(distance);
    } catch (e) {
      print('Error calculating distance: $e');
      return null;
    }
  }

  /// Check if user has location set
  Future<bool> hasUserLocation(String userId) async {
    final location = await getUserLocation(userId);
    return location != null &&
        location['latitude'] != null &&
        location['longitude'] != null;
  }

  /// Get nearby listings within a radius (in km)
  List<Map<String, dynamic>> getListingsWithinRadius({
    required List<Map<String, dynamic>> listings,
    required double userLat,
    required double userLon,
    required double radiusKm,
  }) {
    return listings.where((listing) {
      final location = listing['location'] as Map<String, dynamic>?;

      if (location == null ||
          location['latitude'] == null ||
          location['longitude'] == null) {
        return false;
      }

      final distance = calculateDistance(
        userLat,
        userLon,
        location['latitude'],
        location['longitude'],
      );

      return distance <= radiusKm;
    }).toList();
  }
}