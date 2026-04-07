import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/models/town.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/bookings/screens/bookings_screen.dart';
import 'package:renizo/features/home/screens/customer_home_screen.dart';
import 'package:renizo/features/messages/screens/messages_screen.dart';
import 'package:renizo/features/profile/logic/user_riverpod.dart';
import 'package:renizo/features/profile/screens/profile_screen.dart';
import 'package:renizo/features/search/screens/search_screen.dart';
import 'package:renizo/features/town/screens/town_selection_screen.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom nav colors and style – matches React BottomNav.tsx.
const Color _navBackground = Color(0xFF003E93);
const Color _navSelectedStart = Color(0xFF408AF1);
const Color _navSelectedEnd = Color(0xFF5ca3f5);
const Color _navUnselected = Color(0xB3FFFFFF); // white/70

/// If town is already selected → show Home (dashboard). If town is null → show TownSelectionScreen; after select → dashboard.
class BottomNavBar extends ConsumerStatefulWidget {
  const BottomNavBar({super.key});
  static const String routeName = '/BottomNavBar';

  @override
  ConsumerState<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends ConsumerState<BottomNavBar> {
  Town? _selectedTown;
  bool _townChecked = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedTown();
  }

  Future<void> _loadSelectedTown() async {
    final user = await AuthLocalStorage.getCurrentUser();
    if (user == null) {
      if (mounted) setState(() => _townChecked = true);
      return;
    }
    final townJson = await AuthLocalStorage.getSelectedTown(user.id);
    if (townJson == null || townJson.isEmpty) {
      // Fallback: pull town from profile API if available
      try {
        final me = await ref.read(userMeApiProvider).fetchMe();
        if (me.townId != null && me.townId!.isNotEmpty) {
          final payload = jsonEncode({
            'id': me.townId!,
            'name': me.townName ?? '',
            'isActive': true,
          });
          await AuthLocalStorage.setSelectedTown(user.id, payload);
          if (mounted) {
            setState(() {
              _selectedTown = Town(
                id: me.townId!,
                name: me.townName ?? '',
                isActive: true,
              );
              _townChecked = true;
            });
          }
          return;
        }
      } catch (_) {
        // ignore and fall back to selection
      }
      if (mounted) {
        setState(() {
        _selectedTown = null;
        _townChecked = true;
      });
      }
      return;
    }
    try {
      final map = jsonDecode(townJson) as Map<String, dynamic>?;
      if (map != null && map['id'] != null) {
        if (mounted) {
          setState(() {
            _selectedTown = Town(
              id: (map['id'] ?? '').toString(),
              name: (map['name'] ?? '').toString(),
              isActive: (map['isActive'] ?? true) == true,
            );
            _townChecked = true;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
      _selectedTown = null;
      _townChecked = true;
    });
    }
  }

  void _onTownSelected(Town town) {
    setState(() => _selectedTown = town);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    if (!_townChecked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_selectedTown == null) {
      return TownSelectionScreen(
        onSelectTown: _onTownSelected,
        canClose: false,
      );
    }

    final town = _selectedTown!;
    final pages = <Widget>[
      CustomerHomeScreen(
        selectedTownId: town.id,
        selectedTownName: town.name,
      ),
      SearchScreen(selectedTownId: town.id),
      BookingsScreen(townId: town.id),
      MessagesScreen(
        selectedTownId: town.id,
        selectedTownName: town.name,
      ),
      ProfileScreen(
        selectedTownId: town.id,
        selectedTownName: town.name,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: CustomerBottomNavBar(
        currentIndex: selectedIndex,
        onTabTap: (index) =>
            ref.read(selectedIndexProvider.notifier).state = index,
      ),
    );
  }
}

/// Reusable bottom nav bar – same look as BottomNavBar; use for CustomerHomeScreen-style screens.
class CustomerBottomNavBar extends StatelessWidget {
  const CustomerBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTabTap;

  static const List<_NavItem> _tabs = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.search_rounded, label: 'Search'),
    _NavItem(icon: Icons.calendar_today_rounded, label: 'Bookings'),
    _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _navBackground,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 5, left: 16.w, right: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              final isActive = currentIndex == index;
              return _NavBarItem(
                icon: tab.icon,
                label: tab.label,
                isActive: isActive,
                onTap: () => onTabTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  gradient: isActive
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_navSelectedStart, _navSelectedEnd],
                        )
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 20.sp,
                  color: isActive ? Colors.white : _navUnselected,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                  color: isActive ? Colors.white : _navUnselected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
