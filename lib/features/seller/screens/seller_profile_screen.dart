// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';
// import 'package:renizo/core/utils/auth_local_storage.dart';
// import 'package:renizo/features/auth/screens/login_screen.dart';
// import 'package:renizo/features/notifications/screens/notifications_screen.dart';
// import 'package:renizo/features/profile/screens/help_support_screen.dart';
// import 'package:renizo/features/profile/screens/payment_methods_screen.dart';
// import 'package:renizo/features/profile/screens/settings_screen.dart';
//
// // TSX SellerProfileScreen.tsx colors
// class _ProfileColors {
//   static const blueBg = Color(0xFF2384F4);
//   static const gray50 = Color(0xFFF9FAFB);
//   static const gray100 = Color(0xFFF3F4F6);
//   static const gray400 = Color(0xFF9CA3AF);
//   static const gray500 = Color(0xFF6B7280);
//   static const gray900 = Color(0xFF111827);
//   static const red50 = Color(0xFFFEF2F2);
//   static const red600 = Color(0xFFDC2626);
//   static const orange50 = Color(0xFFFFF7ED);
//   static const orange600 = Color(0xFFEA580C);
//   static const pink50 = Color(0xFFFDF2F8);
//   static const pink600 = Color(0xFFDB2777);
//   static const cyan50 = Color(0xFFECFEFF);
//   static const cyan600 = Color(0xFF0891B2);
//   static const blueAccent = Color(0xFF408AF1);
// }
//
// /// Seller profile – full conversion from React SellerProfileScreen.tsx.
// /// Blue bg, profile card (avatar, name, email, Pro badge, stats), service areas, services offered, account menu, logout.
// class SellerProfileScreen extends StatelessWidget {
//   const SellerProfileScreen({
//     super.key,
//     this.showAppBar = true,
//     this.onLogout,
//   });
//
//   final bool showAppBar;
//   final VoidCallback? onLogout;
//
//   @override
//   Widget build(BuildContext context) {
//     final content = Container(
//       width: double.infinity,
//       color: _ProfileColors.blueBg,
//       child: FutureBuilder(
//         future: AuthLocalStorage.getCurrentUser(),
//         builder: (context, snap) {
//           final user = snap.data;
//           final name = user?.name ?? 'Mike Johnson';
//           final email = user?.email ?? 'provider@demo.com';
//           return ListView(
//             padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 32.h),
//             children: [
//               _ProfileCard(name: name, email: email),
//               SizedBox(height: 24.h),
//               _ServiceAreasSection(),
//               SizedBox(height: 24.h),
//               _ServicesOfferedSection(),
//               SizedBox(height: 24.h),
//               _AccountMenuSection(),
//               SizedBox(height: 16.h),
//               _LogoutButton(onLogout: onLogout),
//               SizedBox(height: 24.h),
//               Center(child: Text('Version 1.0.0', style: TextStyle(fontSize: 12.sp, color: _ProfileColors.gray400))),
//               SizedBox(height: 80.h),
//             ],
//           );
//         },
//       ),
//     );
//
//     if (!showAppBar) return content;
//     return Scaffold(
//       backgroundColor: _ProfileColors.blueBg,
//       appBar: AppBar(
//         title: Text('Profile', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white)),
//         backgroundColor: _ProfileColors.blueBg,
//         elevation: 0,
//       ),
//       body: content,
//     );
//   }
// }
//
// /// TSX: Profile card – bg-white/10 backdrop-blur rounded-3xl p-6, avatar, name, email, Pro badge, stats row.
// class _ProfileCard extends StatelessWidget {
//   const _ProfileCard({required this.name, required this.email});
//
//   final String name;
//   final String email;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(24.w),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(24.r),
//         border: Border.all(color: Colors.white.withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 80.w,
//                 height: 80.w,
//                 decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16.r)),
//                 child: Icon(Icons.person, size: 40.sp, color: Colors.white),
//               ),
//               SizedBox(width: 16.w),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(name, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: Colors.white)),
//                     SizedBox(height: 4.h),
//                     Text(email, style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.8))),
//                     SizedBox(height: 6.h),
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
//                       decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8.r)),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.emoji_events_outlined, size: 16.sp, color: Colors.white),
//                           SizedBox(width: 6.w),
//                           Text('Pro Provider', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.white)),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 16.h),
//           Container(height: 1, color: Colors.white.withOpacity(0.2)),
//           SizedBox(height: 16.h),
//           Row(
//             children: [
//               Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('156', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w500, color: Colors.white)), SizedBox(height: 2.h), Text('Jobs Done', style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.8)))])),
//               Container(width: 1, height: 40.h, color: Colors.white.withOpacity(0.2)),
//               Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('4.8', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w500, color: Colors.white)), SizedBox(height: 2.h), Text('Rating', style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.8)))])),
//               Container(width: 1, height: 40.h, color: Colors.white.withOpacity(0.2)),
//               Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('98%', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w500, color: Colors.white)), SizedBox(height: 2.h), Text('Success', style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.8)))])),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /// TSX: SERVICE AREAS – white card with town chips.
// class _ServiceAreasSection extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final towns = ['Terrace', 'Kitimat', 'Prince Rupert'];
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(padding: EdgeInsets.only(left: 4.w, bottom: 12.h), child: Text('SERVICE AREAS', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9)))),
//         Container(
//           width: double.infinity,
//           padding: EdgeInsets.all(16.w),
//           decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: _ProfileColors.gray100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 1))]),
//           child: Wrap(
//             spacing: 8.w,
//             runSpacing: 8.h,
//             children: towns.map((town) => Container(
//               padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(colors: [const Color(0xFFEFF6FF), const Color(0xFFECFEFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
//                 borderRadius: BorderRadius.circular(12.r),
//                 border: Border.all(color: const Color(0xFFBFDBFE)),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.location_on_outlined, size: 16.sp, color: _ProfileColors.blueAccent),
//                   SizedBox(width: 8.w),
//                   Text(town, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: _ProfileColors.gray900)),
//                 ],
//               ),
//             )).toList(),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// /// TSX: SERVICES OFFERED – white card with category rows.
// class _ServicesOfferedSection extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final services = [
//       ('Residential Cleaning', 'Home cleaning services'),
//       ('Grass Cutting', 'Lawn mowing and yard care'),
//       ('Plumbing', 'Repairs and installations'),
//     ];
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(padding: EdgeInsets.only(left: 4.w, bottom: 12.h), child: Text('SERVICES OFFERED', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9)))),
//         Container(
//           padding: EdgeInsets.all(16.w),
//           decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: _ProfileColors.gray100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 1))]),
//           child: Column(
//             children: services.asMap().entries.map((e) {
//               final name = e.value.$1;
//               final desc = e.value.$2;
//               return Padding(
//                 padding: EdgeInsets.only(bottom: e.key < services.length - 1 ? 8.h : 0),
//                 child: Container(
//                   padding: EdgeInsets.all(12.w),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(colors: [_ProfileColors.gray50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
//                     borderRadius: BorderRadius.circular(12.r),
//                     border: Border.all(color: _ProfileColors.gray100),
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 40.w,
//                         height: 40.w,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(colors: [_ProfileColors.blueAccent.withOpacity(0.2), _ProfileColors.blueAccent.withOpacity(0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
//                           borderRadius: BorderRadius.circular(12.r),
//                         ),
//                         child: Icon(Icons.build_outlined, size: 20.sp, color: _ProfileColors.blueAccent),
//                       ),
//                       SizedBox(width: 12.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(name, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: _ProfileColors.gray900)),
//                             SizedBox(height: 2.h),
//                             Text(desc, style: TextStyle(fontSize: 12.sp, color: _ProfileColors.gray500)),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// /// TSX: ACCOUNT menu – Notifications, Payment Settings, Settings, Help & Support.
// class _AccountMenuSection extends StatelessWidget {
//   const _AccountMenuSection();
//
//   @override
//   Widget build(BuildContext context) {
//     final items = [
//       _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications', iconBg: _ProfileColors.orange50, iconColor: _ProfileColors.orange600, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(onBack: () => Navigator.pop(context))))),
//       _MenuItem(icon: Icons.credit_card_outlined, label: 'Payment Settings', iconBg: _ProfileColors.pink50, iconColor: _ProfileColors.pink600, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentMethodsScreen(onBack: () => Navigator.pop(context))))),
//       _MenuItem(icon: Icons.settings_outlined, label: 'Settings', iconBg: _ProfileColors.gray50, iconColor: _ProfileColors.gray900, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(onBack: () => Navigator.pop(context))))),
//       _MenuItem(icon: Icons.help_outline, label: 'Help & Support', iconBg: _ProfileColors.cyan50, iconColor: _ProfileColors.cyan600, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HelpSupportScreen(onBack: () => Navigator.pop(context))))),
//     ];
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(padding: EdgeInsets.only(left: 4.w, bottom: 12.h), child: Text('ACCOUNT', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9)))),
//         ...items.map((item) => Padding(
//           padding: EdgeInsets.only(bottom: 8.h),
//           child: Material(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16.r),
//             child: InkWell(
//               onTap: item.onTap,
//               borderRadius: BorderRadius.circular(16.r),
//               child: Container(
//                 padding: EdgeInsets.all(16.w),
//                 decoration: BoxDecoration(borderRadius: BorderRadius.circular(16.r), border: Border.all(color: _ProfileColors.gray100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 1))]),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 40.w,
//                       height: 40.w,
//                       decoration: BoxDecoration(color: item.iconBg, borderRadius: BorderRadius.circular(12.r)),
//                       child: Icon(item.icon, size: 20.sp, color: item.iconColor),
//                     ),
//                     SizedBox(width: 12.w),
//                     Expanded(child: Text(item.label, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: _ProfileColors.gray900))),
//                     Icon(Icons.chevron_right, size: 20.sp, color: _ProfileColors.gray400),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         )),
//       ],
//     );
//   }
// }
//
// class _MenuItem {
//   final IconData icon;
//   final String label;
//   final Color iconBg;
//   final Color iconColor;
//   final VoidCallback onTap;
//   _MenuItem({required this.icon, required this.label, required this.iconBg, required this.iconColor, required this.onTap});
// }
//
// /// TSX: Logout button – red-50 bg, red-600 text.
// class _LogoutButton extends StatelessWidget {
//   const _LogoutButton({required this.onLogout});
//
//   final VoidCallback? onLogout;
//
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: _ProfileColors.red50,
//       borderRadius: BorderRadius.circular(16.r),
//       child: InkWell(
//         onTap: () async {
//           if (onLogout != null) {
//             onLogout!();
//             return;
//           }
//           await AuthLocalStorage.clearSession();
//           if (context.mounted) context.go(LoginScreen.routeName);
//         },
//         borderRadius: BorderRadius.circular(16.r),
//         child: Container(
//           width: double.infinity,
//           padding: EdgeInsets.symmetric(vertical: 16.h),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.logout, size: 20.sp, color: _ProfileColors.red600),
//               SizedBox(width: 8.w),
//               Text('Log Out', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: _ProfileColors.red600)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/core/widgets/app_logo_button.dart';
import 'package:renizo/features/auth/screens/login_screen.dart';
import 'package:renizo/features/notifications/screens/notifications_screen.dart';
import 'package:renizo/features/profile/screens/help_support_screen.dart';
import 'package:renizo/features/profile/screens/settings_screen.dart';

