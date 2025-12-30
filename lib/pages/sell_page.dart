import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thryfto/commonWidgets/category_condition_selection.dart';
import 'package:thryfto/commonWidgets/custom_elevated_button.dart';
import 'package:thryfto/commonWidgets/custom_textfield.dart';
import 'package:thryfto/commonWidgets/section_labels.dart';
import 'package:thryfto/services/database_service.dart';

class SellPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const SellPage({super.key, required this.user});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<XFile> _selectedImages = [];
  String _selectedCondition = 'New';
  String _selectedCategory = 'Clothing';
  bool _isLoading = false;
  static const int _maxImages = 5;

  final List<String> _conditions = [
    'New',
    'Like New',
    'Good',
    'Fair',
    'Poor',
  ];

  final List<String> _categories = [
    'Clothing',
    'Shoes',
    'Accessories',
    'Bags',
  ];

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
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _handleCreateListing() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      _showMessage('Please add at least one image', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _db.createListing(
        userId: widget.user['id'] ?? widget.user['uid'],
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        size: _sizeController.text.trim(),
        condition: _selectedCondition,
        category: _selectedCategory,
        imageFiles: _selectedImages,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success']) {
        _showMessage('Listing created successfully!');

        _titleController.clear();
        _priceController.clear();
        _descriptionController.clear();
        _sizeController.clear();
        setState(() {
          _selectedImages = [];
          _selectedCondition = 'New';
          _selectedCategory = 'Clothing';
        });
      } else {
        _showMessage(
          result['message'] ?? 'Failed to create listing',
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
        automaticallyImplyLeading: false,
        title: const Text(
          'Create Listing',
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
              _buildImagePicker(),
              const SizedBox(height: 12),
              const SectionLabel(text: 'Title'),
              const SizedBox(height: 4),
              CustomTextField(
                controller: _titleController,
                hintText: 'e.g., Vintage Denim Jacket',
                icon: Icons.title,
                maxLength: 50,
                maxLines: 1,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
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
                        CustomTextField(
                          controller: _sizeController,
                          hintText: 'M, L, XL...',
                          icon: Icons.straighten,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
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
                text: 'Create Listing',
                isLoading: _isLoading,
                onPressed: _handleCreateListing,
              ),
              const SizedBox(height: 80), // Extra padding for bottom nav
            ],
          ),
        ),
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
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B5CF6),
        ),
        decoration: InputDecoration(
          hintText: '0.00',
          hintStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[300],
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '₱',
              style: TextStyle(
                fontSize: 18,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }
          if (double.tryParse(value) == null) {
            return 'Invalid';
          }
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
                  if (_selectedImages.length < _maxImages) {
                    return _buildAddImageButton();
                  }
                  return const SizedBox.shrink();
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
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 30,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Photos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Max $_maxImages images',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_selectedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${_selectedImages.length} of $_maxImages images',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
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
                ? Image.network(
                    image.path,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    image.path,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.error));
                    },
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImages.removeAt(index);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Cover',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
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
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            size: 30,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 60,
      );

      if (images.isNotEmpty) {
        final remainingSlots = _maxImages - _selectedImages.length;
        final imagesToAdd = images.take(remainingSlots).toList();

        setState(() {
          _selectedImages.addAll(imagesToAdd);
        });

        if (images.length > remainingSlots) {
          _showMessage('Maximum $_maxImages images allowed', isError: true);
        }
      }
    } catch (e) {
      _showMessage('Failed to pick images: $e', isError: true);
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      if (_selectedImages.length >= _maxImages) {
        _showMessage('Maximum $_maxImages images allowed', isError: true);
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      _showMessage('Failed to take photo: $e', isError: true);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFF8B5CF6)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImagesFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF8B5CF6)),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
