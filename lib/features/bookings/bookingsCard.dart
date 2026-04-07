import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/features/bookings/data/bookings_mock_data.dart';

class BookingCard extends StatefulWidget {
  const BookingCard({super.key, required this.booking, required this.onSelect});

  final BookingDisplayItem booking;
  final VoidCallback onSelect;

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  bool _imageError = false;

  static const Color _gradientStart = Color(0xFF408AF1);
  static const Color _gradientEnd = Color(0xFF5ca3f5);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (Color bg, Color text) _statusColors(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309));
      case BookingStatus.rejected:
        return (const Color(0xFFFEE2E2), const Color(0xFFB91C1C));
      case BookingStatus.accepted:
        return (const Color(0xFFDCFCE7), const Color(0xFF15803D));
      case BookingStatus.confirmed:
        return (const Color(0xFFDCFCE7), const Color(0xFF15803D));
      case BookingStatus.inProgress:
        return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8));
      case BookingStatus.completed:
        return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8));
      case BookingStatus.cancelled:
        return (const Color(0xFFF3F4F6), const Color(0xFF374151));
    }
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final initial = b.providerName.isNotEmpty
        ? b.providerName[0].toUpperCase()
        : '?';
    final (statusBg, statusText) = _statusColors(b.status);

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.08),
          child: InkWell(
            onTap: widget.onSelect,
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_gradientStart, _gradientEnd],
                            ),
                          ),
                          child: b.providerAvatar.isNotEmpty && !_imageError
                              ? CachedNetworkImage(
                                  imageUrl: b.providerAvatar,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Center(
                                    child: Text(
                                      initial,
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (mounted) {
                                            setState(() => _imageError = true);
                                          }
                                        });
                                    return Center(
                                      child: Text(
                                        initial,
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                    initial,
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.providerName,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              b.categoryName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                        child: Text(
                          _statusLabel(b.status),
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
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        b.date,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Icon(
                        Icons.access_time,
                        size: 16.sp,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        b.time,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
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
