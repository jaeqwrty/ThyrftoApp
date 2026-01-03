import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thryfto/commonWidgets/category_condition_selection.dart';
import 'package:thryfto/commonWidgets/custom_elevated_button.dart';
import 'package:thryfto/commonWidgets/custom_textfield.dart';
import 'package:thryfto/commonWidgets/section_labels.dart';
import 'package:thryfto/shared/app_colors.dart';
import 'package:thryfto/shared/common_modals.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:thryfto/services/favorite_service.dart';
import 'package:thryfto/services/image_validation_service.dart';
import 'package:thryfto/shared/snackbar_utils.dart';

class SellPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const SellPage({super.key, required this.user});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final DatabaseService _db = DatabaseService();
  final FavoritesService _favoritesService = FavoritesService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ImageValidationService _imageValidation = ImageValidationService();

  List<XFile> _selectedImages = [];
  String _selectedCondition = 'New';
  String _selectedCategory = 'Clothing';
  bool _isLoading = false;
  static const int _maxImages = 5;

  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair', 'Poor'];
  final List<String> _categories = ['Clothing', 'Shoes', 'Accessories', 'Bags'];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  void _showSuccessDialog(String title, double price) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Checkmark icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF8B5CF6),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Listing Posted!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$title',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₱ ${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Just close the dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Done', // Change text to "Done" or "OK"
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleCreateListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      SnackbarUtils.showError(context, 'Please add at least one image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Validate images first
      final validationResult =
          await _imageValidation.validateImages(_selectedImages);

      if (!validationResult['isValid']) {
        setState(() => _isLoading = false);
        SnackbarUtils.showError(context, validationResult['message']);
        return;
      }

      final userId = widget.user['id'] ?? widget.user['uid'];
      final listingTitle = _titleController.text.trim();
      final listingPrice = double.parse(_priceController.text.trim());

      final result = await _db.createListing(
        userId: userId,
        title: listingTitle,
        description: _descriptionController.text.trim(),
        price: listingPrice,
        size: _sizeController.text.trim(),
        condition: _selectedCondition,
        category: _selectedCategory,
        imageFiles: _selectedImages,
      );

      setState(() => _isLoading = false);
      if (!mounted) return;

      if (result['success']) {
        final listingId = result['listingId'];

        // Get the first image URL from the uploaded images
        String? firstImageUrl;
        if (result['imageUrls'] != null &&
            (result['imageUrls'] as List).isNotEmpty) {
          firstImageUrl = (result['imageUrls'] as List)[0];
        }

        // Notify all users who favorited this seller
        if (listingId != null) {
          await _favoritesService.notifyFavoritesOnNewListing(
            sellerId: userId,
            listingId: listingId,
            listingTitle: listingTitle,
            listingImage: firstImageUrl,
          );
        }

        // Clear form
        _titleController.clear();
        _priceController.clear();
        _descriptionController.clear();
        _sizeController.clear();
        setState(() {
          _selectedImages = [];
          _selectedCondition = 'New';
          _selectedCategory = 'Clothing';
        });

        // Show success dialog
        _showSuccessDialog(listingTitle, listingPrice);
      } else {
        SnackbarUtils.showError(
            context, result['message'] ?? 'Failed to create listing');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Create Listing',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              const SectionLabel(text: 'Photos'),
              const SizedBox(height: 8),
              _buildImagePicker(),
              const SizedBox(height: 12),
              const SectionLabel(text: 'Title'),
              const SizedBox(height: 4),
              _buildTitleField(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel(text: 'Price'),
                        const SizedBox(height: 4),
                        _buildPriceField(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel(text: 'Size'),
                        const SizedBox(height: 4),
                        _buildSizeField(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const SectionLabel(text: 'Category'),
              const SizedBox(height: 8),
              CustomChoiceChips(
                options: _categories,
                selectedValue: _selectedCategory,
                onSelected: (value) =>
                    setState(() => _selectedCategory = value),
              ),
              const SizedBox(height: 12),
              const SectionLabel(text: 'Condition'),
              const SizedBox(height: 8),
              CustomChoiceChips(
                options: _conditions,
                selectedValue: _selectedCondition,
                onSelected: (value) =>
                    setState(() => _selectedCondition = value),
              ),
              const SizedBox(height: 12),
              const SectionLabel(text: 'Description'),
              const SizedBox(height: 4),
              CustomTextField(
                controller: _descriptionController,
                hintText: 'Describe your item...',
                icon: Icons.description,
                maxLines: 1,
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a description';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Create Listing',
                isLoading: _isLoading,
                onPressed: _handleCreateListing,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _titleController,
        maxLength: 30,
        buildCounter: (context,
                {required currentLength, required isFocused, maxLength}) =>
            null,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'e.g., Vintage Denim Jacket',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
          prefixIcon: Icon(Icons.title, size: 20, color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter a title';
          return null;
        },
      ),
    );
  }

  Widget _buildPriceField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _priceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B5CF6),
        ),
        decoration: InputDecoration(
          hintText: '0.00',
          hintStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[300],
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '₱',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.25,
              ),
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          if (double.tryParse(value) == null) return 'Invalid';
          return null;
        },
      ),
    );
  }

  Widget _buildSizeField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _sizeController,
        maxLength: 6,
        buildCounter: (context,
                {required currentLength, required isFocused, maxLength}) =>
            null,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'M, L, XL...',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
          prefixIcon: Icon(Icons.straighten, size: 20, color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          return null;
        },
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + 1,
              itemBuilder: (context, index) {
                if (index == _selectedImages.length) {
                  return _selectedImages.length < _maxImages
                      ? _buildAddImageButton()
                      : const SizedBox.shrink();
                }
                return _buildImageItem(_selectedImages[index], index);
              },
            ),
          ),
        if (_selectedImages.isEmpty)
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate,
                        size: 30, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Photos',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500)),
                        Text('Max $_maxImages images',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageItem(XFile image, int index) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? FutureBuilder<Uint8List>(
                    future: image.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData)
                        return Image.memory(snapshot.data!,
                            width: 100, height: 100, fit: BoxFit.cover);
                      return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child:
                              const Center(child: CircularProgressIndicator()));
                    },
                  )
                : Image.file(File(image.path),
                    width: 100, height: 100, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImages.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child:
            Center(child: Icon(Icons.add, size: 30, color: Colors.grey[400])),
      ),
    );
  }

  Future<void> _pickImagesFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      final remainingSlots = _maxImages - _selectedImages.length;
      setState(() => _selectedImages.addAll(images.take(remainingSlots)));
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (_selectedImages.length >= _maxImages) return;
    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image != null) setState(() => _selectedImages.add(image));
  }

  void _showImageSourceDialog() {
    CommonModals.showImageSourceModal(
      context,
      onGallery: _pickImagesFromGallery,
      onCamera: _pickImageFromCamera,
    );
  }
}
