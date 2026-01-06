import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thryfto/shared/widgets/category_condition_selection.dart';
import 'package:thryfto/shared/widgets/custom_elevated_button.dart';
import 'package:thryfto/shared/widgets/custom_textfield.dart';
import 'package:thryfto/shared/widgets/section_labels.dart';
import 'package:thryfto/features/listings/widgets/listing_form_widgets.dart';
import 'package:thryfto/features/listings/widgets/listing_form_fields.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/utils/snackbar_utils.dart';
import 'package:thryfto/core/services/database_service.dart';

class EditListingPage extends StatefulWidget {
  final Map<String, dynamic> listing;
  final Map<String, dynamic> user;

  const EditListingPage({
    super.key,
    required this.listing,
    required this.user,
  });

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _sizeController;

  String _selectedCategory = 'Clothing';
  String _selectedCondition = 'Good';

  List<String> _existingImageUrls = [];
  List<XFile> _newImageFiles = [];
  bool _isLoading = false;

  final List<String> _categories = ['Clothing', 'Shoes', 'Accessories', 'Bags'];
  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair', 'Poor'];
  static const int _maxImages = 5;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.listing['title'] ?? '');
    _priceController = TextEditingController(
      text: widget.listing['price']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.listing['description'] ?? '',
    );
    _sizeController = TextEditingController(text: widget.listing['size'] ?? '');
    _selectedCategory = widget.listing['category'] ?? 'Clothing';
    _selectedCondition = widget.listing['condition'] ?? 'Good';
    _existingImageUrls = List<String>.from(widget.listing['image_urls'] ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> _pickImagesFromGallery() async {
    final totalImages = _existingImageUrls.length + _newImageFiles.length;
    final remainingSlots = _maxImages - totalImages;

    final images = await _picker.pickMultiImage(imageQuality: 70);

    if (images.isNotEmpty) {
      setState(() {
        _newImageFiles.addAll(images.take(remainingSlots));
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final totalImages = _existingImageUrls.length + _newImageFiles.length;
    if (totalImages >= _maxImages) return;

    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _newImageFiles.add(image);
      });
    }
  }

  void _showImageSourceDialog() {
    showImageSourceDialog(
      context: context,
      onGallery: _pickImagesFromGallery,
      onCamera: _pickImageFromCamera,
    );
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
    });
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_existingImageUrls.isEmpty && _newImageFiles.isEmpty) {
      SnackbarUtils.showError(context, 'Please add at least one image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _db.updateListing(
        listingId: widget.listing['id'],
        title: _titleController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        size: _sizeController.text.trim(),
        condition: _selectedCondition,
        existingImageUrls: _existingImageUrls,
        newImageFiles: _newImageFiles,
      );

      setState(() => _isLoading = false);
      if (!mounted) return;

      if (result['success']) {
        SnackbarUtils.showSuccess(context, 'Listing updated successfully!');
        Navigator.pop(context, true);
      } else {
        SnackbarUtils.showError(
          context,
          result['message'] ?? 'Failed to update listing',
        );
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
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Listing',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
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
              ListingImagePicker(
                existingImageUrls: _existingImageUrls,
                newImageFiles: _newImageFiles,
                maxImages: _maxImages,
                onAddImage: _showImageSourceDialog,
                onRemoveExistingImage: _removeExistingImage,
                onRemoveNewImage: _removeNewImage,
              ),
              const SizedBox(height: 12),
              const SectionLabel(text: 'Title'),
              const SizedBox(height: 4),
              ListingFormFields.buildTitleField(_titleController),
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
                        ListingFormFields.buildPriceField(_priceController),
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
                        ListingFormFields.buildSizeField(_sizeController),
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Update Listing',
                isLoading: _isLoading,
                onPressed: _handleUpdate,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
