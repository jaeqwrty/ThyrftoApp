import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/providers/auth_providers.dart';
import 'package:thryfto/features/auth/widgets/auth_widgets.dart';
import 'package:thryfto/core/utils/snackbar_utils.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Use AuthService's resetPassword method
      final authService = ref.read(authServiceProvider);
      final result =
          await authService.resetPassword(_emailController.text.trim());

      if (!mounted) return;

      if (result['success']) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
        SnackbarUtils.showSuccess(context, result['message']);
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          SnackbarUtils.showError(context, result['message']);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        SnackbarUtils.showError(
          context,
          'We could not send the reset link right now. Please try again.',
          actionLabel: 'Try again',
          onAction: _handleResetPassword,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          buildBackgroundBlobs(context),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _emailSent ? _buildSuccessView() : _buildFormView(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // Icon
          Center(
            child: FadeInSlide(
              delay: const Duration(milliseconds: 100),
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          const Center(
            child: FadeInSlide(
              delay: Duration(milliseconds: 200),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle
          Center(
            child: FadeInSlide(
              delay: const Duration(milliseconds: 250),
              child: Text(
                "Don't worry! Enter your email and we'll\nsend you a link to reset your password.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Email field label
          const FadeInSlide(
            delay: Duration(milliseconds: 300),
            child: Text(
              'Email Address',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Email field
          FadeInSlide(
            delay: const Duration(milliseconds: 350),
            child: buildCustomTextField(
              controller: _emailController,
              hintText: 'Enter your email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 32),
          // Submit button
          FadeInSlide(
            delay: const Duration(milliseconds: 400),
            child: buildPrimaryButton(
              text: 'Send Reset Link',
              isLoading: _isLoading,
              onPressed: _handleResetPassword,
            ),
          ),
          const SizedBox(height: 24),
          // Back to login
          Center(
            child: FadeInSlide(
              delay: const Duration(milliseconds: 450),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Back to Login',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Success Icon
        FadeInSlide(
          delay: const Duration(milliseconds: 100),
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFFBFAFC),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                size: 34,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Title
        const FadeInSlide(
          delay: Duration(milliseconds: 200),
          child: Text(
            'Check Your Email',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Description
        FadeInSlide(
          delay: const Duration(milliseconds: 250),
          child: Text(
            "We've sent a password reset link to\n${_emailController.text.trim()}",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Instructions
        FadeInSlide(
          delay: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildInstructionItem(
                  '1',
                  'Open the email on your device',
                ),
                const SizedBox(height: 16),
                _buildInstructionItem(
                  '2',
                  'Click on the reset password link',
                ),
                const SizedBox(height: 16),
                _buildInstructionItem(
                  '3',
                  'Create a new password',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 36),
        // Back to login button
        FadeInSlide(
          delay: const Duration(milliseconds: 350),
          child: buildPrimaryButton(
            text: 'Back to Login',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(height: 16),
        // Resend link
        FadeInSlide(
          delay: const Duration(milliseconds: 400),
          child: TextButton(
            onPressed: () {
              setState(() => _emailSent = false);
            },
            child: const Text(
              "Didn't receive the email? Try again",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ),
      ],
    );
  }
}
