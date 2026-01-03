import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thryfto/services/location_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:thryfto/services/api_keys.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:thryfto/shared/app_colors.dart';

class LocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const LocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _locationService = LocationService();
  final _searchController = TextEditingController();

  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAddress;
  bool _isLoadingGPS = false;
  bool _isSearching = false;

  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;

  bool _hasShownApiError = false;

  @override
  void initState() {
    super.initState();
    _selectedLatitude = widget.initialLatitude;
    _selectedLongitude = widget.initialLongitude;
    _selectedAddress = widget.initialAddress;

    // Initialize search field with existing address
    if (_selectedAddress != null && _selectedAddress!.isNotEmpty) {
      _searchController.text = _selectedAddress!;
    }

    if (kIsWeb && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWebInfoDialog();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _showWebInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Location Setup'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For the best experience on web:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('Use "Current Location" button'),
            SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final String apiKey = ApiKeys.googleMapsApiKey;

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&components=country:ph'
        '&key=$apiKey',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;

          setState(() {
            _searchResults = predictions.map((prediction) {
              return {
                'place_id': prediction['place_id'],
                'description': prediction['description'],
              };
            }).toList();
            _isSearching = false;
            _hasShownApiError = false;
          });
        } else if (data['status'] == 'REQUEST_DENIED') {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });

          if (!_hasShownApiError && mounted) {
            _hasShownApiError = true;
            _showApiConfigDialog();
          }
        } else {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      } else if (response.statusCode == 403) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });

        if (!_hasShownApiError && mounted) {
          _hasShownApiError = true;
          _showApiConfigDialog();
        }
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });

      if (mounted && !_hasShownApiError) {
        if (e.toString().contains('Failed to fetch') ||
            e.toString().contains('XMLHttpRequest') ||
            e.toString().contains('ClientException')) {
          _hasShownApiError = true;
          _showApiConfigDialog();
        }
      }
    }
  }

  void _showApiConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Search Not Available'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The location search feature requires API configuration.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Please use one of these alternatives:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.my_location, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Use "Current Location" button',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // UPDATED: Now syncs with search field
  Future<void> _getPlaceDetails(String placeId, String description) async {
    setState(() => _isSearching = true);

    try {
      final String apiKey = ApiKeys.googleMapsApiKey;

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=geometry'
        '&key=$apiKey',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];

          // 🆕 FORMAT: Clean the description to City, Region format
          final cleanAddress =
              _locationService.formatLocationForDisplay(description);

          setState(() {
            _selectedLatitude = location['lat'];
            _selectedLongitude = location['lng'];
            _selectedAddress = cleanAddress;
            _searchResults = [];
            _searchController.text = cleanAddress;
            _isSearching = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location set: $cleanAddress'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          setState(() => _isSearching = false);
        }
      } else {
        setState(() => _isSearching = false);
      }
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  // UPDATED: Now syncs with search field
  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingGPS = true);

    try {
      final position = await _locationService.getCurrentLocation();

      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Could not get your location. Please turn on location.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoadingGPS = false);
        return;
      }

      // 🆕 USE NEW METHOD: Get only City, Region format
      final address = await _locationService.getCityAndRegionFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
        _selectedAddress = address;
        _searchController.text = address;
        _isLoadingGPS = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location detected: $address'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingGPS = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );

        if (e.toString().contains('denied')) {
          _showPermissionDialog();
        }
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to detect your location. Please enable it in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _locationService.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _confirmLocation() {
    if (_selectedLatitude == null || _selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'latitude': _selectedLatitude,
      'longitude': _selectedLongitude,
      'address': _selectedAddress ?? 'Selected Location',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose Your Location',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: (_selectedLatitude != null &&
              _selectedLongitude != null)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _confirmLocation,
                    icon: const Icon(Icons.check),
                    label: Text(
                      'Confirm Location',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Selected Location Card
            if (_selectedLatitude != null && _selectedLongitude != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Selected',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedAddress ?? 'Location set',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // GPS Location Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingGPS ? null : _useCurrentLocation,
                    icon: _isLoadingGPS
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      _isLoadingGPS
                          ? 'Getting location...'
                          : 'Use Current Location (Recommended)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR SEARCH',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search Bar (Now synced with GPS location)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Type your city or area...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();

                  _debounce = Timer(const Duration(milliseconds: 800), () {
                    _searchPlaces(value);
                  });
                },
              ),
            ),

            const SizedBox(height: 8),

            // Search Results
            _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _searchResults.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_searching,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              kIsWeb
                                  ? 'Use "Current Location" for best results'
                                  : 'Search for your location',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              kIsWeb
                                  ? 'Or type your city/area name'
                                  : 'Type your city, barangay, or area',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _searchResults.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: Color(0xFF8B5CF6),
                            ),
                            title: Text(
                              result['description'],
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () {
                              _getPlaceDetails(
                                result['place_id'],
                                result['description'],
                              );
                            },
                          );
                        },
                      ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
