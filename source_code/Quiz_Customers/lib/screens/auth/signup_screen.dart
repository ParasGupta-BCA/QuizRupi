import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_logo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/shop_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = true;
  bool _showReferralField = false;
  bool _isLoading = false;
  String? _referralStatusMessage;
  bool _isReferralValid = false;
  String? _errorMessage;

  static const String _termsUrl =
      'https://quizrupi.blogspot.com/2026/09/terms-and-conditions-for-quizrupi.html';
  static const String _privacyUrl =
      'https://quizrupi.blogspot.com/2026/09/privacy-policy-for-quizrupi.html';

  TapGestureRecognizer? _termsRecognizer;
  TapGestureRecognizer? _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _launchURL(_termsUrl);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _launchURL(_privacyUrl);
  }

  Future<void> _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Could not launch $urlString: $e');
    }
  }

  @override
  void dispose() {
    _termsRecognizer?.dispose();
    _privacyRecognizer?.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _checkReferral() async {
    final code = _referralController.text.trim();
    if (code.isEmpty) return;

    final service = ref.read(supabaseServiceProvider);
    final isValid = await service.checkReferralCodeValid(code);

    setState(() {
      _isReferralValid = isValid;
      _referralStatusMessage = isValid
          ? '✓ Valid referral code! +50 bonus points will be added.'
          : '✗ Referral code not found. You can still sign up!';
    });
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service to continue'),
          backgroundColor: AppColors.errorContainer,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(supabaseServiceProvider);
      await authService.signUp(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        referralCode: _referralController.text.trim().isNotEmpty
            ? _referralController.text.trim()
            : null,
      );

      // Trigger profile refresh and pre-warm data
      ref.read(profileRefreshTriggerProvider.notifier).state++;
      try {
        ref.read(userProfileProvider.future);
        ref.read(quizCategoriesProvider.future);
        ref.read(booksProvider.future);
        ref.read(todayChallengeProvider.future);
      } catch (_) {}

      if (mounted) {
        context.go('/');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during registration. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Nav
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
                      onPressed: () => context.go('/login'),
                    ),
                    Row(
                      children: [
                        const AppLogo(
                          size: 32,
                          borderRadius: 9,
                          showShadow: false,
                        ),
                        const SizedBox(width: 8),
                        Text('Super', style: AppTextStyles.headlineSm.copyWith(color: Colors.white)),
                        Text(
                          ' Quiz',
                          style: AppTextStyles.headlineSm.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 48), // Spacer
                  ],
                ),
                const SizedBox(height: 12),

                // Tab Switcher [Log In] / [Sign Up]
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.go('/login'),
                          child: Container(
                            color: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Text(
                                'Log In',
                                style: AppTextStyles.labelLg.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryContainer.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Sign Up',
                              style: AppTextStyles.labelLg.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Welcome Incentive Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.amberGold.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryFixed.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.stars_rounded,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Get 250 Welcome Points',
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Credited instantly to your student wallet right after registration.',
                              style: AppTextStyles.bodySm.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.onErrorContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Form Fields
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Full Name *', style: AppTextStyles.labelMd),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _fullNameController,
                      style: const TextStyle(color: AppColors.onSurface),
                      decoration: const InputDecoration(
                        hintText: 'e.g., Rohan Kumar',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    Text('Email Address *', style: AppTextStyles.labelMd),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.onSurface),
                      decoration: const InputDecoration(
                        hintText: 'e.g., rohan@gmail.com',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    Text('Create Password *', style: AppTextStyles.labelMd),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Minimum 8 characters',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (val.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    Text('Confirm Password *', style: AppTextStyles.labelMd),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Re-enter your password',
                        prefixIcon: const Icon(Icons.verified_user_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() =>
                                _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (val != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Referral Toggle
                    GestureDetector(
                      onTap: () {
                        setState(() => _showReferralField = !_showReferralField);
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            "Have a friend's referral code?",
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            _showReferralField
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    if (_showReferralField) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _referralController,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                color: AppColors.onSurface,
                                letterSpacing: 1.5,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter referral code (e.g. QR123456)',
                                prefixIcon: Icon(Icons.tag),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _checkReferral,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceContainerHigh,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                            ),
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                      if (_referralStatusMessage != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _referralStatusMessage!,
                          style: AppTextStyles.bodySm.copyWith(
                            color: _isReferralValid
                                ? AppColors.tertiary
                                : AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 14),

                    // Terms Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          activeColor: AppColors.primaryContainer,
                          onChanged: (val) {
                            setState(() => _termsAccepted = val ?? false);
                          },
                        ),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: "I agree to QuizRupi's ",
                              style: AppTextStyles.bodySm.copyWith(fontSize: 11),
                              children: [
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: AppTextStyles.bodySm.copyWith(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primary,
                                  ),
                                  recognizer: _termsRecognizer,
                                ),
                                TextSpan(
                                  text: ' and ',
                                  style: AppTextStyles.bodySm.copyWith(fontSize: 11),
                                ),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: AppTextStyles.bodySm.copyWith(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primary,
                                  ),
                                  recognizer: _privacyRecognizer,
                                ),
                                TextSpan(
                                  text: '.',
                                  style: AppTextStyles.bodySm.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Create QuizRupi Account',
                                style: AppTextStyles.labelLg.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Already have account prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTextStyles.bodySm,
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.go('/login'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 8),
                        child: Text(
                          'Log In',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
