import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/models/town.dart';
import 'package:renizo/features/home/widgets/customer_header.dart';
import 'package:renizo/features/nav_bar/screen/bottom_nav_bar.dart';
import 'package:renizo/features/notifications/screens/notifications_screen.dart';
import 'package:renizo/core/widgets/app_logo_button.dart';

import '../../town/screens/town_selection_screen.dart';

/// Settings – full conversion from React SettingsScreen.tsx.
/// Blue bg, header with back, sections: Preferences, Privacy & Security, About, Danger Zone.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    this.onBack,
    this.selectedTownName,
    this.selectedTownId,
    this.onChangeTown,
    this.onNotifications,
  });

  final VoidCallback? onBack;
  final String? selectedTownName;
  final String? selectedTownId;
  final VoidCallback? onChangeTown;
  final VoidCallback? onNotifications;

  static const String routeName = '/settings';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _selectedTownName;

  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _bookingReminders = true;
  bool _promotionalEmails = false;
  bool _darkMode = false;
  final String _language = 'English';

  static const Color _bgBlue = Color(0xFF2384F4);

  Future<void> _onChangeTown() async {
    widget.onChangeTown?.call();
    if (widget.onChangeTown != null) return;
    if (!mounted) return;
    final town = await Navigator.of(context).push<Town>(
      MaterialPageRoute<Town>(
        builder: (context) => TownSelectionScreenWithProvider(
          onSelectTown: (t) => Navigator.of(context).pop(t),
          canClose: true,
        ),
      ),
    );
    if (town != null && mounted) {
      setState(() {
        _selectedTownName = town.name;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Now showing services in ${town.name}')),
        );
      }
    }
  }

  void _onNotifications() {
    widget.onNotifications?.call();
    if (widget.onNotifications != null) return;
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            NotificationsScreen(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  void _onNavTabTap(int index) {
    if (index == 4) return;
    Navigator.of(context).pop();
    ref.read(selectedIndexProvider.notifier).state = index;
  }

  void _onBack() {
    widget.onBack?.call();
    if (widget.onBack != null) return;
    if (mounted) Navigator.of(context).pop();
  }

  void _onToggle(String key) {
    setState(() {
      switch (key) {
        case 'darkMode':
          _darkMode = !_darkMode;
          break;
        case 'pushNotifications':
          _pushNotifications = !_pushNotifications;
          break;
        case 'emailNotifications':
          _emailNotifications = !_emailNotifications;
          break;
        case 'smsNotifications':
          _smsNotifications = !_smsNotifications;
          break;
        case 'bookingReminders':
          _bookingReminders = !_bookingReminders;
          break;
        case 'promotionalEmails':
          _promotionalEmails = !_promotionalEmails;
          break;
      }
    });
    final label = key
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (m) => ' ${m.group(0)!.toLowerCase()}',
        )
        .trim();
    final enabled = key == 'darkMode'
        ? _darkMode
        : key == 'pushNotifications'
        ? _pushNotifications
        : key == 'emailNotifications'
        ? _emailNotifications
        : key == 'smsNotifications'
        ? _smsNotifications
        : key == 'bookingReminders'
        ? _bookingReminders
        : _promotionalEmails;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${label[0].toUpperCase()}${label.substring(1)} ${enabled ? 'enabled' : 'disabled'}',
          ),
        ),
      );
    }
  }

  void _onChangePassword() {
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: _bgBlue,
          appBar: AppBar(
            backgroundColor: _bgBlue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Change Password',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: AppLogoButton(size: 34),
              ),
            ],
          ),
          body: const Center(
            child: Text(
              'Change Password – coming soon',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }

  void _onPrivacyPolicy() {
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: _bgBlue,
          appBar: AppBar(
            backgroundColor: _bgBlue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: AppLogoButton(size: 34),
              ),
            ],
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Text(
              'Privacy Policy – coming soon. We respect your privacy and protect your data.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  void _onTermsOfService() {
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: _bgBlue,
          appBar: AppBar(
            backgroundColor: _bgBlue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Terms of Service',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: AppLogoButton(size: 34),
              ),
            ],
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Text(
              'Terms of Service – coming soon. Please read our terms and conditions.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  void _onLanguage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Language selection – coming soon')),
      );
    }
  }

  void _onDeleteAccount() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Permanently delete your account and all data? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete account – coming soon')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlue,
      bottomNavigationBar: CustomerBottomNavBar(
        currentIndex: 4,
        onTabTap: _onNavTabTap,
      ),
      body: Column(
        children: [
          CustomerHeader(
            leading: IconButton(
              onPressed: _onBack,
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 22.sp,
                color: Colors.white,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            selectedTownName: widget.selectedTownName ?? _selectedTownName,
            onChangeTown: _onChangeTown,
            onNotifications: _onNotifications,
          ),
          _buildTitle(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Preferences'),
                  _preferencesCard(),
                  SizedBox(height: 24.h),
                  _sectionTitle('Privacy & Security'),
                  _privacySecurityCard(),
                  SizedBox(height: 24.h),
                  _sectionTitle('About'),
                  _aboutCard(),
                  SizedBox(height: 24.h),
                  _sectionTitle('Danger Zone'),
                  _dangerZoneCard(),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _bgBlue,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _preferencesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _SettingToggle(
            icon: Icons.dark_mode_outlined,
            label: 'Dark Mode',
            description: 'Use dark theme for the app',
            value: _darkMode,
            onToggle: () => _onToggle('darkMode'),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.1)),
          _SettingRow(
            icon: Icons.language,
            label: 'Language',
            description: _language,
            onTap: _onLanguage,
          ),
        ],
      ),
    );
  }

  Widget _privacySecurityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _SettingRow(
            icon: Icons.lock_outline,
            label: 'Change Password',
            description: 'Update your account password',
            onTap: _onChangePassword,
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.1)),
          _SettingRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            description: 'View our privacy policy',
            onTap: _onPrivacyPolicy,
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.1)),
          _SettingRow(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            description: 'Read our terms and conditions',
            onTap: _onTermsOfService,
          ),
        ],
      ),
    );
  }

  Widget _aboutCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _AboutRow(label: 'Version', value: '1.0.0'),
          SizedBox(height: 8.h),
          _AboutRow(label: 'Build', value: '2024.01.22'),
        ],
      ),
    );
  }

  Widget _dangerZoneCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onDeleteAccount,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade200,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Permanently delete your account and all data',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.red.shade200,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  const _SettingToggle({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onToggle,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: Colors.white, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (_) => onToggle(),
            activeTrackColor: const Color(0xFF2384F4),
            activeThumbColor: const Color(0xFFFFFFFF),
            inactiveTrackColor: const Color(0xFFB9DFFF),
            inactiveThumbColor: const Color(0xFFFFFFFF),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: Colors.white, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.7),
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }
}
