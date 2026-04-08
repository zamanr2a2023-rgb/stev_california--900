import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/core/models/user.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/auth/providers/auth_provider.dart';
import 'package:renizo/features/auth/screens/login_screen.dart';
import 'package:renizo/features/onboarding/screens/onboarding_slides_screen.dart';
import 'package:renizo/features/seller/screens/provider_app_screen.dart';

/// Register – converted from React RegisterScreen.tsx.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  static const String routeName = '/register';

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  UserRole _role = UserRole.customer;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      _showError('Passwords do not match');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    // Reset previous state
    ref.read(signupProvider.notifier).reset();

    // Call signup API
    await ref.read(signupProvider.notifier).signup(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
          role: _role == UserRole.provider ? 'provider' : 'user',
        );

    if (!mounted) return;

    final signupState = ref.read(signupProvider);

    if (signupState.isSuccess) {
      // Navigate based on role
      final user = await AuthLocalStorage.getCurrentUser();
      if (user == null) return;
      if (user.isProvider) {
        context.push(ProviderAppScreen.routeName);
      } else {
        context.push(OnboardingSlidesScreen.routeName);
      }
    } else if (signupState.error != null) {
      _showError(signupState.error!);
    }
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: AllColor.destructive,
      ),
    );
  }

  void _goToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(LoginScreen.routeName);
    }
  }

  // Match [LoginScreen] field chrome.
  Widget _authLabel(String text) => SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Text(
            text,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AllColor.white,
            ),
          ),
        ),
      );

  InputDecoration _authDecoration({
    required String hint,
    required IconData prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: AllColor.mutedForeground,
      ),
      filled: true,
      fillColor: AllColor.white,
      prefixIcon: Icon(prefix, size: 18.sp, color: AllColor.mutedForeground),
      suffixIcon: suffix,
      contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _fieldWrapper(Widget child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final signupState = ref.watch(signupProvider);

    return Scaffold(
      backgroundColor: AllColor.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _goToLogin,
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: AllColor.white, size: 22.sp),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: 96.w,
                height: 96.h,
                decoration: BoxDecoration(
                  color: AllColor.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.r),
                  child: Image.asset(
                    'assets/Renizo.png',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AllColor.white,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Join our service marketplace',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AllColor.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 24.h),
              _authLabel('I want to'),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: _roleCard(
                      emoji: '👤',
                      title: 'Find Services',
                      sub: 'Customer',
                      selected: _role == UserRole.customer,
                      onTap: () => setState(() => _role = UserRole.customer),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _roleCard(
                      emoji: '🔧',
                      title: 'Offer Services',
                      sub: 'Provider',
                      selected: _role == UserRole.provider,
                      onTap: () => setState(() => _role = UserRole.provider),
                    ),
                  ),
                ],
              ),
              if (signupState.error != null) ...[
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AllColor.destructive.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AllColor.destructive.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    signupState.error!,
                    style: TextStyle(fontSize: 14.sp, color: AllColor.white),
                  ),
                ),
              ],
              SizedBox(height: 24.h),
              _authLabel('Full Name'),
              _fieldWrapper(
                TextField(
                  controller: _nameController,
                  style: TextStyle(fontSize: 14.sp, color: AllColor.foreground),
                  textCapitalization: TextCapitalization.words,
                  decoration: _authDecoration(
                    hint: 'Jane Doe',
                    prefix: Icons.person_outline_rounded,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _authLabel('Email Address'),
              _fieldWrapper(
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 14.sp, color: AllColor.foreground),
                  decoration: _authDecoration(
                    hint: 'your@email.com',
                    prefix: Icons.mail_outline_rounded,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _authLabel('Phone'),
              _fieldWrapper(
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(fontSize: 14.sp, color: AllColor.foreground),
                  decoration: _authDecoration(
                    hint: '(555) 000-0000',
                    prefix: Icons.phone_outlined,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _authLabel('Password'),
              _fieldWrapper(
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(fontSize: 14.sp, color: AllColor.foreground),
                  decoration: _authDecoration(
                    hint: '••••••••••',
                    prefix: Icons.lock_outline_rounded,
                    suffix: IconButton(
                      splashRadius: 18.r,
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 18.sp,
                        color: AllColor.mutedForeground,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _authLabel('Confirm Password'),
              _fieldWrapper(
                TextField(
                  controller: _confirmController,
                  obscureText: true,
                  style: TextStyle(fontSize: 14.sp, color: AllColor.foreground),
                  decoration: _authDecoration(
                    hint: '••••••••••',
                    prefix: Icons.lock_outline_rounded,
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: signupState.isLoading ? null : _register,
                  style: FilledButton.styleFrom(
                    backgroundColor: AllColor.white,
                    foregroundColor: AllColor.primary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: signupState.isLoading
                      ? SizedBox(
                          height: 24.h,
                          width: 24.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AllColor.primary,
                          ),
                        )
                      : Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 24.h),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AllColor.white.withOpacity(0.85),
                    ),
                  ),
                  GestureDetector(
                    onTap: _goToLogin,
                    child: Text(
                      'Login Now',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AllColor.white,
                        decoration: TextDecoration.underline,
                        decorationColor: AllColor.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Text(
                'Local services made professional',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AllColor.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard({required String emoji, required String title, required String sub, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.w, horizontal: 12.w),
        decoration: BoxDecoration(
          color: selected ? AllColor.white : AllColor.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: selected ? AllColor.white : AllColor.white.withOpacity(0.4), width: 2),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 24.sp)),
            SizedBox(height: 4.h),
            Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: selected ? AllColor.primary : AllColor.white)),
            Text(sub, style: TextStyle(fontSize: 12.sp, color: selected ? AllColor.primary.withOpacity(0.8) : AllColor.white70)),
          ],
        ),
      ),
    );
  }

}
