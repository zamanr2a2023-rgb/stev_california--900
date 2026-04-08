import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/auth/screens/home_screen.dart';
import 'package:renizo/features/nav_bar/screen/bottom_nav_bar.dart';
import 'package:renizo/features/seller/screens/provider_app_screen.dart';

class AppLogoButton extends StatelessWidget {
  const AppLogoButton({
    super.key,
    this.size = 46,
   // this.logoPath = 'assets/Renizo.png',
    this.logoPath ='assets/logoImage.png',
    this.onTap,
  });

  final double size;
  final String logoPath;
  final VoidCallback? onTap;

  Future<void> _goHome(BuildContext context) async {
    final user = await AuthLocalStorage.getCurrentUser();
    if (!context.mounted) return;
    if (user?.isProvider == true) {
      context.go(ProviderAppScreen.routeName);
      return;
    }
    if (user != null) {
      context.go(BottomNavBar.routeName);
      return;
    }
    context.go(HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => _goHome(context),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: size.w,
          height: size.w,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Image.asset(
            logoPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.home_rounded,
              size: (size * 0.5).sp,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
