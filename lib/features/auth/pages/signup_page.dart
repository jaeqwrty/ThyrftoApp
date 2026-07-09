import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/providers/auth_providers.dart';
import 'package:thryfto/shared/widgets/app_logo.dart';
import 'package:thryfto/shared/widgets/auth_wrapper.dart';
import 'package:thryfto/features/auth/widgets/auth_widgets.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'],
            style: const TextStyle(fontFamily: 'SF Pro Display'),
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'],
            style: const TextStyle(fontFamily: 'SF Pro Display'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final signUpState = ref.watch(signUpProvider);
    final isLoading = signUpState.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          buildBackgroundBlobs(context),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        const FadeInSlide(
                          delay: Duration(milliseconds: 50),
                          child: AppLogo(
                            fontSize: 36,
                            subtitle: 'Start your thrifting journey',
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 32),
                        const FadeInSlide(
                          delay: Duration(milliseconds: 100),
                          child: Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Full Name Field
                        FadeInSlide(
                          delay: const Duration(milliseconds: 150),
                          child: buildCustomTextField(
                            controller: _fullNameController,
                            hintText: 'Full Name',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Username Field
                        FadeInSlide(
                          delay: const Duration(milliseconds: 200),
                          child: buildCustomTextField(
                            controller: _usernameController,
                            hintText: 'Username',
                            icon: Icons.alternate_email_rounded,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a username';
                              }
                              if (value.length < 3) {
                                return 'Username must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Email Field
                        FadeInSlide(
                          delay: const Duration(milliseconds: 250),
                          child: buildCustomTextField(
                            controller: _emailController,
                            hintText: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        FadeInSlide(
                          delay: const Duration(milliseconds: 300),
                          child: buildCustomTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            isPasswordVisible: _isPasswordVisible,
                            onTogglePasswordVisibility: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Confirm Password Field
                        FadeInSlide(
                          delay: const Duration(milliseconds: 350),
                          child: buildCustomTextField(
                            controller: _confirmPasswordController,
                            hintText: 'Confirm Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            isPasswordVisible: _isConfirmPasswordVisible,
                            onTogglePasswordVisibility: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sign Up button
                        FadeInSlide(
                          delay: const Duration(milliseconds: 400),
                          child: buildPrimaryButton(
                            text: 'Sign Up',
                            isLoading: isLoading,
                            onPressed: _handleSignUp,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Terms of Service alert box
                        FadeInSlide(
                          delay: const Duration(milliseconds: 450),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'By signing up, you agree to our Terms of Service and Privacy Policy.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      height: 1.4,
                                      fontFamily: 'SF Pro Display',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Social Sign Up CTA
                        FadeInSlide(
                          delay: const Duration(milliseconds: 500),
                          child: Row(
                            children: [
                              Expanded(child: Divider(color: AppColors.borderLight, thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'Or sign up with',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: AppColors.borderLight, thickness: 1)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInSlide(
                          delay: const Duration(milliseconds: 550),
                          child: Row(
                            children: [
                              buildSocialButton(
                                icon: const Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                label: 'Google',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Google Sign Up is coming soon!'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              buildSocialButton(
                                icon: const Icon(
                                  Icons.apple,
                                  size: 22,
                                  color: Colors.black,
                                ),
                                label: 'Apple',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Apple Sign Up is coming soon!'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        FadeInSlide(
                          delay: const Duration(milliseconds: 600),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'SF Pro Display',
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Log in',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
