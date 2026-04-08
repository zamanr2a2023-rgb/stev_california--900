import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/features/bookings/data/bookings_mock_data.dart';
import 'package:renizo/features/seller/models/seller_job_item.dart';

import '../data/bookings_riverpod.dart';
import '../logic/seller_home_logic.dart';
import '../models/seller_bookings.dart';

// TSX/Tailwind colors – same as SellerHome.tsx
class _SellerHomeColors {
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
}

// Same colors used in SellerBookingsScreen booking card
class _BookingsColors {
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const yellow100 = Color(0xFFFEF9C3);
  static const yellow700 = Color(0xFFA16207);
  static const green100 = Color(0xFFDCFCE7);
  static const green700 = Color(0xFF15803D);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue700 = Color(0xFF1D4ED8);
  static const red100 = Color(0xFFFEE2E2);
  static const red700 = Color(0xFFB91C1C);
}

/// Format date like TSX: toLocaleDateString("en-US", { month: "short", day: "numeric" }) → "Jan 18"
String _formatScheduleDate(String scheduledDate) {
  if (scheduledDate.contains('-')) {
    final d = DateTime.tryParse(scheduledDate);
    if (d != null) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[d.month - 1]} ${d.day}';
    }
  }
  return scheduledDate;
}

String _enumName(Object e) => e.toString().split('.').last;
String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

BookingStatus _mapProviderBookingStatus(String raw) {
  final s = raw.trim().toLowerCase();
  if (s == 'pending' || s == 'pending_payment') return BookingStatus.pending;
  if (s == 'rejected') return BookingStatus.rejected;
  if (s == 'accepted') return BookingStatus.accepted;
  if (s == 'paid' || s == 'confirmed') return BookingStatus.confirmed;
  if (s == 'inprogress' || s == 'in_progress' || s == 'in-progress') {
    return BookingStatus.inProgress;
  }
  if (s == 'active') return BookingStatus.inProgress;
  if (s == 'completed') return BookingStatus.completed;
  if (s == 'cancelled' || s == 'canceled') return BookingStatus.cancelled;
  return BookingStatus.pending;
}

SellerJobItem _toSellerJobItem(ProviderBookingItem item) {
  return SellerJobItem(
    id: item.id,
    customerName: item.customerName.isEmpty ? '—' : item.customerName,
    categoryName: item.categoryName.isEmpty ? '—' : item.categoryName,
    townName: item.townName.isEmpty ? '—' : item.townName,
    scheduledDate: item.scheduledDate.isEmpty ? '—' : item.scheduledDate,
    scheduledTime: item.scheduledTime.isEmpty ? '—' : item.scheduledTime,
    notes: item.notes.isEmpty ? null : item.notes,
    paidInApp: item.paidInApp,
    status: _mapProviderBookingStatus(item.status),
  );
}

/// ✅ Option-B: No DashboardScreen.
/// এই স্ক্রিনের ভেতরেই Riverpod দিয়ে `/providers/me/dashboard` fetch হবে।
class SellerHomeScreen extends ConsumerWidget {
  const SellerHomeScreen({
    super.key,
    this.upcomingJobs = const <SellerJobItem>[],
    this.pendingRequests = const <SellerJobItem>[],
    this.onSelectJob,
    this.onManageServices,
    this.onManagePricing,
    this.onStatusChange,
    required bool providerStatusActive,
  });

  // (Jobs list এখনো optional; আপনার API তে recentJobs empty থাকলে UI empty state দেখাবে)
  final List<SellerJobItem> upcomingJobs;
  final List<SellerJobItem> pendingRequests;

  final void Function(String jobId)? onSelectJob;
  final VoidCallback? onManageServices;
  final VoidCallback? onManagePricing;
  final void Function(bool active)? onStatusChange;

  static const Color _heroBlue = Color(0xFF1B6BD4);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(providerDashboardProvider);
    final bookingsAsync = ref.watch(providerMyBookingsProvider);

