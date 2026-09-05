import 'package:flutter/material.dart';
import 'package:thryfto/core/utils/app_page_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/utils/common_modals.dart';
import 'package:thryfto/core/utils/snackbar_utils.dart';
import 'package:thryfto/core/providers/auth_providers.dart';
import 'package:thryfto/core/services/location_service.dart';
import 'package:thryfto/core/services/map_location.dart';
import 'package:thryfto/core/services/profile_picture_service.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;

  const EditProfilePage({super.key, required this.user});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _profileImageService =
      ProfileImageService(); // NEW: Use profile image service
  final _locationService = LocationService();

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  XFile? _imageFile;
  Uint8List? _imageBytes;
  final _picker = ImagePicker();

  bool _isLoading = false;
  bool _isLoadingLocation = false;
  String? _locationError;

  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAddress;
  String? _currentProfileImageUrl;
  bool _shouldDeleteImage = false; // NEW: Track if user wants to delete image

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userId = widget.user['id'] ?? widget.user['uid'];

    _fullNameController.text =
        widget.user['fullName'] ?? widget.user['full_name'] ?? '';
    _usernameController.text = widget.user['username'] ?? '';
    _bioController.text = widget.user['bio'] ?? '';
    _currentProfileImageUrl = widget.user['profileImageUrl'];

    _loadCurrentLocation(userId);
  }

  Future<void> _loadCurrentLocation(String userId) async {
    try {
      final location = await _locationService.getUserLocation(userId);
      if (location != null && mounted) {
        setState(() {
          _selectedLatitude = location['latitude'];
          _selectedLongitude = location['longitude'];
          _selectedAddress = location['address'];
        });
      }
    } catch (e) {
      print('Error loading location: $e');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = pickedFile;
          _imageBytes = bytes;
          _shouldDeleteImage =
              false; // Reset delete flag when new image is picked
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to pick image: $e');
      }
    }
  }

  void _showImageSourceDialog() {
    // Only show remove option if there's an actual image (URL with value or bytes)
    final hasImage = (_currentProfileImageUrl != null &&
            _currentProfileImageUrl!.isNotEmpty) ||
        _imageBytes != null;

    final items = [
      OptionsModalItem(
        icon: Icons.photo_library,
        iconColor: AppColors.primary,
        iconBackgroundColor: AppColors.primary,
        title: 'Choose from Gallery',
        onTap: () => _pickImage(ImageSource.gallery),
      ),
      OptionsModalItem(
        icon: Icons.camera_alt,
        iconColor: AppColors.primary,
        iconBackgroundColor: AppColors.primary,
        title: 'Take a Photo',
        onTap: () => _pickImage(ImageSource.camera),
      ),
    ];

    if (hasImage) {
      items.add(
        OptionsModalItem.delete(
          title: 'Remove Photo',
          onTap: () {
            setState(() {
              _imageFile = null;
              _imageBytes = null;
              _currentProfileImageUrl = null;
              _shouldDeleteImage = true;
            });
          },
        ),
      );
    }

    CommonModals.showOptionsModal(
      context,
      title: 'Profile Photo',
      items: items,
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
              'Could not get your location. Please check settings.';
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

  Future<void> _saveProfile() async {
    if (_fullNameController.text.trim().isEmpty) {
      SnackbarUtils.showWarning(context, 'Full name is required');
      return;
    }

    final normalizedUsername = _usernameController.text.trim().toLowerCase();
    if (normalizedUsername.isEmpty) {
      SnackbarUtils.showWarning(context, 'Username is required');
      return;
    }
    if (!RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(normalizedUsername)) {
      SnackbarUtils.showWarning(
        context,
        'Username must be 3-30 letters, numbers, or underscores',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = widget.user['id'] ?? widget.user['uid'];

      String? newImageUrl;

      // NEW: Handle profile image with the dedicated service
      if (_shouldDeleteImage) {
        // User wants to remove the profile image
        await _profileImageService.deleteProfileImage(userId);
        newImageUrl = ''; // Empty string to remove from database
      } else if (_imageFile != null) {
        // User selected a new image
        newImageUrl =
            await _profileImageService.uploadProfileImage(_imageFile!, userId);
        if (newImageUrl == null) {
          throw Exception('Failed to upload profile image');
        }
      } else {
        // Keep existing image
        newImageUrl = _currentProfileImageUrl;
      }

      final success = await ref.read(authServiceProvider).updateUserProfile(
            uid: userId,
            fullName: _fullNameController.text.trim(),
            username: normalizedUsername,
            bio: _bioController.text.trim(),
            profileImageUrl: newImageUrl ?? '',
          );

      if (!success) {
        throw Exception('Username may already be taken');
      }

      if (_selectedLatitude != null && _selectedLongitude != null) {
        await _locationService.saveUserLocation(
          userId: userId,
          latitude: _selectedLatitude!,
          longitude: _selectedLongitude!,
          address: _selectedAddress ?? 'Location set',
        );
      }

      if (!mounted) return;

      SnackbarUtils.showSuccess(context, 'Profile updated successfully!');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Photo Section
                  Center(
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              image: _imageBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_imageBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : (_currentProfileImageUrl != null &&
                                          _currentProfileImageUrl!.isNotEmpty)
                                      ? DecorationImage(
                                          image: NetworkImage(
                                              _currentProfileImageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                            ),
                            child: (_imageBytes == null &&
                                    (_currentProfileImageUrl == null ||
                                        _currentProfileImageUrl!.isEmpty))
                                ? CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.grey[200],
                                    child: Text(
                                      _fullNameController.text.isNotEmpty
                                          ? _fullNameController.text[0]
                                              .toUpperCase()
                                          : '?',
                                      style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
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
                                color: Colors.white,
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
                      'Tap to change photo',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Full Name
                  Text(
                    'Full Name',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
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

                  // Username
                  Text(
                    'Username',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your username',
                      prefixText: '@',
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

                  // Bio
                  Text(
                    'Bio',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    maxLines: 1,
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: 'Tell us a bit about yourself...',
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

                  const SizedBox(height: 7),

                  // Location Section
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help buyers find items near you',
                    style: TextStyle(
                      color: Colors.grey[600],
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
                          Icon(Icons.check_circle,
                              color: Colors.green.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location Set',
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
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please set your location',
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
                        foregroundColor: AppColors.primary,
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
                      style: ElevatedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
                ],
              ),
            ),
    );
  }
}
