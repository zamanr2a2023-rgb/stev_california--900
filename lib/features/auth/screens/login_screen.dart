import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/auth/providers/auth_provider.dart';
import 'package:renizo/features/auth/screens/register_screen.dart';
import 'package:renizo/features/nav_bar/screen/bottom_nav_bar.dart';
import 'package:renizo/features/onboarding/screens/onboarding_slides_screen.dart';
import 'package:renizo/features/seller/screens/provider_app_screen.dart';
import 'package:renizo/features/town/screens/town_selection_screen.dart';

/// Login – API login; navigates by role (customer vs provider).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  static const String routeName = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  final bool _loginAsProvider = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ label like screenshot
  Widget _authLabel(String text) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(
      text,
      textAlign: TextAlign.start,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: AllColor.white,
      ),
    ),
  );

  // ✅ input decoration like screenshot
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

  // ✅ shadow wrapper (field)
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

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    await ref
        .read(loginProvider.notifier)
        .login(email: email, password: password);

    if (!mounted) return;

    final loginState = ref.read(loginProvider);
    setState(() => _loading = false);

    if (loginState.error != null) {
      setState(() => _error = loginState.error);
      return;
    }

    if (!loginState.isSuccess) return;

    final user = await AuthLocalStorage.getCurrentUser();
    if (user == null) return;

    // Navigate by role: provider -> provider app; customer -> onboarding/town/home
    if (user.isProvider) {
      context.push(ProviderAppScreen.routeName);
    } else {
      final hasOnboarded = await AuthLocalStorage.hasOnboarded(user.id);
      if (!hasOnboarded) {
        context.push(OnboardingSlidesScreen.routeName);
      } else {
        final town = await AuthLocalStorage.getSelectedTown(user.id);
        if (town == null || town.isEmpty) {
          context.push(TownSelectionScreen.routeName);
        } else {
          context.push(BottomNavBar.routeName);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AllColor.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              SizedBox(height: 24.h),
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
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AllColor.white,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Sign in to continue',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AllColor.white.withOpacity(0.9),
                ),
              ),

              if (_error != null) ...[
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
                    _error!,
                    style: TextStyle(fontSize: 14.sp, color: AllColor.white),
                  ),
                ),
              ],

              SizedBox(height: 24.h),

              // ✅ Email (same design)
              _authLabel("Email Address"),
              _fieldWrapper(
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 14.sp, color: AllColor.foreground),
                  decoration: _authDecoration(
                    hint: "your@email.com",
                    prefix: Icons.mail_outline_rounded,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // ✅ Password (same design)
              _authLabel("Password"),
              _fieldWrapper(
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(fontSize: 14.sp, color: AllColor.foreground),
                  decoration: _authDecoration(
                    hint: "••••••••••",
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

              SizedBox(height: 35.h),

              SizedBox(height: 24.h),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _login,
                  style: FilledButton.styleFrom(
                    backgroundColor: AllColor.white,
                    foregroundColor: AllColor.primary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: _loading
                      ? SizedBox(
                          height: 24.h,
                          width: 24.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AllColor.primary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.login),
                            SizedBox(width: 8.w),
                            Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: AllColor.white.withOpacity(0.4)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: AllColor.white70,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: AllColor.white.withOpacity(0.4)),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              OutlinedButton(
                onPressed: () => context.push(RegisterScreen.routeName),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AllColor.white,
                  side: BorderSide(color: AllColor.white.withOpacity(0.5)),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add),
                    SizedBox(width: 8.w),
                    Text(
                      'Create New Account',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),
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
}