    return async.when(
      loading: () => Container(
        width: double.infinity,
        color: _heroBlue,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      error: (e, _) => Container(
        width: double.infinity,
        color: _heroBlue,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load dashboard',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  '$e',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () => ref.invalidate(providerDashboardProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (m) {
        final override = ref.watch(providerAvailabilityOverrideProvider);
        final providerActive = override ?? m.availability.acceptingJobs;

        final providerName = (m.user.fullName.trim().isNotEmpty)
            ? m.user.fullName.trim()
            : 'Provider';
        final providerAvatarUrl =
            'https://i.pravatar.cc/300?u=${Uri.encodeComponent(providerName)}';

        final bookingsData = bookingsAsync.asData?.value;
        final bookingItems =
            bookingsData?.items ?? const <ProviderBookingItem>[];
        final apiJobs = bookingItems.map(_toSellerJobItem).toList();

        final pendingJobs = apiJobs
            .where((j) => j.status == BookingStatus.pending)
            .toList();
        final activeJobs = apiJobs
            .where(
              (j) =>
                  j.status == BookingStatus.confirmed ||
                  j.status == BookingStatus.inProgress,
            )
            .toList();
        final allJobs = apiJobs;

        return SellerHomeContent(
          upcomingJobs: activeJobs,
          pendingRequests: pendingJobs,
          allJobs: allJobs,

          providerStatusActive: providerActive,

          onSelectJob: (jobId) => onSelectJob?.call(jobId),
          onManageServices: () => onManageServices?.call(),
          onManagePricing: () => onManagePricing?.call(),

          onStatusChange: (active) {
            // ✅ UI তে switch সঙ্গে সঙ্গে update হবে
            ref.read(providerAvailabilityOverrideProvider.notifier).state =
                active;

            // ✅ চাইলে parent এ notify
            onStatusChange?.call(active);

            // NOTE: যদি backend এ status update API থাকে, এখানে call করবেন
          },

          // ✅ dashboard values
          providerName: providerName,
          providerAvatarUrl: providerAvatarUrl,
          pendingCount: bookingsData?.counts.pending ?? m.stats.pending,
          activeCount: bookingsData?.counts.active ?? m.stats.active,
          completedCount: bookingsData?.counts.completed ?? m.stats.completed,
          rating: m.stats.rating,
          successRate: m.stats.successRate,
          totalJobs: bookingsData?.counts.all ?? m.stats.totalJobs,
        );
      },
    );
  }
}

class SellerHomeContent extends StatefulWidget {
  const SellerHomeContent({
    super.key,
    required this.upcomingJobs,
    required this.pendingRequests,
    required this.allJobs,
    required this.providerStatusActive,
    required this.onSelectJob,
    required this.onManageServices,
    required this.onManagePricing,
    required this.onStatusChange,

    // ✅ dashboard data
    required this.providerName,
    required this.providerAvatarUrl,
    required this.pendingCount,
    required this.activeCount,
    required this.completedCount,
    required this.rating,
    required this.successRate,
    required this.totalJobs,
  });

  final List<SellerJobItem> upcomingJobs;
  final List<SellerJobItem> pendingRequests;
  final List<SellerJobItem> allJobs;

  final bool providerStatusActive;
  final void Function(String jobId) onSelectJob;
  final VoidCallback onManageServices;
  final VoidCallback onManagePricing;
  final void Function(bool active) onStatusChange;

  final String providerName;
  final String providerAvatarUrl;
  final int pendingCount;
  final int activeCount;
  final int completedCount;
  final double rating;
  final int successRate;
  final int totalJobs;

  @override
  State<SellerHomeContent> createState() => _SellerHomeContentState();
}

class _SellerHomeContentState extends State<SellerHomeContent> {
  String _jobTab = 'pending'; // pending | active | completed

  static const Color _heroBlue = Color(0xFF1B6BD4);

  List<SellerJobItem> get _filteredJobs {
    if (_jobTab == 'active') {
      return widget.allJobs
          .where(
            (j) =>
                j.status == BookingStatus.confirmed ||
                j.status == BookingStatus.inProgress,
          )
          .toList();
    }
    if (_jobTab == 'completed') {
      return widget.allJobs
          .where((j) => j.status == BookingStatus.completed)
          .toList();
    }
    return widget.allJobs
        .where((j) => j.status == BookingStatus.pending)
        .toList();
  }

  @override


  //Welcome back item:

