import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/providers/auth_providers.dart';
import 'package:thryfto/features/auth/pages/signup_page.dart';
import 'package:thryfto/features/auth/pages/forgot_password_page.dart';
import 'package:thryfto/shared/widgets/app_logo.dart';
import 'package:thryfto/features/auth/widgets/auth_widgets.dart';
import 'package:thryfto/core/utils/snackbar_utils.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State variable to toggle password visibility
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(loginProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;

    if (result['success']) {
      // The AuthWrapper will automatically redirect to HomeScreen
    } else {
      SnackbarUtils.showError(context, result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final isLoading = loginState.isLoading;

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
                          delay: Duration(milliseconds: 100),
                          child: AppLogo(
                            fontSize: 36,
                            subtitle: 'Find your next favorite piece',
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 40),
                        const FadeInSlide(
                          delay: Duration(milliseconds: 200),
                          child: Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Email Field
                        FadeInSlide(
                          delay: const Duration(milliseconds: 300),
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
                        const SizedBox(height: 16),

                        // Password Field with Show/Hide Toggle
                        FadeInSlide(
                          delay: const Duration(milliseconds: 400),
                          child: buildCustomTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            isPasswordVisible: !_obscurePassword,
                            onTogglePasswordVisibility: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 12),
                        FadeInSlide(
                          delay: const Duration(milliseconds: 450),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ForgotPasswordPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SF Pro Display',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        FadeInSlide(
                          delay: const Duration(milliseconds: 500),
                          child: buildPrimaryButton(
                            text: 'Log In',
                            isLoading: isLoading,
                            onPressed: _handleLogin,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Social Logins CTA
                        FadeInSlide(
                          delay: const Duration(milliseconds: 550),
                          child: Row(
                            children: [
                              Expanded(child: Divider(color: AppColors.borderLight, thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'Or continue with',
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
                        const SizedBox(height: 20),
                        FadeInSlide(
                          delay: const Duration(milliseconds: 600),
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
                                onTap: () => SnackbarUtils.showInfo(context, 'Google Login is coming soon!'),
                              ),
                              const SizedBox(width: 16),
                              buildSocialButton(
                                icon: const Icon(
                                  Icons.apple,
                                  size: 22,
                                  color: Colors.black,
                                ),
                                label: 'Apple',
                                onTap: () => SnackbarUtils.showInfo(context, 'Apple Login is coming soon!'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        FadeInSlide(
                          delay: const Duration(milliseconds: 650),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'New to Thryfto? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'SF Pro Display',
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SignUpScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Sign up',
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
