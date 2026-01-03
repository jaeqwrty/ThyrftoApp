import 'package:flutter/material.dart';
import 'package:thryfto/shared/app_colors.dart';
import 'package:thryfto/shared/app_constants.dart';

/// Common modal bottom sheet widgets
class CommonModals {
  CommonModals._();

  /// Modal drag handle widget (the little bar at the top of modals)
  static Widget dragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: AppConstants.modalDragHandleWidth,
      height: AppConstants.modalDragHandleHeight,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(AppConstants.radiusS / 2),
      ),
    );
  }

  /// Show image source selection modal (Gallery or Camera)
  static void showImageSourceModal(
    BuildContext context, {
    required VoidCallback onGallery,
    required VoidCallback onCamera,
    bool showCamera = true,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: AppConstants.borderRadiusModal,
      ),
      builder: (context) => Container(
        padding: AppConstants.paddingAllXL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                onGallery();
              },
            ),
            if (showCamera)
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
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

  /// Show options modal for conversations/messages (delete, etc.)
  static void showOptionsModal(
    BuildContext context, {
    required String title,
    required List<OptionsModalItem> items,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: AppConstants.borderRadiusModal,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                dragHandle(),
                Padding(
                  padding: AppConstants.paddingListItem,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppConstants.fontSizeL,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ...items.map((item) => _buildOptionListTile(context, item)),
                const SizedBox(height: AppConstants.spaceS),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build a single option list tile for the options modal
  static Widget _buildOptionListTile(
      BuildContext context, OptionsModalItem item) {
    return ListTile(
      contentPadding: AppConstants.paddingListItem,
      leading: Container(
        padding: AppConstants.paddingAllS,
        decoration: BoxDecoration(
          color: item.iconBackgroundColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Icon(
          item.icon,
          color: item.iconColor,
          size: AppConstants.iconSizeL,
        ),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          color: item.titleColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: AppConstants.fontSizeML,
        ),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: TextStyle(
                fontSize: AppConstants.fontSizeS,
                color: Colors.grey[600],
              ),
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        item.onTap();
      },
    );
  }
}

/// Model class for options modal items
class OptionsModalItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const OptionsModalItem({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  /// Factory for delete option
  factory OptionsModalItem.delete({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return OptionsModalItem(
      icon: Icons.delete_outline,
      iconColor: Colors.red,
      iconBackgroundColor: Colors.red,
      title: title,
      subtitle: subtitle,
      titleColor: Colors.red,
      onTap: onTap,
    );
  }

  /// Factory for edit option
  factory OptionsModalItem.edit({
    required String title,
    required VoidCallback onTap,
  }) {
    return OptionsModalItem(
      icon: Icons.edit_outlined,
      iconColor: AppColors.primary,
      iconBackgroundColor: AppColors.primary,
      title: title,
      onTap: onTap,
    );
  }

  /// Factory for share option
  factory OptionsModalItem.share({
    required String title,
    required VoidCallback onTap,
  }) {
    return OptionsModalItem(
      icon: Icons.share_outlined,
      iconColor: AppColors.primary,
      iconBackgroundColor: AppColors.primary,
      title: title,
      onTap: onTap,
    );
  }

  /// Factory for block option
  factory OptionsModalItem.block({
    required String title,
    required VoidCallback onTap,
  }) {
    return OptionsModalItem(
      icon: Icons.block_outlined,
      iconColor: Colors.orange,
      iconBackgroundColor: Colors.orange,
      title: title,
      onTap: onTap,
    );
  }
}
