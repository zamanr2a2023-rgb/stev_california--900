
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:renizo/features/bookings/data/bookings_mock_data.dart';
// import 'package:renizo/features/seller/models/seller_job_item.dart';
//
// // TSX SellerBookingsScreen.tsx colors
// class _BookingsColors {
//   static const blueBg = Color(0xFF2384F4);
//   static const tabBlue = Color(0xFF003E93);
//   static const gray50 = Color(0xFFF9FAFB);
//   static const gray100 = Color(0xFFF3F4F6);
//   static const gray200 = Color(0xFFE5E7EB);
//   static const gray500 = Color(0xFF6B7280);
//   static const gray600 = Color(0xFF4B5563);
//   static const gray700 = Color(0xFF374151);
//   static const yellow100 = Color(0xFFFEF9C3);
//   static const yellow700 = Color(0xFFA16207);
//   static const green100 = Color(0xFFDCFCE7);
//   static const green700 = Color(0xFF15803D);
//   static const blue100 = Color(0xFFDBEAFE);
//   static const blue700 = Color(0xFF1D4ED8);
//   static const red100 = Color(0xFFFEE2E2);
//   static const red700 = Color(0xFFB91C1C);
//   static const emeraldBorder = Color(0xFF6EE7B7);
//   static const emeraldBg = Color(0xFF064E3B);
//   static const emeraldText = Color(0xFFA7F3D0);
//   static const emeraldMuted = Color(0xFF6EE7B7);
// }
//
// String _formatDate(String scheduledDate) {
//   if (scheduledDate.contains('-')) {
//     final d = DateTime.tryParse(scheduledDate);
//     if (d != null) {
//       const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
//       return '${months[d.month - 1]} ${d.day}';
//     }
//   }
//   return scheduledDate;
// }
//
// /// Seller bookings – full conversion from React SellerBookingsScreen.tsx.
// /// Blue header, filter tabs (All/Pending/Active/Completed/Cancelled), booking cards, warranty box.
// class SellerBookingsScreen extends StatefulWidget {
//   const SellerBookingsScreen({
//     super.key,
//     this.showAppBar = true,
//     this.bookings = const [],
//     this.onSelectBooking,
//   });
//
//   final bool showAppBar;
//   final List<SellerJobItem> bookings;
//   final void Function(String bookingId)? onSelectBooking;
//
//   @override
//   State<SellerBookingsScreen> createState() => _SellerBookingsScreenState();
// }
//
// class _SellerBookingsScreenState extends State<SellerBookingsScreen> {
//   String _activeFilter = 'all'; // all | pending | active | completed | cancelled
//    final ScrollController _filterScroll = ScrollController();
//
//   @override
//   void dispose() {
//     _filterScroll.dispose();
//     super.dispose();
//   }
//
//
//   List<SellerJobItem> get _filteredBookings {
//     if (_activeFilter == 'all') return widget.bookings;
//     if (_activeFilter == 'active') {
//       return widget.bookings.where((b) => b.status == BookingStatus.confirmed || b.status == BookingStatus.inProgress).toList();
//     }
//     if (_activeFilter == 'pending') return widget.bookings.where((b) => b.status == BookingStatus.pending).toList();
//     if (_activeFilter == 'completed') return widget.bookings.where((b) => b.status == BookingStatus.completed).toList();
//     if (_activeFilter == 'cancelled') return widget.bookings.where((b) => b.status == BookingStatus.cancelled).toList();
//     return widget.bookings;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final filters = [
//       _FilterItem(id: 'all', label: 'All', count: widget.bookings.length),
//       _FilterItem(id: 'pending', label: 'Pending', count: widget.bookings.where((b) => b.status == BookingStatus.pending).length),
//       _FilterItem(id: 'active', label: 'Active', count: widget.bookings.where((b) => b.status == BookingStatus.confirmed || b.status == BookingStatus.inProgress).length),
//       _FilterItem(id: 'completed', label: 'Completed', count: widget.bookings.where((b) => b.status == BookingStatus.completed).length),
//       _FilterItem(id: 'cancelled', label: 'Cancelled', count: widget.bookings.where((b) => b.status == BookingStatus.cancelled).length),
//     ];
//
//     final content = Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header – TSX: bg-[#2384F4] px-4 py-6; no top gap (SafeArea top: false)
//         Container(
//           width: double.infinity,
//           color: _BookingsColors.blueBg,
//           padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
//           child: SafeArea(
//             top: false,
//             bottom: false,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('My Bookings', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: Colors.white)),
//                 SizedBox(height: 4.h),
//                 Text('${widget.bookings.length} total bookings', style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.7))),
//               ],
//             ),
//           ),
//         ),
//         // Filter Tabs – TSX: px-4 py-3 bg-[#2384F4] border-b border-gray-100 overflow-x-auto; flex gap-2; button px-4 py-2 rounded-xl text-sm font-medium; selected bg-[#003E93] text-white, unselected bg-gray-100 text-gray-600 hover:bg-gray-200
//       Container(
//   width: double.infinity,
//   padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
//   color: _BookingsColors.blueBg,
//   child: ScrollConfiguration(
//     behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false), // ✅ hide grey bar
//     child: SingleChildScrollView(
//       controller: _filterScroll,
//       scrollDirection: Axis.horizontal,
//       physics: const BouncingScrollPhysics(),
//       child: Row(
//         children: filters.asMap().entries.map((entry) {
//           final i = entry.key;
//           final f = entry.value;
//           return Padding(
//             padding: EdgeInsets.only(right: i < filters.length - 1 ? 10.w : 0),
//             child: _FilterPill(
//               label: f.label,
//               count: f.count,
//               selected: _activeFilter == f.id,
//               onTap: () => setState(() => _activeFilter = f.id),
//             ),
//           );
//         }).toList(),
//       ),
//     ),
//   ),
// ),
//
//         // List + Warranty or Empty – TSX: flex-1 overflow-y-auto px-4 py-4 space-y-3, bg blue
//         Expanded(
//           child: Container(
//             color: _BookingsColors.blueBg,
//             child: _filteredBookings.isEmpty
//                 ? _EmptyBookings(activeFilter: _activeFilter)
//                 : ListView(
//                     padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
//                     children: [
//                       ..._filteredBookings.map((b) => Padding(
//                             padding: EdgeInsets.only(bottom: 12.h),
//                             child: _BookingCard(booking: b, onSelect: () => widget.onSelectBooking?.call(b.id)),
//                           )),
//                       SizedBox(height: 16.h),
//                       _WarrantyBox(),
//                     ],
//                   ),
//           ),
//         ),
//       ],
//     );
//
//     if (!widget.showAppBar) return content;
//     return Scaffold(
//       backgroundColor: _BookingsColors.blueBg,
//       appBar: AppBar(
//         title: Text('Bookings', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white)),
//         backgroundColor: _BookingsColors.blueBg,
//         elevation: 0,
//       ),
//       body: content,
//     );
//   }
// }
//
// class _FilterItem {
//   final String id;
//   final String label;
//   final int count;
//   _FilterItem({required this.id, required this.label, required this.count});
// }
//
// /// TSX: button px-4 py-2 rounded-xl text-sm font-medium whitespace-nowrap; selected bg-[#003E93] text-white, unselected bg-gray-100 text-gray-600 hover:bg-gray-200; count ml-1.5, selected text-white/80 else text-gray-500
// class _FilterChip extends StatefulWidget {
//   const _FilterChip({required this.label, required this.count, required this.isSelected, required this.onTap});
//
//   final String label;
//   final int count;
//   final bool isSelected;
//   final VoidCallback onTap;
//
//   @override
//   State<_FilterChip> createState() => _FilterChipState();
// }
//
// class _FilterChipState extends State<_FilterChip> {
//   bool _pressed = false;
//
//   @override
//   Widget build(BuildContext context) {
//     final isSelected = widget.isSelected;
//     final bgColor = isSelected ? _BookingsColors.tabBlue : (_pressed ? _BookingsColors.gray200 : _BookingsColors.gray100);
//     return GestureDetector(
//       onTap: widget.onTap,
//       onTapDown: (_) => setState(() => _pressed = true),
//       onTapUp: (_) => setState(() => _pressed = false),
//       onTapCancel: () => setState(() => _pressed = false),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 150),
//         padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//         decoration: BoxDecoration(
//           color: bgColor,
//           borderRadius: BorderRadius.circular(12.r),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(widget.label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : _BookingsColors.gray600)),
//             if (widget.count > 0) ...[
//               SizedBox(width: 6.w),
//               Text('(${widget.count})', style: TextStyle(fontSize: 14.sp, color: isSelected ? Colors.white.withOpacity(0.8) : _BookingsColors.gray500)),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// /// TSX BookingCard: white rounded-2xl p-4, avatar, name, status, date/time/location, notes, payment row.
// class _BookingCard extends StatelessWidget {
//   const _BookingCard({required this.booking, required this.onSelect});
//
//   final SellerJobItem booking;
//   final VoidCallback onSelect;
//
//   @override
//   Widget build(BuildContext context) {
//     final statusStyle = {
//       BookingStatus.pending: (_BookingsColors.yellow100, _BookingsColors.yellow700),
//       BookingStatus.confirmed: (_BookingsColors.green100, _BookingsColors.green700),
//       BookingStatus.inProgress: (_BookingsColors.blue100, _BookingsColors.blue700),
//       BookingStatus.completed: (_BookingsColors.gray100, _BookingsColors.gray700),
//       BookingStatus.cancelled: (_BookingsColors.red100, _BookingsColors.red700),
//     };
//     final pair = statusStyle[booking.status] ?? (_BookingsColors.gray100, _BookingsColors.gray700);
//     final statusBg = pair.$1;
//     final statusText = pair.$2;
//     final statusLabel = booking.status == BookingStatus.inProgress ? 'Active' : booking.status.name[0].toUpperCase() + booking.status.name.substring(1);
//     final dateStr = _formatDate(booking.scheduledDate);
//
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(16.r),
//       child: InkWell(
//         onTap: onSelect,
//         borderRadius: BorderRadius.circular(16.r),
//         child: Container(
//           padding: EdgeInsets.all(16.w),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16.r),
//             border: Border.all(color: _BookingsColors.gray100),
//             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 1))],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     width: 48.w,
//                     height: 48.w,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(colors: [const Color(0xFF408AF1).withOpacity(0.1), const Color(0xFF5ca3f5).withOpacity(0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
//                       borderRadius: BorderRadius.circular(12.r),
//                     ),
//                     child: Icon(Icons.person_outline, size: 24.sp, color: const Color(0xFF408AF1)),
//                   ),
//                   SizedBox(width: 12.w),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(booking.customerName, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: _BookingsColors.gray700)),
//                         SizedBox(height: 2.h),
//                         Text(booking.categoryName, style: TextStyle(fontSize: 14.sp, color: _BookingsColors.gray500)),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
//                     decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20.r)),
//                     child: Text(statusLabel, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: statusText)),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 12.h),
//               Row(
//                 children: [
//                   Icon(Icons.calendar_today_outlined, size: 16.sp, color: _BookingsColors.gray600),
//                   SizedBox(width: 4.w),
//                   Text(dateStr, style: TextStyle(fontSize: 14.sp, color: _BookingsColors.gray600)),
//                   SizedBox(width: 16.w),
//                   Icon(Icons.access_time, size: 16.sp, color: _BookingsColors.gray600),
//                   SizedBox(width: 4.w),
//                   Text(booking.scheduledTime, style: TextStyle(fontSize: 14.sp, color: _BookingsColors.gray600)),
//                   SizedBox(width: 16.w),
//                   Icon(Icons.location_on_outlined, size: 16.sp, color: _BookingsColors.gray600),
//                   SizedBox(width: 4.w),
//                   Text(booking.townName, style: TextStyle(fontSize: 14.sp, color: _BookingsColors.gray600)),
//                 ],
//               ),
//               if (booking.notes != null && booking.notes!.isNotEmpty) ...[
//                 SizedBox(height: 12.h),
//                 Container(
//                   padding: EdgeInsets.all(12.w),
//                   decoration: BoxDecoration(color: _BookingsColors.gray50, borderRadius: BorderRadius.circular(12.r)),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.description_outlined, size: 16.sp, color: _BookingsColors.gray500),
//                       SizedBox(width: 8.w),
//                       Expanded(child: Text(booking.notes!, style: TextStyle(fontSize: 14.sp, color: _BookingsColors.gray700), maxLines: 2, overflow: TextOverflow.ellipsis)),
//                     ],
//                   ),
//                 ),
//               ],
//               SizedBox(height: 12.h),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
//                 decoration: BoxDecoration(
//                   color: booking.paidInApp ? _BookingsColors.green100 : _BookingsColors.gray50,
//                   borderRadius: BorderRadius.circular(12.r),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(booking.paidInApp ? Icons.verified_user : Icons.info_outline, size: 16.sp, color: booking.paidInApp ? _BookingsColors.green700 : _BookingsColors.gray700),
//                     SizedBox(width: 8.w),
//                     Text(booking.paidInApp ? 'Paid In-App' : 'Pending Payment', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: booking.paidInApp ? _BookingsColors.green700 : _BookingsColors.gray700)),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// /// TSX: Warranty Info for Providers – emerald box.
// class _WarrantyBox extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(16.w),
//       decoration: BoxDecoration(
//         color: _BookingsColors.emeraldBg.withOpacity(0.4),
//         borderRadius: BorderRadius.circular(16.r),
//         border: Border.all(color: _BookingsColors.emeraldBorder.withOpacity(0.3)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(Icons.verified_user, size: 20.sp, color: _BookingsColors.emeraldMuted),
//           SizedBox(width: 12.w),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('30-Day Warranty Reminder', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: _BookingsColors.emeraldText)),
//                 SizedBox(height: 4.h),
//                 Text(
//                   'All services paid through Renizo include a 30-day workmanship warranty. Be prepared to address any quality issues reported within 30 days of service completion at no additional charge to the customer.',
//                   style: TextStyle(fontSize: 12.sp, color: _BookingsColors.emeraldText.withOpacity(0.9), height: 1.4),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /// TSX: empty state – calendar icon, "No {filter} bookings", subtitle.
// class _EmptyBookings extends StatelessWidget {
//   const _EmptyBookings({required this.activeFilter});
//
//   final String activeFilter;
//
//   @override
//   Widget build(BuildContext context) {
//     String msg = 'Your bookings will appear here';
//     if (activeFilter == 'pending') msg = 'New booking requests will appear here';
//     if (activeFilter == 'active') msg = 'Active jobs will appear here';
//     if (activeFilter == 'completed') msg = 'Completed jobs will appear here';
//     if (activeFilter == 'cancelled') msg = 'Cancelled bookings will appear here';
//
//     final filterLabel = activeFilter == 'all' ? '' : activeFilter;
//     return Container(
//       width: double.infinity,
//       height: double.infinity,
//       color: _BookingsColors.blueBg,
//       padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 24.w),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 64.w,
//             height: 64.w,
//             margin: EdgeInsets.only(bottom: 16.h),
//             decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16.r)),
//             child: Icon(Icons.calendar_today_outlined, size: 32.sp, color: Colors.white),
//           ),
//           Text('No ${filterLabel.isNotEmpty ? "$filterLabel " : ""}bookings', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.white)),
//           SizedBox(height: 4.h),
//           Text(msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.7))),
//         ],
//       ),
//     );
//   }
// }
// class _FilterPill extends StatelessWidget {
//   const _FilterPill({
//     required this.label,
//     required this.count,
//     required this.selected,
//     required this.onTap,
//   });
//
//   final String label;
//   final int count;
//   final bool selected;
//   final VoidCallback onTap;
//
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: selected ? _BookingsColors.tabBlue : Colors.white,
//       borderRadius: BorderRadius.circular(999.r),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(999.r),
//         child: Container(
//           height: 34.h,
//           padding: EdgeInsets.symmetric(horizontal: 14.w),
//           alignment: Alignment.center,
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 12.sp,
//                   fontWeight: FontWeight.w600,
//                   color: selected ? Colors.white : _BookingsColors.tabBlue,
//                 ),
//               ),
//               if (count > 0) ...[
//                 SizedBox(width: 6.w),
//                 Text(
//                   '($count)',
//                   style: TextStyle(
//                     fontSize: 12.sp,
//                     fontWeight: FontWeight.w600,
//                     color: selected ? Colors.white.withOpacity(0.85) : _BookingsColors.tabBlue,
//                   ),
//                 ),
//               ],
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
import 'package:renizo/features/seller/models/seller_job_item.dart';
import 'package:renizo/core/widgets/app_logo_button.dart';

