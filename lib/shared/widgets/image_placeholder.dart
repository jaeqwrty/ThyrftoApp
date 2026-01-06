import 'package:flutter/material.dart';

class ImagePlaceholder extends StatelessWidget {
  final double? size;
  final Color? backgroundColor;
  final Color? iconColor;

  const ImagePlaceholder({
    super.key,
    this.size = 40,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image,
          size: size,
          color: iconColor ?? Colors.grey[400],
        ),
      ),
    );
  }
}
