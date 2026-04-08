import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:renizo/core/constants/api_control/provider_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/core/widgets/app_logo_button.dart';
import 'package:renizo/features/auth/screens/login_screen.dart';
import 'package:renizo/features/bookings/data/bookings_mock_data.dart';
import 'package:renizo/features/seller/screens/seller_booking_details_screen.dart';
import 'package:renizo/features/messages/data/chat_api_service.dart';
import 'package:renizo/features/messages/screens/chat_screen.dart';
import 'package:renizo/features/notifications/screens/notifications_screen.dart';
import 'package:renizo/features/seller/logic/seller_home_logic.dart';
import 'package:renizo/features/seller/models/seller_bookings.dart';
import 'package:renizo/features/seller/screens/seller_bookings_screen.dart';
import 'package:renizo/features/seller/screens/seller_earnings_screen.dart';
import 'package:renizo/features/seller/screens/seller_home_screen.dart';
import 'package:renizo/features/messages/screens/messages_screen.dart';
import 'package:renizo/features/seller/data/bookings_riverpod.dart';
import 'package:renizo/features/seller/models/seller_job_item.dart';
import 'package:renizo/features/seller/screens/seller_profile_screen.dart';
import 'package:renizo/features/cabinet/screens/provider_cabinet_list_screen.dart';
import 'package:renizo/features/cabinet/screens/provider_cabinet_detail_screen.dart';
import 'package:renizo/features/seller/widgets/seller_bottom_nav_bar.dart';
import 'package:renizo/features/town/logic/towns_logic.dart';
import 'package:renizo/core/models/town.dart';

final catalogServicesProvider =
    FutureProvider<List<_CatalogService>>((ref) async {
  final client = ref.watch(httpClientProvider);
  final token = await AuthLocalStorage.getToken();

  final res = await client.get(
    Uri.parse(ProviderApi.catalogServices),
    headers: {
      'Content-Type': 'application/json',
      if (token != null && token.toString().isNotEmpty)
        'Authorization': 'Bearer $token',
    },
  );

  dynamic decoded;
  try {
    decoded = jsonDecode(res.body);
  } catch (_) {
    throw Exception('Invalid response from server');
  }

  if (res.statusCode >= 400) {
    final msg =
        (decoded is Map<String, dynamic>) ? decoded['message']?.toString() : null;
    throw Exception(msg ?? 'Failed to load services');
  }

  if (decoded is! Map<String, dynamic>) return <_CatalogService>[];
  final data = decoded['data'];
  if (data is! List) return <_CatalogService>[];

  return data
      .whereType<Map>()
      .map((e) => _CatalogService.fromJson(e.cast<String, dynamic>()))
      .where((service) => service.isActive)
      .toList();
});

/// Provider app – full conversion from React ProviderApp.tsx.
/// Header (logo + notifications), body (home/bookings/messages/earnings/profile or overlay), bottom nav.
class ProviderAppScreen extends ConsumerStatefulWidget {
  const ProviderAppScreen({super.key});

  static const String routeName = '/seller';

  @override
  ConsumerState<ProviderAppScreen> createState() => _ProviderAppScreenState();
}

class _ProviderAppScreenState extends ConsumerState<ProviderAppScreen> {
  int _activeTab = 0; // 0=home, 1=bookings, 2=messages, 3=earnings, 4=profile
  String? _currentOverlay; // 'availability' | 'services' | 'pricing' | 'booking-details' | 'chat' | 'notifications' | 'cabinet-requests' | 'cabinet-detail'
  String? _selectedBookingId;
  String? _selectedCabinetRequestId;
  String? _selectedChatId;
  String? _selectedThreadId; // from POST /chat/threads response _id
  final ChatApiService _chatApi = ChatApiService();

  bool _providerStatusActive = true; // 'active' | 'offline'
  List<SellerJobItem> _upcomingJobs = [];
  List<SellerJobItem> _pendingRequests = [];
  List<SellerJobItem> _allBookings = [];

