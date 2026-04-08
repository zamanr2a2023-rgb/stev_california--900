import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/core/models/service_category.dart';
import 'package:renizo/features/home/models/customer_home_models.dart';

/// Primary blue from React ServiceCategories (text-[#408AF1], gradient).
const Color _primary = Color(0xFF408AF1);
const Color _primaryLight = Color(0xFF5ca3f5);

/// Service categories – renders services from API data.
/// If [services] is empty the widget hides itself (SizedBox.shrink).
class ServiceCategoriesWidget extends StatelessWidget {
  const ServiceCategoriesWidget({
    super.key,
    required this.services,
    required this.onSelectService,
    this.lightTitle = false,
  });

  final List<ServiceModel> services;
  final void Function(ServiceModel service) onSelectService;
  final bool lightTitle;

  /// Backward-compatible static accessor used by TaskSubmissionScreen.
  static final List<ServiceCategory> mockCategories = [
    const ServiceCategory(id: 'cat1', name: 'Residential Cleaning', icon: 'Home', description: 'Professional home cleaning services'),
    const ServiceCategory(id: 'cat2', name: 'Commercial Cleaning', icon: 'Building2', description: 'Office and commercial space cleaning'),
    const ServiceCategory(id: 'cat3', name: 'Contract Cleaning', icon: 'CalendarCheck', description: 'Scheduled recurring cleaning'),
    const ServiceCategory(id: 'cat4', name: 'Floor Waxing', icon: 'Sparkles', description: 'Professional floor care'),
    const ServiceCategory(id: 'cat5', name: 'Pressure Washing', icon: 'Droplets', description: 'Power washing services'),
    const ServiceCategory(id: 'cat6', name: 'Grass Cutting', icon: 'Scissors', description: 'Lawn maintenance services'),
    const ServiceCategory(id: 'cat7', name: 'Snow Removal', icon: 'Snowflake', description: 'Winter snow clearing'),
    const ServiceCategory(id: 'cat8', name: 'Laundry', icon: 'Shirt', description: 'Laundry and ironing services'),
  ];

  /// Icon name (React Lucide) → SVG asset path.
  static const Map<String, String> _iconAssets = {
    'Home': 'assets/images/icons/home.svg',
    'Building2': 'assets/images/icons/building-2.svg',
    'CalendarCheck': 'assets/images/icons/calendar-check.svg',
    'Sparkles': 'assets/images/icons/sparkles.svg',
    'Droplets': 'assets/images/icons/droplets.svg',
    'Scissors': 'assets/images/icons/scissors.svg',
    'Snowflake': 'assets/images/icons/snowflake.svg',
    'Shirt': 'assets/images/icons/shirt.svg',
  };

  static Widget buildCategoryIcon(String iconName, double size) {
    final asset = _iconAssets[iconName];
    if (asset != null) {
      return SvgPicture.asset(
        asset,
        width: size,
        height: size,
        colorFilter: const ColorFilter.mode(_primary, BlendMode.srcIn),
      );
    }
    return Icon(_fallbackIconFor(iconName), size: size, color: _primary);
  }

  static IconData _fallbackIconFor(String iconName) {
    switch (iconName) {
      case 'Home':
        return LucideIcons.house;
      case 'Building2':
        return LucideIcons.building2;
      case 'CalendarCheck':
        return LucideIcons.calendarCheck;
      case 'Sparkles':
        return LucideIcons.sparkles;
      case 'Droplets':
        return LucideIcons.droplets;
      case 'Scissors':
        return LucideIcons.scissors;
      case 'Snowflake':
        return LucideIcons.snowflake;
      case 'Shirt':
        return LucideIcons.shirt;
      default:
        return LucideIcons.sparkles;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();

    final titleColor = lightTitle ? AllColor.white : AllColor.foreground;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services Available',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          SizedBox(height: 16.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 1.0,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _ServiceCard(
                service: service,
                index: index,
                onTap: () => onSelectService(service),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Service Card ────────────────────────────────────────────────────────────

class _ServiceCard extends StatefulWidget {
  const _ServiceCard({
    required this.service,
    required this.index,
    required this.onTap,
  });

  final ServiceModel service;
  final int index;
  final VoidCallback onTap;

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: (widget.index * 50).round()), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: Material(
        color: AllColor.white,
        borderRadius: BorderRadius.circular(16.r),
        elevation: 2,
        shadowColor: AllColor.primary.withOpacity(0.1),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _primary.withOpacity(0.1),
                          _primaryLight.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: ServiceCategoriesWidget.buildCategoryIcon(
                        widget.service.icon,
                        24.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                  Text(
                    widget.service.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111827),
                      //color:Colors.red
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
