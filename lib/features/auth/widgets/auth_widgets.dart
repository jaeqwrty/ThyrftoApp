import 'package:flutter/material.dart';
import 'package:thryfto/core/constants/app_colors.dart';

const Color _authInk = Color(0xFF17131F);
const Color _authMuted = Color(0xFF6B6475);
const Color _authSurface = Color(0xFFFBFAFC);
const Color _authLine = Color(0xFFE5DFEC);

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
      color: _authInk,
      fontWeight: FontWeight.w600,
    ),
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: const Color(0xFFAAA3B5),
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
        child: Icon(icon, color: _authMuted, size: 20),
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _authMuted,
                size: 20,
              ),
              onPressed: onTogglePasswordVisibility,
            )
          : suffixIcon,
      filled: true,
      fillColor: _authSurface,
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _authLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _authLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _authInk, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),
  );
}

/// Primary button widget for authentication pages
Widget buildPrimaryButton({
  required String text,
  VoidCallback? onPressed,
  bool isLoading = false,
  IconData? icon,
}) {
  final bool isButtonEnabled = onPressed != null && !isLoading;

  return AnimatedScale(
    scale: isLoading ? 0.99 : 1,
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOutCubic,
    child: Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isButtonEnabled ? _authInk : _authInk.withValues(alpha: 0.42),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
                          fontWeight: FontWeight.w800,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ],
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
      ),
    ),
  );
}

/// Soft structured background for authentication pages
Widget buildBackgroundBlobs(BuildContext context) {
  return const ColoredBox(
    color: AppColors.background,
    child: SizedBox.expand(),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _authLine),
          boxShadow: [
            BoxShadow(
              color: _authInk.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 6),
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
                fontWeight: FontWeight.w800,
                color: _authInk,
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