import '../logic/provider_profile_logic.dart';
import '../models/seller_provider_model.dart';

class _ProfileColors {
  static const blueBg = Color(0xFF2384F4);
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray900 = Color(0xFF111827);
  static const red50 = Color(0xFFFEF2F2);
  static const red600 = Color(0xFFDC2626);
  static const orange50 = Color(0xFFFFF7ED);
  static const orange600 = Color(0xFFEA580C);
  static const pink50 = Color(0xFFFDF2F8);
  static const pink600 = Color(0xFFDB2777);
  static const cyan50 = Color(0xFFECFEFF);
  static const cyan600 = Color(0xFF0891B2);
  static const blueAccent = Color(0xFF408AF1);
}

class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key, this.showAppBar = true, this.onLogout});

  final bool showAppBar;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(providerProfileScreenProvider);

    final content = Container(
      width: double.infinity,
      color: _ProfileColors.blueBg,
      child: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load profile',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
                SizedBox(height: 10.h),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(providerProfileScreenProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (model) {
          final name = model.user.fullName.isNotEmpty
              ? model.user.fullName
              : 'Mike Johnson';
          final email = model.user.email.isNotEmpty
              ? model.user.email
              : 'provider@demo.com';
          final badgeText =
              (model.user.badge == null || model.user.badge!.trim().isEmpty)
              ? 'Pro Provider'
              : model.user.badge!.trim();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(providerProfileScreenProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 32.h),
              children: [
                _ProfileCard(
                  name: name,
                  email: email,
                  badgeText: badgeText,
                  jobsDone: model.stats.jobsDone.toString(),
                  rating: model.stats.rating.toStringAsFixed(1),
                  success: '${model.stats.successRate}%',
                ),
                SizedBox(height: 24.h),
                _ServiceAreasSection(towns: model.serviceAreas),
                SizedBox(height: 24.h),
                _ServicesOfferedSection(services: model.servicesOffered),
                SizedBox(height: 24.h),
                const _AccountMenuSection(),
                SizedBox(height: 16.h),
                _LogoutButton(onLogout: onLogout),
                SizedBox(height: 24.h),
                Center(
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: _ProfileColors.gray400,
                    ),
                  ),
                ),
                SizedBox(height: 80.h),
              ],
            ),
          );
        },
      ),
    );

    if (!showAppBar) return content;

    return Scaffold(
      backgroundColor: _ProfileColors.blueBg,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: _ProfileColors.blueBg,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: AppLogoButton(size: 34),
          ),
        ],
      ),
      body: content,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.badgeText,
    required this.jobsDone,
    required this.rating,
    required this.success,
  });

  final String name;
  final String email;
  final String badgeText;
  final String jobsDone;
  final String rating;
  final String success;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(Icons.person, size: 40.sp, color: Colors.white),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _StatBlock(value: jobsDone, label: 'Jobs Done'),
              ),
              Container(
                width: 1,
                height: 40.h,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _StatBlock(value: rating, label: 'Rating'),
              ),
              Container(
                width: 1,
                height: 40.h,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _StatBlock(value: success, label: 'Success'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _ServiceAreasSection extends StatelessWidget {
  const _ServiceAreasSection({required this.towns});
  final List<String> towns;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Text(
            'SERVICE AREAS',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: _ProfileColors.gray100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: towns.isEmpty
              ? Text(
                  'No service areas yet',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: _ProfileColors.gray500,
                  ),
                )
              : Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: towns.map((town) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEFF6FF), Color(0xFFECFEFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16.sp,
                            color: _ProfileColors.blueAccent,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            town,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: _ProfileColors.gray900,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _ServicesOfferedSection extends StatelessWidget {
  const _ServicesOfferedSection({required this.services});
  final List<ProviderService> services;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Text(
            'SERVICES OFFERED',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: _ProfileColors.gray100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: services.isEmpty
              ? Text(
                  'No services offered yet',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: _ProfileColors.gray500,
                  ),
                )
              : Column(
                  children: services.asMap().entries.map((e) {
                    final s = e.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: e.key < services.length - 1 ? 8.h : 0,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_ProfileColors.gray50, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: _ProfileColors.gray100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _ProfileColors.blueAccent.withOpacity(0.2),
                                    _ProfileColors.blueAccent.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: _ServiceOfferedIcon(iconUrl: s.iconUrl),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w500,
                                      color: _ProfileColors.gray900,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    s.description.isEmpty ? '—' : s.description,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: _ProfileColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _ServiceOfferedIcon extends StatelessWidget {
  const _ServiceOfferedIcon({required this.iconUrl});

  final String iconUrl;

  @override
  Widget build(BuildContext context) {
    if (iconUrl.isEmpty) {
      return Icon(
        Icons.build_outlined,
        size: 20.sp,
        color: _ProfileColors.blueAccent,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Image.network(
        iconUrl,
        width: 24.w,
        height: 24.w,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.build_outlined,
          size: 20.sp,
          color: _ProfileColors.blueAccent,
        ),
      ),
    );
  }
}

class _AccountMenuSection extends StatelessWidget {
  const _AccountMenuSection();

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        iconBg: _ProfileColors.orange50,
        iconColor: _ProfileColors.orange600,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                NotificationsScreen(onBack: () => Navigator.pop(context)),
          ),
        ),
      ),
      // _MenuItem(
      //   icon: Icons.credit_card_outlined,
      //   label: 'Payment Settings',
      //   iconBg: _ProfileColors.pink50,
      //   iconColor: _ProfileColors.pink600,
      //   onTap: () => Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //       builder: (_) =>
      //           PaymentMethodsScreen(onBack: () => Navigator.pop(context)),
      //     ),
      //   ),
      // ),
      _MenuItem(
        icon: Icons.settings_outlined,
        label: 'Settings',
        iconBg: _ProfileColors.gray50,
        iconColor: _ProfileColors.gray900,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SettingsScreen(onBack: () => Navigator.pop(context)),
          ),
        ),
      ),
      _MenuItem(
        icon: Icons.help_outline,
        label: 'Help & Support',
        iconBg: _ProfileColors.cyan50,
        iconColor: _ProfileColors.cyan600,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HelpSupportScreen(onBack: () => Navigator.pop(context)),
          ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Text(
            'ACCOUNT',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
        ...items.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: _ProfileColors.gray100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: item.iconBg,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          item.icon,
                          size: 20.sp,
                          color: item.iconColor,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            color: _ProfileColors.gray900,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20.sp,
                        color: _ProfileColors.gray400,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
  _MenuItem({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onLogout});
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ProfileColors.red50,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: () async {
          if (onLogout != null) {
            onLogout!();
            return;
          }
          await AuthLocalStorage.clearSession();
          if (context.mounted) context.go(LoginScreen.routeName);
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, size: 20.sp, color: _ProfileColors.red600),
              SizedBox(width: 8.w),
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: _ProfileColors.red600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
