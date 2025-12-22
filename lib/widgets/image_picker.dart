import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(List<File>) onImagesSelected;
  final int maxImages;
  final List<File>? initialImages;

  const ImagePickerWidget({
    super.key,
    required this.onImagesSelected,
    this.maxImages = 5,
    this.initialImages,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialImages != null) {
      _selectedImages = List.from(widget.initialImages!);
    }
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final remainingSlots = widget.maxImages - _selectedImages.length;
        final imagesToAdd = images.take(remainingSlots).toList();

        setState(() {
          _selectedImages.addAll(
            imagesToAdd.map((xFile) => File(xFile.path)).toList(),
          );
        });

        widget.onImagesSelected(_selectedImages);

        if (images.length > remainingSlots) {
          _showMaxImagesMessage();
        }
      }
    } catch (e) {
      _showErrorMessage('Failed to pick images: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      if (_selectedImages.length >= widget.maxImages) {
        _showMaxImagesMessage();
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });

        widget.onImagesSelected(_selectedImages);
      }
    } catch (e) {
      _showErrorMessage('Failed to take photo: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    widget.onImagesSelected(_selectedImages);
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

  void _showMaxImagesMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Maximum ${widget.maxImages} images allowed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image grid
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + 1,
              itemBuilder: (context, index) {
                if (index == _selectedImages.length) {
                  // Add more button
                  if (_selectedImages.length < widget.maxImages) {
                    return _buildAddImageButton();
                  }
                  return const SizedBox.shrink();
                }

                return _buildImageItem(_selectedImages[index], index);
              },
            ),
          ),

        // Initial add button (shown when no images)
        if (_selectedImages.isEmpty)
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              height: 200,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 50,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add Photos',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Max ${widget.maxImages} images',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Image count
        if (_selectedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${_selectedImages.length} of ${widget.maxImages} images',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageItem(File image, int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              image,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
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
          // Primary badge for first image
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
                  'Primary',
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
        width: 120,
        height: 120,
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
            size: 40,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }
}