  Widget build(BuildContext context) {
    final providerName = widget.providerName;
    final providerAvatar = widget.providerAvatarUrl;

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        color: _heroBlue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16.w, 15.h, 16.w, 20.h),
              decoration: const BoxDecoration(color: _heroBlue),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -80.h,
                      right: -80.w,
                      child: Container(
                        width: 160.w,
                        height: 160.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -60.h,
                      left: -60.w,
                      child: Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14.r),
                                    child: CachedNetworkImage(
                                      imageUrl: providerAvatar,
                                      width: 64.w,
                                      height: 64.w,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: Colors.white24,
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white70,
                                          size: 32.sp,
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: Colors.white24,
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white70,
                                          size: 32.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -2.h,
                                  right: -2.w,
                                  child: Container(
                                    width: 20.w,
                                    height: 20.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.green.shade400,
                                      border: Border.all(
                                        color: const Color(0xFF408AF1),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome Back, $providerName! 👋',
                                    style: TextStyle(
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Service Provider',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),

                        // Stats grid
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.schedule,
                                value: '${widget.pendingCount}',
                                label: 'Pending',
                                iconBgColor: Colors.yellow.withOpacity(0.2),
                                iconColor: Colors.yellow.shade300,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.check_circle_outline,
                                value: '${widget.activeCount}',
                                label: 'Active',
                                iconBgColor: Colors.green.withOpacity(0.2),
                                iconColor: Colors.green.shade300,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.star_outline,
                                value: widget.rating.toStringAsFixed(1),
                                label: 'Rating',
                                iconBgColor: Colors.amber.withOpacity(0.2),
                                iconColor: Colors.amber.shade300,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16.h),

                        // Performance badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: Colors.green.shade300,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Success Rate',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                      Text(
                                        '${widget.successRate}%',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.blue.shade300,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Jobs',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                      Text(
                                        '${widget.totalJobs}',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Availability toggle
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 22.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Availability Status',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        widget.providerStatusActive
                                            ? 'Accepting new jobs'
                                            : 'Not accepting jobs',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Switch(
                                value: widget.providerStatusActive,
                                onChanged: widget.onStatusChange,
                                activeTrackColor: Colors.green.shade400,
                                activeThumbColor: Colors.white,
                                inactiveTrackColor: Colors.white.withOpacity(
                                  0.3,
                                ),
                                inactiveThumbColor: Colors.grey.shade200,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Quick Actions
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: _QuickActionCard(
                      icon: Icons.location_on_outlined,
                      title: 'Services',
                      subtitle: 'Coverage areas',
                      accentColor: const Color(0xFF60A5FA),
                      onTap: widget.onManageServices,
                    ),
                  ),
                ],
              ),
            ),

