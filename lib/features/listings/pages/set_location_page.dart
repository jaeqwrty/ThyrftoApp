import 'package:flutter/material.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/services/location_service.dart';
import 'package:thryfto/core/utils/snackbar_utils.dart';

class SetLocationPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? currentLocation;

  const SetLocationPage({
    super.key,
    required this.userId,
    this.currentLocation,
  });

  @override
  State<SetLocationPage> createState() => _SetLocationPageState();
}

class _SetLocationPageState extends State<SetLocationPage> {
  final LocationService _locationService = LocationService();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _errorMessage;
  String _detectedLocationName = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _loadCurrentLocation() {
    if (widget.currentLocation != null) {
      setState(() {
        _selectedLatitude = widget.currentLocation!['latitude'];
        _selectedLongitude = widget.currentLocation!['longitude'];
        final address = widget.currentLocation!['address'] ?? '';
        _addressController.text = address;
        if (address.isNotEmpty && !address.startsWith('Lat:')) {
          _detectedLocationName = address;
        }
      });
    }
  }

  Future<void> _getCurrentDeviceLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _locationService.getCurrentLocation();

      if (position == null) {
        setState(() {
          _errorMessage = 'Could not get your location. Please check settings.';
          _isLoading = false;
        });
        return;
      }

      // 🆕 USE NEW METHOD: Get clean City, Region format
      final address = await _locationService.getCityAndRegionFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
        _detectedLocationName = address;

        // Only auto-fill if user hasn't entered a custom address
        if (_addressController.text.isEmpty) {
          _addressController.text = address;
        }

        _isLoading = false;
      });

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Location detected: $address');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });

      if (e.toString().contains('denied')) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to show nearby listings and help buyers find you. Please enable location access in settings.',
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

  Future<void> _saveLocation() async {
    if (_selectedLatitude == null || _selectedLongitude == null) {
      SnackbarUtils.showWarning(context, 'Please select a location first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use custom address if provided, otherwise use detected location name
      final addressToSave = _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : _detectedLocationName;

      final success = await _locationService.saveUserLocation(
        userId: widget.userId,
        latitude: _selectedLatitude!,
        longitude: _selectedLongitude!,
        address: addressToSave,
      );

      if (mounted) {
        if (success) {
          SnackbarUtils.showSuccess(context, 'Location saved successfully!');
          Navigator.pop(context, true);
        } else {
          SnackbarUtils.showError(
            context,
            'Failed to save location. Please try again.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getLocationDisplayText() {
    if (_selectedLatitude == null || _selectedLongitude == null) {
      return 'No location selected';
    }

    if (_detectedLocationName.isNotEmpty &&
        !_detectedLocationName.startsWith('Lat:')) {
      return _detectedLocationName;
    }

    return 'Lat: ${_selectedLatitude!.toStringAsFixed(6)}, Lon: ${_selectedLongitude!.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Set Your Location',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontFamily: 'SF Pro Display',
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.accent,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your location helps buyers find items near them and see how far items are from you.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Current Location Section
                  if (_selectedLatitude != null && _selectedLongitude != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.green.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Location Detected',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _getLocationDisplayText(),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Address Input
                  TextField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Location Name (Optional)',
                      hintText: 'e.g., Matina, Davao City or Downtown Davao',
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFBFAFC),
                      helperText: 'This will be shown to other users',
                      helperStyle:
                          const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_errorMessage != null) const SizedBox(height: 24),

                  // Use Current Location Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _getCurrentDeviceLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text(
                        'Use Current Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _selectedLatitude != null &&
                              _selectedLongitude != null
                          ? _saveLocation
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.32),
                      ),
                      child: Text(
                        'Save Location',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