import '../../bookings/data/bookings_mock_data.dart';
import '../data/bookings_riverpod.dart';
import '../models/seller_bookings.dart';

// TSX SellerBookingsScreen.tsx colors
class _BookingsColors {
  static const blueBg = Color(0xFF2384F4);
  static const tabBlue = Color(0xFF003E93);
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
  static const emeraldBorder = Color(0xFF6EE7B7);
  static const emeraldBg = Color(0xFF064E3B);
  static const emeraldText = Color(0xFFA7F3D0);
  static const emeraldMuted = Color(0xFF6EE7B7);
}

String _formatDate(String scheduledDate) {
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

/// ✅ Seller bookings screen (API + Riverpod Integrated)
class SellerBookingsScreen extends ConsumerStatefulWidget {
  const SellerBookingsScreen({
    super.key,
    this.showAppBar = true,
    this.onSelectBooking,
    this.onOpenCabinetRequests,
    this.bookings = const [],
  });

  final bool showAppBar;
  final void Function(String bookingId)? onSelectBooking;
  /// Opens provider cabinet queue (`GET /cabinet-requests`).
  final VoidCallback? onOpenCabinetRequests;
  /// Legacy; list uses [providerMyBookingsProvider] when empty.
  final List<SellerJobItem> bookings;

  @override
  ConsumerState<SellerBookingsScreen> createState() =>
      _SellerBookingsScreenState();
}

class _SellerBookingsScreenState extends ConsumerState<SellerBookingsScreen> {
  String _activeFilter =
      'all'; // all | pending | active | completed | cancelled
  final ScrollController _filterScroll = ScrollController();

  @override
  void dispose() {
    _filterScroll.dispose();
    super.dispose();
  }

  BookingStatus _mapStatus(String raw) {
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
      status: _mapStatus(item.status),
    );
  }

  List<SellerJobItem> _filteredBookings(List<SellerJobItem> bookings) {
    if (_activeFilter == 'all') return bookings;
    if (_activeFilter == 'active') {
      return bookings
          .where(
            (b) =>
                b.status == BookingStatus.confirmed ||
                b.status == BookingStatus.inProgress,
          )
          .toList();
    }
    if (_activeFilter == 'pending') {
      return bookings.where((b) => b.status == BookingStatus.pending).toList();
    }
    if (_activeFilter == 'completed') {
      return bookings
          .where((b) => b.status == BookingStatus.completed)
          .toList();
    }
    if (_activeFilter == 'cancelled') {
      return bookings
          .where((b) => b.status == BookingStatus.cancelled)
          .toList();
    }
    return bookings;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(providerMyBookingsProvider);

    return async.when(
      loading: () => Scaffold(
        backgroundColor: _BookingsColors.blueBg,
        appBar: widget.showAppBar
            ? AppBar(
                title: Text(
                  'Bookings',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: _BookingsColors.blueBg,
                elevation: 0,
                actions: [
                  Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: AppLogoButton(size: 34),
                  ),
                ],
              )
            : null,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),

      error: (e, _) => Scaffold(
        backgroundColor: _BookingsColors.blueBg,
        appBar: widget.showAppBar
            ? AppBar(
                title: Text(
                  'Bookings',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: _BookingsColors.blueBg,
                elevation: 0,
                actions: [
                  Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: AppLogoButton(size: 34),
                  ),
                ],
              )
            : null,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load bookings',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
                SizedBox(height: 8.h),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 10.h),
                TextButton(
                  onPressed: () => ref.invalidate(providerMyBookingsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),

      data: (data) {
        final bookings = data.items.map(_toSellerJobItem).toList();
        final filtered = _filteredBookings(bookings);

        final filters = [
          _FilterItem(id: 'all', label: 'All', count: data.counts.all),
          _FilterItem(
            id: 'pending',
            label: 'Pending',
            count: data.counts.pending,
          ),
          _FilterItem(id: 'active', label: 'Active', count: data.counts.active),
          _FilterItem(
            id: 'completed',
            label: 'Completed',
            count: data.counts.completed,
          ),
          _FilterItem(
            id: 'cancelled',
            label: 'Cancelled',
            count: data.counts.cancelled,
          ),
        ];

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              color: _BookingsColors.blueBg,
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Bookings',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${data.total} total bookings',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (widget.onOpenCabinetRequests != null)
              Container(
                width: double.infinity,
                color: _BookingsColors.blueBg,
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14.r),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onOpenCabinetRequests,
                    borderRadius: BorderRadius.circular(14.r),
                    splashColor: _BookingsColors.tabBlue.withValues(alpha: 0.08),
                    highlightColor: _BookingsColors.gray100,
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: _BookingsColors.gray100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44.w,
                              height: 44.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFF408AF1)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.kitchen_outlined,
                                color: _BookingsColors.tabBlue,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Kitchen cabinet requests',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: _BookingsColors.gray700,
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Text(
                                    'Quotes, site visits & workflow',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      height: 1.25,
                                      color: _BookingsColors.gray600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: _BookingsColors.gray500,
                              size: 28.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Filter pills
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
              color: _BookingsColors.blueBg,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  controller: _filterScroll,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: filters.asMap().entries.map((entry) {
                      final i = entry.key;
                      final f = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          right: i < filters.length - 1 ? 10.w : 0,
                        ),
                        child: _FilterPill(
                          label: f.label,
                          count: f.count,
                          selected: _activeFilter == f.id,
                          onTap: () => setState(() => _activeFilter = f.id),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // List / Empty
            Expanded(
              child: Container(
                color: _BookingsColors.blueBg,
                child: filtered.isEmpty
                    ? _EmptyBookings(activeFilter: _activeFilter)
                    : ListView(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                        children: [
                          ...filtered.map(
                            (b) => Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: _BookingCard(
                                booking: b,
                                onSelect: () =>
                                    widget.onSelectBooking?.call(b.id),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          _WarrantyBox(),
                        ],
                      ),
              ),
            ),
          ],
        );

        if (!widget.showAppBar) return content;

        return Scaffold(
          backgroundColor: _BookingsColors.blueBg,
          appBar: AppBar(
            title: Text(
              'Bookings',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: _BookingsColors.blueBg,
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
      },
    );
  }
}

class _FilterItem {
  final String id;
  final String label;
  final int count;
  _FilterItem({required this.id, required this.label, required this.count});
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onSelect});

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

    final dateStr = _formatDate(booking.scheduledDate);

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
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: statusText.withOpacity(0.22)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: _BookingsColors.gray500,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: _BookingsColors.gray50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: _BookingsColors.gray100),
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
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

class _WarrantyBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _BookingsColors.emeraldBg.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _BookingsColors.emeraldBorder.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user,
            size: 20.sp,
            color: _BookingsColors.emeraldMuted,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '30-Day Warranty Reminder',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _BookingsColors.emeraldText,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'All services paid through Renizo include a 30-day workmanship warranty. Be prepared to address any quality issues reported within 30 days of service completion at no additional charge to the customer.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _BookingsColors.emeraldText.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings({required this.activeFilter});
  final String activeFilter;

  @override
  Widget build(BuildContext context) {
    String msg = 'Your bookings will appear here';
    if (activeFilter == 'pending') {
      msg = 'New booking requests will appear here';
    }
    if (activeFilter == 'active') msg = 'Active jobs will appear here';
    if (activeFilter == 'completed') msg = 'Completed jobs will appear here';
    if (activeFilter == 'cancelled') {
      msg = 'Cancelled bookings will appear here';
    }

    final filterLabel = activeFilter == 'all' ? '' : activeFilter;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _BookingsColors.blueBg,
      padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 32.sp,
              color: Colors.white,
            ),
          ),
          Text(
            'No ${filterLabel.isNotEmpty ? "$filterLabel " : ""}bookings',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999.r),
        splashColor: Colors.white.withValues(alpha: 0.18),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: Ink(
          height: 36.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: selected
                ? _BookingsColors.tabBlue
                : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999.r),
            border: Border.all(
              color: selected
                  ? _BookingsColors.tabBlue
                  : Colors.white.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 5.w),
                Text(
                  '($count)',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
