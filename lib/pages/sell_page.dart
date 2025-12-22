// ============================================
// File: lib/pages/sell_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:thryfto/widgets/section_label.dart';
import 'package:thryfto/widgets/custom_text_field.dart';
import 'package:thryfto/widgets/custom_dropdown.dart';
import 'package:thryfto/widgets/primary_button.dart';
import 'package:thryfto/widgets/image_picker.dart';

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

  List<File> _selectedImages = [];
  String _selectedCondition = 'New';
  String _selectedCategory = 'Clothing';
  bool _isLoading = false;

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
    'Electronics',
    'Home & Garden',
    'Sports',
    'Books',
    'Other',
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

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
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
        title: const Text(
          'Create Listing',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionLabel(text: 'Photos'),
              const SizedBox(height: 12),
              ImagePickerWidget(
                onImagesSelected: (images) {
                  setState(() => _selectedImages = images);
                },
                maxImages: 5,
                initialImages: _selectedImages,
              ),
              const SizedBox(height: 24),
              const SectionLabel(text: 'Title'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _titleController,
                hintText: 'e.g., Vintage Denim Jacket',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const SectionLabel(text: 'Price'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _priceController,
                hintText: '0.00',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const SectionLabel(text: 'Category'),
              const SizedBox(height: 8),
              CustomDropdown(
                value: _selectedCategory,
                items: _categories,
                icon: Icons.category,
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              const SizedBox(height: 16),
              const SectionLabel(text: 'Size'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _sizeController,
                hintText: 'e.g., M, L, XL, 32, etc.',
                icon: Icons.straighten,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a size';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const SectionLabel(text: 'Condition'),
              const SizedBox(height: 8),
              CustomDropdown(
                value: _selectedCondition,
                items: _conditions,
                icon: Icons.local_offer,
                onChanged: (value) {
                  setState(() => _selectedCondition = value!);
                },
              ),
              const SizedBox(height: 16),
              const SectionLabel(text: 'Description'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _descriptionController,
                hintText: 'Describe your item...',
                icon: Icons.description,
                maxLines: 1,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Create Listing',
                isLoading: _isLoading,
                onPressed: _handleCreateListing,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
