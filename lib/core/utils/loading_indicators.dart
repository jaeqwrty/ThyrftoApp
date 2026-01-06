import 'package:flutter/material.dart';
import 'package:thryfto/core/constants/app_constants.dart';

/// Common loading indicator widgets
class LoadingIndicators {
  LoadingIndicators._();

  /// Standard circular progress indicator (colored to match theme)
  static Widget standard({Color? color}) {
    return CircularProgressIndicator(
      color: color,
      strokeWidth: AppConstants.strokeNormal,
    );
  }

  /// Small circular progress indicator for buttons or compact spaces
  static Widget small({Color? color}) {
    return SizedBox(
      width: AppConstants.iconSizeM,
      height: AppConstants.iconSizeM,
      child: CircularProgressIndicator(
        color: color ?? Colors.white,
        strokeWidth: AppConstants.strokeNormal,
      ),
    );
  }

  /// Centered loading indicator
  static Widget centered({Color? color}) {
    return Center(
      child: CircularProgressIndicator(
        color: color,
        strokeWidth: AppConstants.strokeNormal,
      ),
    );
  }

  /// Loading indicator with progress value
  static Widget withProgress({
    required int cumulativeBytes,
    required int? totalBytes,
    Color? color,
  }) {
    return CircularProgressIndicator(
      value: totalBytes != null ? cumulativeBytes / totalBytes : null,
      color: color,
      strokeWidth: AppConstants.strokeNormal,
    );
  }

  /// Loading overlay (full screen with background)
  static Widget overlay({Color? backgroundColor}) {
    return Container(
      color: backgroundColor ?? Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Loading row with text (e.g., "Uploading...")
  static Widget withText(String text,
      {Color? textColor, Color? indicatorColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: AppConstants.iconSizeM,
          height: AppConstants.iconSizeM,
          child: CircularProgressIndicator(
            strokeWidth: AppConstants.strokeNormal,
            color: indicatorColor,
          ),
        ),
        const SizedBox(width: AppConstants.spaceM),
        Text(
          text,
          style: TextStyle(
            color: textColor ?? Colors.grey[600],
            fontSize: AppConstants.fontSizeM,
          ),
        ),
      ],
    );
  }

  /// Loading state for image loading with container
  static Widget imageLoading({
    double? width,
    double? height,
    Color? backgroundColor,
  }) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
