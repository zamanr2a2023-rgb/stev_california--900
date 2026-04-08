/// Display model for booking list – mirrors React BookingsScreen transformed booking.
class BookingDisplayItem {
  const BookingDisplayItem({
    required this.id,
    required this.providerName,
    required this.providerAvatar,
    required this.date,
    required this.time,
    required this.status,
    required this.categoryName,
    this.scheduledDateTime,
  });

  final String id;
  final String providerName;
  final String providerAvatar;
  final String date;
  final String time;
  final BookingStatus status;
  final String categoryName;
  /// Optional; used by MessagesScreen for sorting and time-ago.
  final DateTime? scheduledDateTime;
}

/// API status values: pending_payment, rejected, accepted, paid, in_progress, completed, cancelled.
enum BookingStatus {
  pending,       // pending_payment – booking created, not paid yet
  rejected,      // provider rejected
  accepted,      // provider accepted, waiting payment
  confirmed,     // paid – ready to start
  inProgress,   // in_progress
  completed,
  cancelled,
}

/// Full booking details for BookingDetailsScreen – mirrors React getBookingById + related data.
class BookingDetailsModel {
  const BookingDetailsModel({
    required this.id,
    required this.providerName,
    required this.providerAvatar,
    required this.categoryName,
    required this.townName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.address,
    this.notes,
    required this.status,
    required this.paymentStatus,
    this.totalAmount,
    this.renizoFeeAmount,
    this.renizoFeePercent,
    this.currency,
    this.basePriceAmount,
    this.addonsTotalAmount,
    this.providerPayoutAmount,
    this.basePriceCents,
    this.addonsTotalCents,
    this.totalCents,
    this.renizoFeeCents,
    this.providerPayoutCents,
  });

  final String id;
  final String providerName;
  final String providerAvatar;
  final String categoryName;
  final String townName;
  final String scheduledDate; // "2026-01-17"
  final String scheduledTime; // "10:00"
  final String address;
  final String? notes;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final double? totalAmount;
  final double? renizoFeeAmount;
  final int? renizoFeePercent;
  /// From API price.currency (e.g. "CAD").
  final String? currency;
  /// From API price.basePriceCents (in dollars for display).
  final double? basePriceAmount;
  /// From API price.addonsTotalCents (in dollars for display).
  final double? addonsTotalAmount;
  /// From API price.providerPayoutCents (in dollars for display).
  final double? providerPayoutAmount;
  /// Raw API price in cents – use so payment screen shows exact API data.
  final int? basePriceCents;
  final int? addonsTotalCents;
  final int? totalCents;
  final int? renizoFeeCents;
  final int? providerPayoutCents;
}

extension BookingDetailsRenizoFee on BookingDetailsModel {
  /// Dollar amount: API fee when present, else [renizoFeePercent]% of total (default 10%).
  double get renizoFeeDisplayAmount {
    if (renizoFeeAmount != null && renizoFeeAmount! > 0) return renizoFeeAmount!;
    if (renizoFeeCents != null && renizoFeeCents! > 0) return renizoFeeCents! / 100.0;
    final total = totalAmount ?? basePriceAmount ?? 0;
    return total * ((renizoFeePercent ?? 10) / 100.0);
  }

  int get renizoFeeDisplayPercent => renizoFeePercent ?? 10;
}

enum PaymentStatus { unpaid, paidInApp, paidOutside }

/// Mock load: returns display bookings for customer (mirrors AppService.getBookingsByCustomer + transform).
/// Uses customer1; one sample booking so list is non-empty by default.
Future<List<BookingDisplayItem>> loadBookingsForCustomer(String customerId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  // Mock: one booking for customer1 (mirrors React mock – booking1 → provider1, cat1 Residential Cleaning).
  if (customerId != 'customer1') return [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  String dateStr(DateTime d) {
    if (d == today) return 'Today';
    if (d == tomorrow) return 'Tomorrow';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
  final t1 = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);
  final t2 = DateTime(today.year, today.month, today.day, 15, 0);
  return [
    BookingDisplayItem(
      id: 'booking1',
      providerName: 'Mike Johnson',
      providerAvatar: 'https://i.pravatar.cc/300?u=mike-johnson',
      date: dateStr(tomorrow),
      time: '10:00',
      status: BookingStatus.pending,
      categoryName: 'Residential Cleaning',
      scheduledDateTime: t1,
    ),
    BookingDisplayItem(
      id: 'booking2',
      providerName: 'Sparkle Home Cleaning',
      providerAvatar: 'https://i.pravatar.cc/300?u=sparkle-cleaning',
      date: dateStr(today),
      time: '15:00',
      status: BookingStatus.confirmed,
      categoryName: 'Residential Cleaning',
      scheduledDateTime: t2,
    ),
  ];
}

/// Mock getBookingById – returns full details for BookingDetailsScreen (mirrors AppService.getBookingById + related).
Future<BookingDetailsModel?> getBookingById(String bookingId) async {
  await Future.delayed(const Duration(milliseconds: 400));
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
  switch (bookingId) {
    case 'booking1':
      return BookingDetailsModel(
        id: 'booking1',
        providerName: 'Mike Johnson',
        providerAvatar: 'https://i.pravatar.cc/300?u=mike-johnson',
        categoryName: 'Residential Cleaning',
        townName: 'Terrace',
        scheduledDate: tomorrowStr,
        scheduledTime: '10:00',
        address: '456 Oak Avenue, Terrace, BC',
        notes: 'Need regular house cleaning with window cleaning',
        status: BookingStatus.pending,
        paymentStatus: PaymentStatus.unpaid,
        totalAmount: 150,
        basePriceCents: null,
        addonsTotalCents: null,
        totalCents: null,
        renizoFeeCents: null,
        providerPayoutCents: null,
      );
    case 'booking2':
      return BookingDetailsModel(
        id: 'booking2',
        providerName: 'Sparkle Home Cleaning',
        providerAvatar: 'https://i.pravatar.cc/300?u=sparkle-cleaning',
        categoryName: 'Residential Cleaning',
        townName: 'Terrace',
        scheduledDate: todayStr,
        scheduledTime: '15:00',
        address: '123 Main St, Terrace, BC',
        notes: null,
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.paidInApp,
        totalAmount: 145,
        basePriceCents: null,
        addonsTotalCents: null,
        totalCents: null,
        renizoFeeCents: null,
        providerPayoutCents: null,
      );
    default:
      return null;
  }
}
