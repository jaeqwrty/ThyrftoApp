import 'package:flutter/material.dart';
import 'package:thryfto/core/utils/app_page_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/providers/auth_providers.dart';
import 'package:thryfto/shared/widgets/app_logo.dart';
import 'package:thryfto/shared/widgets/auth_wrapper.dart';
import 'package:thryfto/features/auth/widgets/auth_widgets.dart';
import 'package:thryfto/core/utils/snackbar_utils.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(signUpProvider.notifier).signUp(
          fullName: _fullNameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          cityState: '', // Will be set during profile setup
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

    if (!mounted) return;

    if (result['success']) {
      SnackbarUtils.showSuccess(context, result['message']);
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute.fadeThrough(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    } else {
      SnackbarUtils.showError(context, result['message']);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final result = await ref.read(signUpProvider.notifier).signInWithGoogle();

    if (!mounted) return;

    if (result['success']) {
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute.fadeThrough(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    } else if (result['message'] != 'Sign in cancelled') {
      SnackbarUtils.showError(context, result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signUpState = ref.watch(signUpProvider);
    final isLoading = signUpState.isLoading;

    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;
    // Use total screen height for scaling visual sizes so elements stay stable
    final layoutHeight = screenHeight;

    final isWideScreen = screenWidth > 600;

    // Ensure all content is displayed (never cut or hidden entirely)
    const bool showLogo = true;
    final bool showLogoSubtitle = layoutHeight >= 520;
    const bool showSocialLogins = true;
    final bool showDetailedTerms = layoutHeight >= 580;

    // Proportional field padding & font sizes scaling based on layout height
    final double vFieldPad = (layoutHeight * 0.014).clamp(6.0, 14.0);
    final double fieldFontSize = (layoutHeight * 0.018).clamp(11.0, 14.0);
    final double fieldSpacing = (layoutHeight * 0.010).clamp(4.0, 10.0);
    final double logoFontSize = (layoutHeight * 0.045).clamp(20.0, 36.0);
    final double titleFontSize = (layoutHeight * 0.032).clamp(16.0, 26.0);

    final EdgeInsetsGeometry fieldPadding = EdgeInsets.symmetric(
      horizontal: isWideScreen ? 20.0 : 16.0,
      vertical: vFieldPad,
    );

    // ── Reusable field builder shortcuts ──────────────────────────────────
    Widget fullNameField() => buildCustomTextField(
          controller: _fullNameController,
          hintText: 'Full Name',
          icon: Icons.person_outline,
          contentPadding: fieldPadding,
          fontSize: fieldFontSize,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Please enter your full name' : null,
        );

    Widget usernameField() => buildCustomTextField(
          controller: _usernameController,
          hintText: 'Username',
          icon: Icons.alternate_email_rounded,
          contentPadding: fieldPadding,
          fontSize: fieldFontSize,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter a username';
            if (v.length < 3) return 'At least 3 characters';
            return null;
          },
        );

    Widget emailField() => buildCustomTextField(
          controller: _emailController,
          hintText: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          contentPadding: fieldPadding,
          fontSize: fieldFontSize,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter your email';
            if (!v.contains('@')) return 'Please enter a valid email';
            return null;
          },
        );

    Widget passwordField() => buildCustomTextField(
          controller: _passwordController,
          hintText: 'Password',
          icon: Icons.lock_outline,
          isPassword: true,
          isPasswordVisible: _isPasswordVisible,
          contentPadding: fieldPadding,
          fontSize: fieldFontSize,
          onTogglePasswordVisibility: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter a password';
            if (v.length < 6) return 'At least 6 characters';
            return null;
          },
        );

    Widget confirmPasswordField() => buildCustomTextField(
          controller: _confirmPasswordController,
          hintText: 'Confirm Password',
          icon: Icons.lock_outline,
          isPassword: true,
          isPasswordVisible: _isConfirmPasswordVisible,
          contentPadding: fieldPadding,
          fontSize: fieldFontSize,
          onTogglePasswordVisibility: () => setState(
              () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm your password';
            if (v != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        );

    // ── Fields section ────────────────────────────────────────────────────
    Widget fieldsSection() {
      if (isWideScreen) {
        return Column(
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: fullNameField()),
              SizedBox(width: 12),
              Expanded(child: usernameField()),
            ]),
            SizedBox(height: fieldSpacing),
            emailField(),
            SizedBox(height: fieldSpacing),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: passwordField()),
              SizedBox(width: 12),
              Expanded(child: confirmPasswordField()),
            ]),
          ],
        );
      }
      return Column(
        children: [
          fullNameField(),
          SizedBox(height: fieldSpacing),
          usernameField(),
          SizedBox(height: fieldSpacing),
          emailField(),
          SizedBox(height: fieldSpacing),
          passwordField(),
          SizedBox(height: fieldSpacing),
          confirmPasswordField(),
        ],
      );
    }

    // ── Terms widget ──────────────────────────────────────────────────────
    Widget termsWidget() => showDetailedTerms
        ? Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.accent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'By signing up, you agree to our Terms of Service and Privacy Policy.',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontFamily: 'SF Pro Display'),
                ),
              ),
            ]),
          )
        : Text.rich(
            TextSpan(
              text: 'By signing up, you agree to our ',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontFamily: 'SF Pro Display'),
              children: [
                TextSpan(
                    text: 'Terms of Service',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
                const TextSpan(text: ' and '),
                TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
                const TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
          );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          buildBackgroundBlobs(context),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // SingleChildScrollView is ONLY for the keyboard-open case.
                // When keyboard is closed the Column(spaceEvenly) fills the
                // screen exactly — no scroll bar appears.
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    // Force the inner Column to be AT LEAST as tall as the
                    // available viewport so spaceEvenly distributes all gaps.
                    constraints: BoxConstraints(
                        minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWideScreen ? 40.0 : 28.0,
                          vertical: 8.0,
                        ),
                        child: Center(
                          child: Container(
                            width: isWideScreen ? 560 : double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Form(
                              key: _formKey,
                              // spaceEvenly: distributes ALL remaining height
                              // between the top-level sections. Gaps shrink
                              // automatically on smaller screens. Nothing clips.
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                children: [
                                  // ── Logo ──────────────────────────────
                                  if (showLogo)
                                    FadeInSlide(
                                      delay:
                                          const Duration(milliseconds: 50),
                                      child: AppLogo(
                                        fontSize: logoFontSize,
                                        subtitle: showLogoSubtitle
                                            ? 'Start your thrifting journey'
                                            : null,
                                        fontFamily: 'SF Pro Display',
                                      ),
                                    ),

                                  // ── Title ─────────────────────────────
                                  FadeInSlide(
                                    delay:
                                        const Duration(milliseconds: 100),
                                    child: Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        fontFamily: 'SF Pro Display',
                                      ),
                                    ),
                                  ),

                                  // ── All Fields ────────────────────────
                                  FadeInSlide(
                                    delay:
                                        const Duration(milliseconds: 200),
                                    child: fieldsSection(),
                                  ),

                                  // ── Button + Terms ────────────────────
                                  FadeInSlide(
                                    delay:
                                        const Duration(milliseconds: 350),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        buildPrimaryButton(
                                          text: 'Sign Up',
                                          isLoading: isLoading,
                                          onPressed: _handleSignUp,
                                        ),
                                        const SizedBox(height: 10),
                                        termsWidget(),
                                      ],
                                    ),
                                  ),

                                  // ── Social Logins ─────────────────────
                                  if (showSocialLogins)
                                    FadeInSlide(
                                      delay:
                                          const Duration(milliseconds: 480),
                                      child: Column(
                                        children: [
                                          Row(children: [
                                            Expanded(
                                                child: Divider(
                                                     color:
                                                         AppColors.border,
                                                    thickness: 1)),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                              child: Text(
                                                'Or sign up with',
                                                style: TextStyle(
                                                    color: AppColors
                                                        .textSecondary,
                                                    fontSize: 12,
                                                    fontFamily:
                                                        'SF Pro Display'),
                                              ),
                                            ),
                                            Expanded(
                                                child: Divider(
                                                     color:
                                                         AppColors.border,
                                                    thickness: 1)),
                                          ]),
                                          const SizedBox(height: 10),
                                          Row(children: [
                                            buildSocialButton(
                                              icon: const Text('G',
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.blue)),
                                              label: 'Google',
                                              onTap: isLoading
                                                  ? () {}
                                                  : _handleGoogleSignIn,
                                            ),
                                            const SizedBox(width: 12),
                                            buildSocialButton(
                                              icon: const Icon(Icons.apple,
                                                  size: 20,
                                                  color: AppColors.textPrimary),
                                              label: 'Apple',
                                              onTap: () =>
                                                  SnackbarUtils.showInfo(
                                                context,
                                                'Apple Sign Up is coming soon!',
                                              ),
                                            ),
                                          ]),
                                        ],
                                      ),
                                    ),

                                  // ── Login Link ────────────────────────
                                  FadeInSlide(
                                    delay:
                                        const Duration(milliseconds: 560),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Already have an account? ',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                              fontFamily: 'SF Pro Display'),
                                        ),
                                        GestureDetector(
                                          onTap: () =>
                                              Navigator.pop(context),
                                          child: const Text(
                                            'Log in',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'SF Pro Display',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