  static const Color _headerBlue = Color(0xFF0060CF);
  static const Color _bgBlue = Color(0xFF2384F4);

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  /// Refreshes [providerMyBookingsProvider]. Home/bookings UIs read bookings from that API;
  /// legacy lists stay empty (nav badge uses API counts in [build]).
  Future<void> _loadBookings() async {
    ref.invalidate(providerMyBookingsProvider);
    if (!mounted) return;
    setState(() {
      _pendingRequests = [];
      _upcomingJobs = [];
      _allBookings = [];
    });
  }

  void _showTab(int index) {
    setState(() {
      _activeTab = index;
      _currentOverlay = null;
    });
  }

  void _showOverlay(String overlay) {
    setState(() => _currentOverlay = overlay);
  }

  void _hideOverlay() {
    setState(() {
      _currentOverlay = null;
      _selectedBookingId = null;
      _selectedChatId = null;
      _selectedThreadId = null;
      _selectedCabinetRequestId = null;
    });
  }

  void _onSelectJob(String jobId) {
    setState(() {
      _selectedBookingId = jobId;
      _currentOverlay = 'booking-details';
    });
  }

  Future<void> _onOpenChat(String bookingId, {String? partnerName}) async {
    final threadId = await _chatApi.getOrCreateThread(bookingId);
    if (!mounted) return;
    setState(() {
      _selectedThreadId = threadId;
      _selectedChatId = bookingId;
      _currentOverlay = 'chat';
    });
  }

  void _onBackFromBookingDetails() {
    setState(() {
      _currentOverlay = null;
      _selectedBookingId = null;
    });
    _loadBookings();
  }

  void _onBackFromChat() {
    setState(() {
      _currentOverlay = null;
      _selectedChatId = null;
      _selectedThreadId = null;
    });
  }