            // Bookings List
            Padding(
              padding: EdgeInsets.only(top: 12.h, bottom: 96.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tabs
                  Padding(
                    padding: EdgeInsets.only(
                      left: 16.w,
                      right: 16.w,
                      bottom: 16.h,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          _TabChip(
                            label: 'Pending (${widget.pendingCount})',
                            isSelected: _jobTab == 'pending',
                            onTap: () => setState(() => _jobTab = 'pending'),
                          ),
                          SizedBox(width: 8.w),
                          _TabChip(
                            label: 'Active (${widget.activeCount})',
                            isSelected: _jobTab == 'active',
                            onTap: () => setState(() => _jobTab = 'active'),
                          ),
                          SizedBox(width: 8.w),
                          _TabChip(
                            label: 'Completed (${widget.completedCount})',
                            isSelected: _jobTab == 'completed',
                            onTap: () => setState(() => _jobTab = 'completed'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Jobs list
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _filteredJobs.isEmpty
                        ? _EmptyJobs(activeTab: _jobTab)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _filteredJobs.asMap().entries.map((
                              entry,
                            ) {
                              final index = entry.key;
                              final job = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: _AnimatedJobCard(
                                  index: index,
                                  job: job,
                                  onSelect: () => widget.onSelectJob(job.id),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.iconBgColor,
    this.iconColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? iconBgColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final bg = iconBgColor ?? Colors.white.withOpacity(0.2);
    final iconC = iconColor ?? Colors.white;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 18.sp, color: iconC),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted row-style tile; matches Performance / Availability strips on hero blue.
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        splashColor: Colors.white.withValues(alpha: 0.14),
        highlightColor: Colors.white.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22.sp, color: Colors.white),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        height: 1.25,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.55),
                size: 22.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatefulWidget {
  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<_TabChip> {
  bool _pressed = false;

  static const Color _tabBlue = Color(0xFF003E93);
  static const Color _white = Color(0xFFFFFFFF);

  static final List<BoxShadow> _shadowMd = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 6,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final bgColor = isSelected
        ? _tabBlue
        : (_pressed ? _SellerHomeColors.gray50 : _white);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: isSelected ? _shadowMd : null,
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? _white : _SellerHomeColors.gray600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}

class _AnimatedJobCard extends StatefulWidget {
  const _AnimatedJobCard({
    required this.index,
    required this.job,
    required this.onSelect,
  });

  final int index;
  final SellerJobItem job;
  final VoidCallback onSelect;

  @override
  State<_AnimatedJobCard> createState() => _AnimatedJobCardState();
}

class _AnimatedJobCardState extends State<_AnimatedJobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(-20, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
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
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: _SellerJobCard(booking: widget.job, onSelect: widget.onSelect),
      ),
    );
  }
}

class _SellerJobCard extends StatelessWidget {
  const _SellerJobCard({required this.booking, required this.onSelect});

  final SellerJobItem booking;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final statusStyle = {
      BookingStatus.pending: (
        _BookingsColors.yellow100,
        _BookingsColors.yellow700,
      ),
      BookingStatus.rejected: (_BookingsColors.red100, _BookingsColors.red700),
      BookingStatus.accepted: (
        _BookingsColors.green100,
        _BookingsColors.green700,
      ),
      BookingStatus.confirmed: (
        _BookingsColors.green100,
        _BookingsColors.green700,
      ),
      BookingStatus.inProgress: (
        _BookingsColors.blue100,
        _BookingsColors.blue700,
      ),
      BookingStatus.completed: (
        _BookingsColors.gray100,
        _BookingsColors.gray700,
      ),
      BookingStatus.cancelled: (_BookingsColors.red100, _BookingsColors.red700),
    };

    final pair =
        statusStyle[booking.status] ??
        (_BookingsColors.gray100, _BookingsColors.gray700);
    final statusBg = pair.$1;
    final statusText = pair.$2;

    final statusLabel = booking.status == BookingStatus.inProgress
        ? 'Active'
        : _cap(_enumName(booking.status));

    final dateStr = _formatScheduleDate(booking.scheduledDate);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: _BookingsColors.gray100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF408AF1).withOpacity(0.1),
                          const Color(0xFF5ca3f5).withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 24.sp,
                      color: const Color(0xFF408AF1),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.customerName,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            color: _BookingsColors.gray700,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          booking.categoryName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: _BookingsColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: statusText,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16.sp,
                    color: _BookingsColors.gray600,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: _BookingsColors.gray600,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Icon(
                    Icons.access_time,
                    size: 16.sp,
                    color: _BookingsColors.gray600,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    booking.scheduledTime,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: _BookingsColors.gray600,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Icon(
                    Icons.location_on_outlined,
                    size: 16.sp,
                    color: _BookingsColors.gray600,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      booking.townName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: _BookingsColors.gray600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: _BookingsColors.gray50,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16.sp,
                        color: _BookingsColors.gray500,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          booking.notes!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: _BookingsColors.gray700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: booking.paidInApp
                      ? _BookingsColors.green100
                      : _BookingsColors.gray50,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      booking.paidInApp
                          ? Icons.verified_user
                          : Icons.info_outline,
                      size: 16.sp,
                      color: booking.paidInApp
                          ? _BookingsColors.green700
                          : _BookingsColors.gray700,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      booking.paidInApp ? 'Paid In-App' : 'Pending Payment',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: booking.paidInApp
                            ? _BookingsColors.green700
                            : _BookingsColors.gray700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyJobs extends StatelessWidget {
  const _EmptyJobs({required this.activeTab});
  final String activeTab;

  @override
  Widget build(BuildContext context) {
    String msg = 'New requests will appear here';
    if (activeTab == 'active') msg = 'Active jobs will appear here';
    if (activeTab == 'completed') msg = 'Completed jobs will appear here';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 48.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, _SellerHomeColors.gray50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _SellerHomeColors.gray200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: _SellerHomeColors.gray100,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 32.sp,
              color: _SellerHomeColors.gray400,
            ),
          ),
          Text(
            'No $activeTab jobs',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: _SellerHomeColors.gray600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            msg,
            style: TextStyle(fontSize: 14.sp, color: _SellerHomeColors.gray500),
          ),
        ],
      ),
    );
  }
}
