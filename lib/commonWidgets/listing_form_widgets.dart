import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Shared image picker widget for both create and edit listing pages
class ListingImagePicker extends StatelessWidget {
  final List<String> existingImageUrls;
  final List<XFile> newImageFiles;
  final int maxImages;
  final VoidCallback onAddImage;
  final Function(int) onRemoveExistingImage;
  final Function(int) onRemoveNewImage;

  const ListingImagePicker({
    super.key,
    this.existingImageUrls = const [],
    this.newImageFiles = const [],
    this.maxImages = 5,
    required this.onAddImage,
    required this.onRemoveExistingImage,
    required this.onRemoveNewImage,
  });

  @override
  Widget build(BuildContext context) {
    final totalImages = existingImageUrls.length + newImageFiles.length;

    if (totalImages == 0) {
      return GestureDetector(
        onTap: onAddImage,
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
                Icon(Icons.add_photo_alternate, size: 30, color: Colors.grey[400]),
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
                      'Max $maxImages images',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: existingImageUrls.length + newImageFiles.length + (totalImages < maxImages ? 1 : 0),
        itemBuilder: (context, index) {
          // Existing images first
          if (index < existingImageUrls.length) {
            return _ExistingImageTile(
              url: existingImageUrls[index],
              index: index,
              onRemove: onRemoveExistingImage,
            );
          }
          
          // Then new images
          final newImageIndex = index - existingImageUrls.length;
          if (newImageIndex < newImageFiles.length) {
            return _NewImageTile(
              file: newImageFiles[newImageIndex],
              index: newImageIndex,
              onRemove: onRemoveNewImage,
            );
          }
          
          // Finally add button if space available
          return _AddImageButton(onTap: onAddImage);
        },
      ),
    );
  }
}

class _ExistingImageTile extends StatelessWidget {
  final String url;
  final int index;
  final Function(int) onRemove;

  const _ExistingImageTile({
    required this.url,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 100,
                height: 100,
                color: Colors.grey[300],
                child: Icon(Icons.error, color: Colors.grey[600]),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => onRemove(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewImageTile extends StatelessWidget {
  final XFile file;
  final int index;
  final Function(int) onRemove;

  const _NewImageTile({
    required this.file,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? FutureBuilder<Uint8List>(
                    future: file.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        );
                      }
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  )
                : Image.file(
                    File(file.path),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => onRemove(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Center(
          child: Icon(Icons.add, size: 30, color: Colors.grey[400]),
        ),
      ),
    );
  }
}

/// Show image source selection dialog (shared between create and edit)
void showImageSourceDialog({
  required BuildContext context,
  required VoidCallback onGallery,
  required VoidCallback onCamera,
}) {
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
            leading: const Icon(Icons.photo_library, color: Color(0xFF8B5CF6)),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              onGallery();
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Color(0xFF8B5CF6)),
            title: const Text('Take a Photo'),
            onTap: () {
              Navigator.pop(context);
              onCamera();
            },
          ),
        ],
      ),
    ),
  );
}