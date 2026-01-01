import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thryfto/commonWidgets/category_condition_selection.dart';
import 'package:thryfto/commonWidgets/custom_elevated_button.dart';
import 'package:thryfto/commonWidgets/custom_textfield.dart';
import 'package:thryfto/commonWidgets/section_labels.dart';
import 'package:thryfto/commonWidgets/listing_form_widgets.dart';
import 'package:thryfto/global/app_colors.dart';
import 'package:thryfto/services/database_service.dart';

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

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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
      _showMessage('Please add at least one image', isError: true);
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
        _showMessage('Listing updated successfully!');
        Navigator.pop(context, true);
      } else {
        _showMessage(
          result['message'] ?? 'Failed to update listing',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showMessage('Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
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

  Widget _buildTitleField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            color: Colors.black.withOpacity(0.05),
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
          color: AppColors.primary,
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
            color: Colors.black.withOpacity(0.05),
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

}