import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thryfto/core/services/database_service.dart';
import 'package:thryfto/core/services/favorite_service.dart';
import 'package:thryfto/core/utils/common_modals.dart';
import 'package:thryfto/core/utils/snackbar_utils.dart';

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

  List<XFile> _selectedImages = [];
  String _selectedCondition = 'New';
  String _selectedCategory = 'Clothing';
  bool _isLoading = false;
  static const int _maxImages = 5;

  static const Color _ink = Color(0xFF17131F);
  static const Color _muted = Color(0xFF6B6475);
  static const Color _page = Color(0xFFF6F3F8);
  static const Color _surface = Color(0xFFFBFAFC);
  static const Color _line = Color(0xFFE5DFEC);
  static const Color _accent = Color(0xFFA8752A);
  static const Color _error = Color(0xFFD94A4A);

  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair', 'Poor'];
  final List<String> _categories = [
    'Clothing',
    'Shoewear',
    'Accessories',
    'Bags'
  ];

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
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F1E7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: _accent,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Listing published',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'PHP ${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
      SnackbarUtils.showError(context, 'Please add at least one photo');
      return;
    }

    setState(() => _isLoading = true);

    try {
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

        String? firstImageUrl;
        if (result['imageUrls'] != null &&
            (result['imageUrls'] as List).isNotEmpty) {
          firstImageUrl = (result['imageUrls'] as List)[0];
        }

        if (listingId != null) {
          await _favoritesService.notifyFavoritesOnNewListing(
            sellerId: userId,
            listingId: listingId,
            listingTitle: listingTitle,
            listingImage: firstImageUrl,
          );
        }

        _titleController.clear();
        _priceController.clear();
        _descriptionController.clear();
        _sizeController.clear();
        setState(() {
          _selectedImages = [];
          _selectedCondition = 'New';
          _selectedCategory = 'Clothing';
        });

        _showSuccessDialog(listingTitle, listingPrice);
      } else {
        SnackbarUtils.showError(
          context,
          result['message'] ?? 'Failed to create listing',
          actionLabel: 'Try again',
          onAction: _handleCreateListing,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        'We could not publish this listing. Review the details and try again.',
        actionLabel: 'Try again',
        onAction: _handleCreateListing,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Sell an item',
          style: TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _buildIntro(),
              const SizedBox(height: 18),
              _buildPhotoComposer(),
              const SizedBox(height: 18),
              _buildSection(
                title: 'Item basics',
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _titleController,
                      label: 'Title',
                      hintText: 'Vintage denim jacket',
                      icon: Icons.sell_outlined,
                      maxLength: 30,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
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
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Price',
                            hintText: '0.00',
                            prefixText: 'PHP ',
                            icon: Icons.payments_outlined,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final price = double.tryParse(value.trim());
                              if (price == null || price <= 0) {
                                return 'Invalid price';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _sizeController,
                            label: 'Size',
                            hintText: 'M',
                            icon: Icons.straighten_outlined,
                            maxLength: 12,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildSection(
                title: 'Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Category'),
                    const SizedBox(height: 10),
                    _buildChoiceGrid(
                      options: _categories,
                      selectedValue: _selectedCategory,
                      iconFor: _categoryIcon,
                      onSelected: (value) =>
                          setState(() => _selectedCategory = value),
                    ),
                    const SizedBox(height: 18),
                    _buildFieldLabel('Condition'),
                    const SizedBox(height: 10),
                    _buildChoiceGrid(
                      options: _conditions,
                      selectedValue: _selectedCondition,
                      iconFor: _conditionIcon,
                      onSelected: (value) =>
                          setState(() => _selectedCondition = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildSection(
                title: 'Description',
                child: _buildTextField(
                  controller: _descriptionController,
                  label: 'Item notes',
                  hintText: 'Mention flaws, fit, material, and styling notes.',
                  icon: Icons.notes_outlined,
                  maxLines: 5,
                  maxLength: 180,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create a clean listing with clear photos and honest details.',
            style: TextStyle(
              color: _muted,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoComposer() {
    final hasImages = _selectedImages.isNotEmpty;

    return _buildSection(
      title: 'Photos',
      trailing: Text(
        '${_selectedImages.length}/$_maxImages',
        style: const TextStyle(
          color: _muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: hasImages ? _buildSelectedImages() : _buildEmptyPhotoState(),
    );
  }

  Widget _buildEmptyPhotoState() {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _showImageSourceDialog,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 172,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: _ink,
                  size: 34,
                ),
                SizedBox(height: 10),
                Text(
                  'Add photos',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Upload up to 5 clear item photos',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedImages() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1.25,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImagePreview(_selectedImages.first),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.56),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Cover photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length +
                (_selectedImages.length < _maxImages ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                return _buildAddImageTile();
              }

              return _buildImageThumb(_selectedImages[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumb(XFile image, int index) {
    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox.expand(child: _buildImagePreview(image)),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: _buildRemoveImageButton(index),
          ),
          if (index == 0)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRemoveImageButton(int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedImages.removeAt(index)),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.64),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildAddImageTile() {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _showImageSourceDialog,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _line),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: _ink,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(XFile image) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: image.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          }

          return const ColoredBox(
            color: _surface,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }

    return Image.file(File(image.path), fit: BoxFit.cover);
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.035),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _line),
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      minLines: maxLines > 1 ? 4 : 1,
      maxLength: maxLength,
      style: const TextStyle(
        color: _ink,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixText: prefixText,
        prefixIcon: Padding(
          padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
          child: Icon(icon, color: _muted, size: 20),
        ),
        alignLabelWithHint: maxLines > 1,
        counterText: '',
        filled: true,
        fillColor: _surface,
        labelStyle: const TextStyle(
          color: _muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFAAA3B5),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixStyle: const TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: _ink, width: 1.3),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: _error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: _error, width: 1.3),
        ),
      ),
    );
  }

  Widget _buildChoiceGrid({
    required List<String> options,
    required String selectedValue,
    required IconData Function(String) iconFor,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: options.map((option) {
        final selected = selectedValue == option;
        return ChoiceChip(
          showCheckmark: false,
          avatar: Icon(
            iconFor(option),
            size: 17,
            color: selected ? Colors.white : _muted,
          ),
          label: Text(option),
          selected: selected,
          onSelected: (value) {
            if (value) onSelected(option);
          },
          labelStyle: TextStyle(
            color: selected ? Colors.white : _ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
          selectedColor: _ink,
          backgroundColor: _surface,
          side: BorderSide(color: selected ? _ink : _line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: _line),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleCreateListing,
            style: ElevatedButton.styleFrom(
              backgroundColor: _ink,
              disabledBackgroundColor: _ink.withValues(alpha: 0.42),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Publish listing',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _muted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Shoewear':
        return Icons.hiking_outlined;
      case 'Accessories':
        return Icons.watch_outlined;
      case 'Bags':
        return Icons.shopping_bag_outlined;
      case 'Clothing':
      default:
        return Icons.checkroom_outlined;
    }
  }

  IconData _conditionIcon(String condition) {
    switch (condition) {
      case 'New':
        return Icons.auto_awesome_outlined;
      case 'Like New':
        return Icons.diamond_outlined;
      case 'Good':
        return Icons.thumb_up_alt_outlined;
      case 'Fair':
        return Icons.tune_outlined;
      case 'Poor':
      default:
        return Icons.build_outlined;
    }
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
