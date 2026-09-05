import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:thryfto/core/utils/app_page_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/utils/common_modals.dart';
import 'package:thryfto/core/utils/snackbar_utils.dart';
import 'package:thryfto/core/providers/auth_providers.dart';
import 'package:thryfto/core/services/location_service.dart';
import 'package:thryfto/core/services/map_location.dart';
import 'package:thryfto/core/services/profile_picture_service.dart';
import 'package:thryfto/features/auth/pages/happy_thrifting_page.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _profileImageService = ProfileImageService();
  final _locationService = LocationService();
  final _bioController = TextEditingController();

  XFile? _imageFile;
  Uint8List? _imageBytes;
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAddress;
  String? _locationError;
  String? _userFullName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user != null) {
      final userProfile = await authService.getUserProfile(user.uid);
      if (userProfile != null && mounted) {
        setState(() {
          _userFullName = userProfile['fullName'] ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        print('📸 Image picked: ${pickedFile.name}');
        final bytes = await pickedFile.readAsBytes();
        print('📊 Image size: ${bytes.length} bytes');

        setState(() {
          _imageFile = pickedFile;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to pick image: $e');
      }
    }
  }

  void _showImageSourceDialog() {
    CommonModals.showImageSourceModal(
      context,
      onGallery: () => _pickImage(ImageSource.gallery),
      onCamera: () => _pickImage(ImageSource.camera),
      showCamera: !kIsWeb,
    );
  }

  Future<void> _getCurrentDeviceLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final position = await _locationService.getCurrentLocation();

      if (position == null) {
        setState(() {
          _locationError =
              'Could not get your location. Please turn on your location.';
          _isLoadingLocation = false;
        });
        return;
      }

      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
        _selectedAddress = address;
        _isLoadingLocation = false;
      });

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Location detected: $address');
      }
    } catch (e) {
      setState(() {
        _locationError = 'Error: ${e.toString()}';
        _isLoadingLocation = false;
      });

      if (e.toString().contains('denied')) {
        _showPermissionDialog();
      }
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      AppPageRoute.fadeThrough(
        builder: (context) => LocationPicker(
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLatitude = result['latitude'];
        _selectedLongitude = result['longitude'];
        _selectedAddress = result['address'];
        _locationError = null;
      });

      SnackbarUtils.showSuccess(context, 'Location set: ${result['address']}');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to show nearby listings. Please enable location access in settings.',
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

  Future<void> _completeSetup() async {
    // Validate location
    if (_selectedLatitude == null || _selectedLongitude == null) {
      SnackbarUtils.showError(
        context,
        'Please set your location to help buyers find items near you',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      print('👤 User ID: ${user.uid}');

      // Upload profile image if selected
      String? imageUrl;
      if (_imageFile != null) {
        print('⬆️ Starting image upload...');

        // Show uploading message
        if (mounted) {
          SnackbarUtils.showInfo(context, 'Uploading image...');
        }

        imageUrl = await _profileImageService.uploadProfileImage(
          _imageFile!,
          user.uid,
        );

        // Clear the uploading message
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }

        if (imageUrl == null) {
          print('❌ Image upload returned null');
          throw Exception('Failed to upload profile image. Please try again.');
        }

        print('✅ Image uploaded successfully: ${imageUrl.substring(0, 50)}...');
      } else {
        print('ℹ️ No image selected, skipping upload');
      }

      // Save location
      print('📍 Saving location...');
      await _locationService.saveUserLocation(
        userId: user.uid,
        latitude: _selectedLatitude!,
        longitude: _selectedLongitude!,
        address: _selectedAddress ?? 'Location set',
      );
      print('✅ Location saved');

      // Complete onboarding
      print('📝 Completing onboarding...');
      final success = await authService.completeOnboarding(
        uid: user.uid,
        bio: _bioController.text.trim(),
        profileImageUrl: imageUrl,
        address: _selectedAddress ?? 'Location set',
      );

      if (!mounted) return;

      if (success) {
        print('✅ Onboarding completed successfully');

        // Fetch updated user profile
        final userProfile = await authService.getUserProfile(user.uid);
        if (!mounted) return;

        if (userProfile != null) {
          print('✅ User profile fetched');
          print('   Profile image URL: ${userProfile['profileImageUrl']}');

          // Navigate to Happy Thrifting confirmation page
          Navigator.pushAndRemoveUntil(
            context,
            AppPageRoute.fadeThrough(
                builder: (context) => HappyThriftingPage(userProfile: userProfile)),
            (route) => false,
          );
        } else {
          throw Exception('Failed to fetch user profile');
        }
      } else {
        throw Exception('Failed to complete setup');
      }
    } catch (e, stackTrace) {
      print('❌ Error in _completeSetup: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() => _isLoading = false);

      SnackbarUtils.showError(context, 'Error: ${e.toString()}');
    }
  }

  Widget _buildProfileImage() {
    if (_imageBytes != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.backgroundGreyDark,
          image: DecorationImage(
            image: MemoryImage(_imageBytes!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (!kIsWeb && _imageFile != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.backgroundGreyDark,
          image: DecorationImage(
            image: FileImage(File(_imageFile!.path)),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      // Show initials with background color when no image
      final initial = (_userFullName != null && _userFullName!.isNotEmpty)
          ? _userFullName![0].toUpperCase()
          : '?';

      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[200],
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 40,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Setup Profile',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo
            Center(
              child: GestureDetector(
                onTap: _showImageSourceDialog,
                child: Stack(
                  children: [
                    _buildProfileImage(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: AppColors.backgroundWhite,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Add a profile photo (Optional)',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bio
            TextField(
              controller: _bioController,
              maxLines: 2,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: 'Bio (Optional)',
                hintText: 'Tell us a bit about yourself...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
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
              ),
            ),

            const SizedBox(height: 10),

            // Location Section Header
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Your Location',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Help buyers find items near you',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 16),

            // Current Location Status
            if (_selectedLatitude != null && _selectedLongitude != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
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
                            'Location Detected',
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
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please set your location to continue',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Use Current Location Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed:
                    _isLoadingLocation ? null : _getCurrentDeviceLocation,
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _isLoadingLocation
                      ? 'Getting location...'
                      : 'Use Current Location',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Pin Location on Map Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _openMapPicker,
                icon: const Icon(Icons.map_outlined),
                label: const Text(
                  'Search location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            // Error Message
            if (_locationError != null) ...[
              const SizedBox(height: 12),
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
                        _locationError!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 48),

            // Complete Setup Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completeSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.backgroundWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.backgroundWhite,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Complete Setup',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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