  void _onUpdateBooking(String bookingId, BookingStatus status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking ${status.name}')),
    );
    _loadBookings();
    _onBackFromBookingDetails();
  }

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

  BookingDetailsModel? _buildBookingDetailsModel(
    ProviderBookingItem item,
  ) {
    return BookingDetailsModel(
      id: item.id,
      providerName: item.customerName,
      providerAvatar: '',
      categoryName: item.categoryName,
      townName: item.townName,
      scheduledDate: item.scheduledDate,
      scheduledTime: item.scheduledTime,
      address: item.townName,
      notes: item.notes.isEmpty ? null : item.notes,
      status: _mapProviderBookingStatus(item.status),
      paymentStatus:
          item.paidInApp ? PaymentStatus.paidInApp : PaymentStatus.unpaid,
      totalAmount: null,
      basePriceCents: null,
      addonsTotalCents: null,
      totalCents: null,
      renizoFeeCents: null,
      providerPayoutCents: null,
    );
  }

  void _onStatusChange(bool active) async {
    setState(() => _providerStatusActive = active);

    try {
      final client = ref.read(httpClientProvider);
      final token = await AuthLocalStorage.getToken();

      final res = await client.patch(
        Uri.parse(ProviderApi.acceptingJobs),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.toString().isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'acceptingJobs': active}),
      );

      dynamic decoded;
      try {
        decoded = jsonDecode(res.body);
      } catch (_) {
        decoded = null;
      }

      if (res.statusCode >= 400) {
        final msg = (decoded is Map<String, dynamic>)
            ? decoded['message']?.toString()
            : null;
        throw Exception(msg ?? 'Failed to update status');
      }

      final confirmed = (decoded is Map<String, dynamic>)
          ? (decoded['data']?['acceptingJobs'])
          : null;
      final nextValue = confirmed is bool ? confirmed : active;

      if (!mounted) return;
      setState(() => _providerStatusActive = nextValue);
      ref.read(providerAvailabilityOverrideProvider.notifier).state = nextValue;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nextValue ? 'Available' : 'Offline')),
      );
    } catch (e) {
      if (!mounted) return;
      final revert = !active;
      setState(() => _providerStatusActive = revert);
      ref.read(providerAvailabilityOverrideProvider.notifier).state = revert;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _onLogout() async {
    await AuthLocalStorage.clearSession();
    if (!mounted) return;
    context.go(LoginScreen.routeName);
  }

  bool get _showBottomNav =>
      _currentOverlay == null ||
      ![
        'availability',
        'services',
        'pricing',
        'booking-details',
        'chat',
        'notifications',
        'cabinet-requests',
        'cabinet-detail',
      ].contains(_currentOverlay);

  @override
  Widget build(BuildContext context) {
    final showHeader = _currentOverlay != 'notifications';
    final pendingNavBadge = ref.watch(providerMyBookingsProvider).when(
          data: (d) => d.counts.pending,
          loading: () => 0,
          error: (_, __) => 0,
        );
    return Scaffold(
      backgroundColor: _bgBlue,
      body: Column(
        children: [
          if (showHeader) _buildHeader(),
          Expanded(
            child: _currentOverlay != null ? _buildOverlayContent() : _buildTabContent(),
          ),
          if (_showBottomNav) SellerBottomNavBar(
                currentIndex: _activeTab,
                onTabTap: _showTab,
                pendingCount: pendingNavBadge,
              ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 12.h),
      decoration: BoxDecoration(
        color: _headerBlue,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            AppLogoButton(size: 48),
            const Spacer(),
            IconButton(
              onPressed: () => _showOverlay('notifications'),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_none, size: 24.sp, color: Colors.white),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return SellerHomeScreen(
          upcomingJobs: _upcomingJobs,
          pendingRequests: _pendingRequests,
          providerStatusActive: _providerStatusActive,
          onSelectJob: _onSelectJob,
          onManageServices: () => _showOverlay('services'),
          onManagePricing: () => _showOverlay('pricing'),
          onStatusChange: _onStatusChange,
        );
      case 1:
        return Container(
          color: _bgBlue,
          child: SellerBookingsScreen(
            showAppBar: false,
            bookings: _allBookings,
            onSelectBooking: _onSelectJob,
            onOpenCabinetRequests: () => setState(() {
              _currentOverlay = 'cabinet-requests';
              _selectedCabinetRequestId = null;
            }),
          ),
        );
      case 2:
        return Container(
          color: const Color(0xFFF9FAFB),
          child: MessagesScreen(
            userRole: 'provider',
            showAppBar: false,
            sellerBookings: _allBookings,
            onSelectChat: (_, bookingId) => _onOpenChat(bookingId ?? ''),
          ),
        );
      case 3:
        return Container(
          color: const Color(0xFFF9FAFB),
          child: SellerEarningsScreen(showAppBar: false, bookings: _allBookings),
        );
      case 4:
        return Container(
          color: const Color(0xFFF9FAFB),
          child: SellerProfileScreen(showAppBar: false, onLogout: _onLogout),
        );
      default:
        return SellerHomeScreen(
          upcomingJobs: _upcomingJobs,
          pendingRequests: _pendingRequests,
          providerStatusActive: _providerStatusActive,
          onSelectJob: _onSelectJob,
          onManageServices: () => _showOverlay('services'),
          onManagePricing: () => _showOverlay('pricing'),
          onStatusChange: _onStatusChange,
        );
    }
  }

  Widget _buildOverlayContent() {
    switch (_currentOverlay) {
      case 'booking-details':
        if (_selectedBookingId == null) return const SizedBox.shrink();
        return SellerBookingDetailsScreen(
          bookingId: _selectedBookingId!,
          onBack: _onBackFromBookingDetails,
          onOpenChat: (id, {String? partnerName}) => _onOpenChat(id, partnerName: partnerName),
          onUpdateBooking: _onUpdateBooking,
          initialBooking: null,
        );
      case 'chat':
        if (_selectedChatId == null) return const SizedBox.shrink();
        return ChatScreen(
          threadId: _selectedThreadId,
          bookingId: _selectedChatId,
          userRole: 'provider',
          providerName: null,
          onBack: _onBackFromChat,
        );
      case 'notifications':
        return NotificationsScreen(
          onBack: () => setState(() => _currentOverlay = null),
          onNavTabTap: (index) => setState(() {
            _currentOverlay = null;
            _activeTab = index;
          }),
        );
      case 'availability':
        return _placeholderScreen('Availability', 'Set your working hours', () => setState(() => _currentOverlay = null));
      case 'services':
        return ServiceCoverageScreen(
          onBack: _hideOverlay,
        );
      case 'pricing':
        return _placeholderScreen('Pricing', 'Manage your rates', () => setState(() => _currentOverlay = null));
      case 'cabinet-requests':
        return ProviderCabinetListScreen(
          onBack: _hideOverlay,
          onSelectRequest: (id) => setState(() {
            _selectedCabinetRequestId = id;
            _currentOverlay = 'cabinet-detail';
          }),
        );
      case 'cabinet-detail':
        if (_selectedCabinetRequestId == null) return const SizedBox.shrink();
        return ProviderCabinetDetailScreen(
          requestId: _selectedCabinetRequestId!,
          onBack: () => setState(() {
            _currentOverlay = 'cabinet-requests';
          }),
          onOpenBooking: (bookingId) {
            _hideOverlay();
            _onSelectJob(bookingId);
          },
        );
      default:
        return _buildTabContent();
    }
  }

  Widget _placeholderScreen(String title, String subtitle, VoidCallback onBack) {
    return Container(
      color: _bgBlue,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22.sp),
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                  ),
                  SizedBox(width: 12.w),
                  Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(subtitle, style: TextStyle(fontSize: 16.sp, color: Colors.white70)),
                    SizedBox(height: 24.h),
                    Text('Coming soon', style: TextStyle(fontSize: 14.sp, color: Colors.white54)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceCoverageScreen extends ConsumerStatefulWidget {
  const ServiceCoverageScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<ServiceCoverageScreen> createState() => _ServiceCoverageScreenState();
}

class _ServiceCoverageScreenState extends ConsumerState<ServiceCoverageScreen> {
  final Set<String> _selectedAreaIds = {};
  final Set<String> _selectedCategoryIds = {};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final townsAsync = ref.watch(townsControllerProvider);
    final servicesAsync = ref.watch(catalogServicesProvider);

    return Container(
      color: const Color(0xFF1F84F6),
      // Already below provider header + status bar; skip top SafeArea to avoid a large gap.
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 96.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 16.h),
                  _buildSectionTitle(
                    icon: Icons.location_on_outlined,
                    title: 'Service Areas',
                    subtitle: townsAsync.maybeWhen(
                      data: (towns) => '${_selectedAreaIds.length} selected',
                      orElse: () => 'Loading...',
                    ),
                  ),
                  SizedBox(height: 12.h),
                  townsAsync.when(
                    loading: () => Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.h),
                        child: const CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Text(
                        err.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 13.sp),
                      ),
                    ),
                    data: (towns) {
                      if (towns.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Text(
                            'No towns available',
                            style: TextStyle(color: Colors.white, fontSize: 13.sp),
                          ),
                        );
                      }
                      return Wrap(
                        spacing: 12.w,
                        runSpacing: 12.h,
                        children: towns
                            .map(
                              (town) => _AreaCard(
                                town: town,
                                selected: _selectedAreaIds.contains(town.id),
                                onTap: () => _toggleArea(town.id),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  SizedBox(height: 24.h),
                  _buildSectionTitle(
                    icon: Icons.store_mall_directory_outlined,
                    title: 'Service Categories',
                    subtitle: servicesAsync.maybeWhen(
                      data: (_) => '${_selectedCategoryIds.length} selected',
                      orElse: () => 'Loading...',
                    ),
                  ),
                  SizedBox(height: 4.h),
                  servicesAsync.when(
                    loading: () => Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: const CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Text(
                        err.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 13.sp),
                      ),
                    ),
                    data: (services) {
                      if (services.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Text(
                            'No services available',
                            style: TextStyle(color: Colors.white, fontSize: 13.sp),
                          ),
                        );
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: services.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 10.h,
                          mainAxisExtent: 96.h,
                        ),
                        itemBuilder: (context, index) {
                          final service = services[index];
                          final selected =
                              _selectedCategoryIds.contains(service.id);
                          return _CategoryCard(
                            service: service,
                            selected: selected,
                            onTap: () => _toggleCategory(service.id),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16.w,
              right: 16.w,
              bottom: 24.h,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCoverage,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  backgroundColor: const Color(0xFF2E9BFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  elevation: 4,
                  shadowColor: Colors.black26,
                ),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'Saving...',
                            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      )
                    : Text(
                        'Save Service Coverage',
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCoverage() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final client = ref.read(httpClientProvider);
      final token = await AuthLocalStorage.getToken();

      final res = await client.put(
        Uri.parse(ProviderApi.serviceAreas),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.toString().isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'towns': _selectedAreaIds.toList(),
          'serviceIds': _selectedCategoryIds.toList(),
        }),
      );

      dynamic decoded;
      try {
        decoded = jsonDecode(res.body);
      } catch (_) {
        decoded = null;
      }

      if (res.statusCode >= 400) {
        final msg = (decoded is Map<String, dynamic>)
            ? decoded['message']?.toString()
            : null;
        throw Exception(msg ?? 'Failed to save coverage');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service coverage saved')),
      );
      widget.onBack();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: widget.onBack,
              icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.sp),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Areas & Categories',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Choose where and what services you offer',
                  style: TextStyle(fontSize: 13.sp, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Container(
          height: 6.h,
          width: 80.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(999.r),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title, required String subtitle}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        SizedBox(width: 8.w),
        Text(
          '($subtitle)',
          style: TextStyle(fontSize: 13.sp, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  void _toggleArea(String id) {
    setState(() {
      if (_selectedAreaIds.contains(id)) {
        _selectedAreaIds.remove(id);
      } else {
        _selectedAreaIds.add(id);
      }
    });
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selectedCategoryIds.contains(id)) {
        _selectedCategoryIds.remove(id);
      } else {
        _selectedCategoryIds.add(id);
      }
    });
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.town, required this.selected, required this.onTap});

  final Town town;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (ScreenUtil().screenWidth - 16.w * 2 - 12.w) / 2,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.place_outlined, color: const Color(0xFF3B82F6), size: 18.sp),
                      const Spacer(),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    town.name,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1B2733)),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    town.state.isNotEmpty ? town.state : 'BC',
                    style: TextStyle(fontSize: 12.sp, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 14.sp),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.service, required this.selected, required this.onTap});

  final _CatalogService service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final description =
        service.description.isNotEmpty ? service.description : 'Tap to select';

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategoryLeadingIcon(iconUrl: service.iconUrl),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          service.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1B2733),
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            height: 1.25,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.check, color: Colors.white, size: 14.sp),
              ),
            ),
        ],
      ),
    );
  }
}

/// Same blue weight as [_AreaCard] pin; stays on the left of the text column.
class _CategoryLeadingIcon extends StatelessWidget {
  const _CategoryLeadingIcon({required this.iconUrl});

  final String iconUrl;

  static const Color _blue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    if (iconUrl.isEmpty) {
      return Icon(
        Icons.home_repair_service_outlined,
        size: 18.sp,
        color: _blue,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6.r),
      child: Image.network(
        iconUrl,
        width: 20.w,
        height: 20.w,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.home_repair_service_outlined,
          size: 18.sp,
          color: _blue,
        ),
      ),
    );
  }
}

class _CatalogService {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final bool isActive;

  const _CatalogService({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.isActive,
  });

  factory _CatalogService.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString();
    return _CatalogService(
      id: s(json['_id']).isNotEmpty ? s(json['_id']) : s(json['id']),
      name: s(json['name']),
      description: s(json['description']),
      iconUrl: s(json['iconUrl']),
      isActive: json['isActive'] == null ? true : json['isActive'] == true,
    );
  }
}
