import 'package:flutter/material.dart';
import 'package:thryfto/core/constants/app_colors.dart';

/// Custom text field widget for authentication pages with focused/error borders
Widget buildCustomTextField({
  required TextEditingController controller,
  required String hintText,
  required IconData icon,
  bool isPassword = false,
  bool obscureText = false,
  Widget? suffixIcon,
  VoidCallback? onTogglePasswordVisibility,
  bool isPasswordVisible = false,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
  int maxLines = 1,
  EdgeInsetsGeometry? contentPadding,
  double? fontSize,
}) {
  return TextFormField(
    controller: controller,
    obscureText: isPassword ? !isPasswordVisible : obscureText,
    keyboardType: keyboardType,
    validator: validator,
    maxLines: isPassword ? 1 : maxLines,
    minLines: isPassword ? 1 : (maxLines == 1 ? 1 : 3),
    style: TextStyle(
      fontFamily: 'SF Pro Display',
      fontSize: fontSize ?? 14,
      color: AppColors.textPrimary,
    ),
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppColors.textSecondary,
        fontSize: fontSize ?? 14,
        fontFamily: 'SF Pro Display',
      ),
      errorStyle: const TextStyle(
        fontFamily: 'SF Pro Display',
      ),
      prefixIcon: Padding(
        padding: EdgeInsets.only(
          top: maxLines > 1 ? 12 : 0,
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: onTogglePasswordVisibility,
            )
          : suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: AppColors.borderLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: AppColors.borderLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),
  );
}

/// Primary button widget for authentication pages with gradient and glow shadow
Widget buildPrimaryButton({
  required String text,
  VoidCallback? onPressed,
  bool isLoading = false,
  IconData? icon,
}) {
  final bool isButtonEnabled = onPressed != null && !isLoading;

  return Container(
    height: 50,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      gradient: isButtonEnabled
          ? const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : null,
      color: !isButtonEnabled ? Colors.grey[300] : null,
      boxShadow: isButtonEnabled
          ? [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    ),
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
    ),
  );
}

/// Dynamic gradient blurred circles in the background of authentication pages
Widget buildBackgroundBlobs(BuildContext context) {
  final size = MediaQuery.of(context).size;
  return Stack(
    children: [
      Positioned(
        top: -size.width * 0.2,
        right: -size.width * 0.1,
        width: size.width * 0.8,
        height: size.width * 0.8,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFD946EF).withOpacity(0.12),
                const Color(0xFFD946EF).withOpacity(0),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: -size.width * 0.2,
        left: -size.width * 0.2,
        width: size.width * 0.9,
        height: size.width * 0.9,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF8B5CF6).withOpacity(0.12),
                const Color(0xFF8B5CF6).withOpacity(0),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

/// Styled Apple and Google quick-sign-in buttons
Widget buildSocialButton({
  required Widget icon,
  required String label,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Staggered entry animation widget
class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeInSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
