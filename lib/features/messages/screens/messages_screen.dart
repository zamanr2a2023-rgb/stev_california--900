import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/models/town.dart';
import 'package:renizo/core/widgets/app_logo_button.dart';
import 'package:renizo/features/bookings/data/bookings_mock_data.dart';
import 'package:renizo/features/home/widgets/customer_header.dart';
import 'package:renizo/features/messages/data/chat_api_service.dart';
import 'package:renizo/features/messages/screens/chat_screen.dart';
import 'package:renizo/features/notifications/screens/notifications_screen.dart';
import 'package:renizo/features/seller/models/seller_job_item.dart';
import 'package:renizo/features/town/screens/town_selection_screen.dart';

/// Chat list item – from API thread or mock/seller bookings.
class ChatListItem {
  const ChatListItem({
    required this.id,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
    required this.providerAvatar,
    required this.categoryName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.timeAgo,
    required this.unreadCount,
    required this.bookingStatus,
    this.threadId,
  });

  final String id;
  final String bookingId;
  final String providerId;
  final String providerName;
  final String providerAvatar;
  final String categoryName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String timeAgo;
  final int unreadCount;
  final BookingStatus bookingStatus;
  /// From API GET /chat/threads – used to open chat and call read API.
  final String? threadId;
}

/// Messages screen – unified for customer and seller (provider).
/// Customer: CustomerHeader, loadBookingsForCustomer, chat with providers.
/// Seller: simple blue header "Chat with your customers", list from sellerBookings.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    this.customerId = 'customer1',
    this.userRole = 'customer',
    this.showAppBar = true,
    this.sellerBookings,
    this.onSelectChat,
    this.selectedTownId,
    this.selectedTownName,
    this.onChangeTown,
    this.onNotifications,
  });

  final String customerId;
  /// 'customer' | 'provider'. When 'provider', use sellerBookings for list and "Chat with your customers" header.
  final String userRole;
  /// When false, no AppBar (e.g. embedded in provider app tab).
  final bool showAppBar;
  /// For userRole == 'provider': list of seller bookings to show as chat threads.
  final List<SellerJobItem>? sellerBookings;
  /// (otherPartyId, bookingId). For customer: providerId; for provider: call with (_, bookingId).
  final void Function(String otherPartyId, String? bookingId)? onSelectChat;
  final String? selectedTownId;
  final String? selectedTownName;
  final VoidCallback? onChangeTown;
  final VoidCallback? onNotifications;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<ChatListItem> _chats = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTownName;
  String? _selectedTownId;

  static const Color _bgBlue = Color(0xFF2384F4);

  Future<void> _onChangeTown() async {
    widget.onChangeTown?.call();
    if (widget.onChangeTown != null) return;
    if (!mounted) return;
    final town = await Navigator.of(context).push<Town>(
      MaterialPageRoute<Town>(
        builder: (context) => TownSelectionScreen(
          onSelectTown: (t) => Navigator.of(context).pop(t),
          canClose: true,
        ),
      ),
    );
    if (town != null && mounted) {
      setState(() {
        _selectedTownName = town.name;
        _selectedTownId = town.id;
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

  bool get _isProvider => widget.userRole == 'provider';
  final ChatApiService _chatApi = ChatApiService();

  static BookingStatus _statusFromString(String? s) {
    if (s == null || s.isEmpty) return BookingStatus.pending;
    switch (s.toLowerCase()) {
      case 'pending':
      case 'pending_payment':
        return BookingStatus.pending;
      case 'rejected':
        return BookingStatus.rejected;
      case 'accepted':
        return BookingStatus.accepted;
      case 'confirmed':
      case 'paid':
        return BookingStatus.confirmed;
      case 'in_progress':
      case 'in progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  static String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes.abs() < 60) return '${diff.inMinutes.abs()}m ago';
    if (diff.inHours.abs() < 24) return '${diff.inHours.abs()}h ago';
    if (diff.inHours.abs() < 48) return 'Yesterday';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Future<void> _loadThreadsFromApi() async {
    setState(() => _loading = true);
    final threads = await _chatApi.getThreads();
    if (!mounted) return;
    final isProvider = _isProvider;
    final items = <ChatListItem>[];
    for (final t in threads) {
      final other = isProvider ? t.customerId : t.providerId;
      final unread = isProvider ? t.unreadByProvider : t.unreadByCustomer;
      final lastAt = t.lastMessageAt ?? t.updatedAt;
      final status = t.booking?.status;
      items.add(ChatListItem(
        id: t.id,
        bookingId: t.bookingId,
        providerId: other.id,
        providerName: other.fullName,
        providerAvatar: other.avatarUrl ?? '',
        categoryName: t.booking?.status ?? 'Chat',
        lastMessage: t.lastMessage ?? '',
        lastMessageTime: lastAt,
        timeAgo: _timeAgo(lastAt),
        unreadCount: unread,
        bookingStatus: _statusFromString(status),
        threadId: t.id,
      ));
    }
    items.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    setState(() {
      _chats = items;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _loadThreadsFromApi().then((_) {
      if (!mounted) return;
      if (_chats.isEmpty && _isProvider && widget.sellerBookings != null && widget.sellerBookings!.isNotEmpty) {
        _buildChatsFromSellerBookings(widget.sellerBookings!);
        setState(() => _loading = false);
      }
      // Customer: same API only (GET /chat/threads). No mock fallback – same data as API.
    });
  }

  @override
  void didUpdateWidget(MessagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isProvider && widget.sellerBookings != oldWidget.sellerBookings) {
      if (widget.sellerBookings != null && widget.sellerBookings!.isNotEmpty) {
        _buildChatsFromSellerBookings(widget.sellerBookings!);
        setState(() {});
      } else {
        setState(() => _chats = []);
      }
    }
  }

  void _buildChatsFromSellerBookings(List<SellerJobItem> bookings) {
    final now = DateTime.now();
    const lastMessages = {
      BookingStatus.pending: "New booking request",
      BookingStatus.rejected: 'Message received',
      BookingStatus.accepted: 'Please complete payment to confirm.',
      BookingStatus.confirmed: "See you on the scheduled date!",
      BookingStatus.inProgress: "I'm on my way.",
      BookingStatus.completed: 'Thanks for choosing our service!',
      BookingStatus.cancelled: 'Message received',
    };
    final chats = <ChatListItem>[];
    for (final b in bookings) {
      if (b.status == BookingStatus.cancelled) continue;
      DateTime dt;
      try {
        final parts = b.scheduledDate.split('-');
        final timeParts = b.scheduledTime.split(':');
        dt = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
          timeParts.length >= 2 ? int.parse(timeParts[0]) : 0,
          timeParts.length >= 2 ? int.parse(timeParts[1]) : 0,
        );
      } catch (_) {
        dt = now;
      }
      final diff = now.difference(dt);
      String timeAgo;
      if (diff.inMinutes.abs() < 60) {
        timeAgo = '${diff.inMinutes.abs()}m ago';
      } else if (diff.inHours.abs() < 24) {
        timeAgo = '${diff.inHours.abs()}h ago';
      } else if (diff.inHours.abs() < 48) {
        timeAgo = 'Yesterday';
      } else {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        timeAgo = '${months[dt.month - 1]} ${dt.day}';
      }
      chats.add(
        ChatListItem(
          id: 'chat-${b.id}',
          bookingId: b.id,
          providerId: '',
          providerName: b.customerName,
          providerAvatar: '',
          categoryName: b.categoryName,
          lastMessage: lastMessages[b.status] ?? 'Message received',
          lastMessageTime: dt,
          timeAgo: timeAgo,
          unreadCount: b.status == BookingStatus.pending ? 1 : 0,
          bookingStatus: b.status,
        ),
      );
    }
    chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    _chats = chats;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() => _loading = true);
    final bookings = await loadBookingsForCustomer(widget.customerId);
    if (!mounted) return;
    final active = bookings
        .where((b) => b.status != BookingStatus.cancelled)
        .toList();

    final lastMessages = {
      BookingStatus.pending:
          "Thanks for booking! I'll confirm the details shortly.",
      BookingStatus.rejected: 'Message received',
      BookingStatus.accepted: 'Please complete payment to confirm.',
      BookingStatus.confirmed: "See you on the scheduled date!",
      BookingStatus.inProgress: "I'm on my way to your location.",
      BookingStatus.completed: 'Thanks for choosing our service!',
      BookingStatus.cancelled: 'Message received',
    };

    final now = DateTime.now();
    final chats = <ChatListItem>[];
    for (final booking in active) {
      final dt = booking.scheduledDateTime ?? now;
      final diff = now.difference(dt);
      String timeAgo;
      if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours}h ago';
      } else if (diff.inHours < 48) {
        timeAgo = 'Yesterday';
      } else {
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
        timeAgo = '${months[dt.month - 1]} ${dt.day}';
      }

      chats.add(
        ChatListItem(
          id: 'chat-${booking.id}',
          bookingId: booking.id,
          providerId: booking.id,
          providerName: booking.providerName,
          providerAvatar: booking.providerAvatar,
          categoryName: booking.categoryName,
          lastMessage: lastMessages[booking.status] ?? 'Message received',
          lastMessageTime: dt,
          timeAgo: timeAgo,
          unreadCount: booking.status == BookingStatus.pending ? 1 : 0,
          bookingStatus: booking.status,
        ),
      );
    }
    chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    setState(() {
      _chats = chats;
      _loading = false;
    });
  }

  List<ChatListItem> get _filteredChats {
    if (_searchQuery.isEmpty) return _chats;
    final q = _searchQuery.toLowerCase();
    return _chats.where((c) {
      return c.providerName.toLowerCase().contains(q) ||
          c.categoryName.toLowerCase().contains(q) ||
          c.lastMessage.toLowerCase().contains(q);
    }).toList();
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
        return (const Color(0xFFF3F4F6), const Color(0xFF374151));
      case BookingStatus.cancelled:
        return (const Color(0xFFF3F4F6), const Color(0xFF374151));
    }
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.rejected:
        return 'rejected';
      case BookingStatus.accepted:
        return 'accepted';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.inProgress:
        return 'in progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  Future<void> _onSelectChat(ChatListItem chat) async {
    if (chat.threadId != null) {
      await _chatApi.markThreadRead(chat.threadId!);
    }
    widget.onSelectChat?.call(chat.providerId, chat.bookingId);
    if (widget.onSelectChat != null) return;
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ChatScreen(
          threadId: chat.threadId,
          bookingId: chat.bookingId,
          userRole: _isProvider ? 'provider' : 'customer',
          providerId: chat.providerId.isNotEmpty ? chat.providerId : null,
          providerName: chat.providerName,
          providerAvatar: chat.providerAvatar.isNotEmpty ? chat.providerAvatar : null,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _isProvider ? _buildProviderHeader() : CustomerHeader(
          selectedTownName: widget.selectedTownName ?? _selectedTownName,
          onChangeTown: _onChangeTown,
          onNotifications: _onNotifications,
        ),
        Expanded(
          child: _loading
              ? Center(
                  child: SizedBox(
                    width: 48.w,
                    height: 48.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!_isProvider) ...[
                              Text(
                                'Messages',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                _chats.isEmpty
                                    ? 'No active conversations'
                                    : '${_chats.length} active conversation${_chats.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                            if (_chats.isNotEmpty) ...[
                              SizedBox(height: 2.h),
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search messages...',
                                  hintStyle: TextStyle(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    size: 20.sp,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFF3F4F6),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFF3F4F6),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF408AF1),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 12.h,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            await _loadThreadsFromApi();
                            if (_chats.isEmpty &&
                                _isProvider &&
                                widget.sellerBookings != null &&
                                widget.sellerBookings!.isNotEmpty) {
                              _buildChatsFromSellerBookings(widget.sellerBookings!);
                              if (mounted) setState(() {});
                            }
                          },
                          color: Colors.white,
                          backgroundColor: _bgBlue,
                          child: _filteredChats.isNotEmpty
                              ? ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    16.w,
                                    0,
                                    16.w,
                                    16.h,
                                  ),
                                  itemCount: _filteredChats.length,
                                  itemBuilder: (context, index) {
                                    final chat = _filteredChats[index];
                                    return _ChatCard(
                                      chat: chat,
                                      statusColors: _statusColors(
                                        chat.bookingStatus,
                                      ),
                                      statusLabel: _statusLabel(
                                        chat.bookingStatus,
                                      ),
                                      onTap: () => _onSelectChat(chat),
                                    );
                                  },
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight,
                                        ),
                                        child: Center(
                                          child: _buildEmptyState(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );

    if (_isProvider && widget.showAppBar) {
      return Scaffold(
        backgroundColor: _bgBlue,
        appBar: AppBar(
          title: Text(
            'Messages',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: _bgBlue,
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
    return Scaffold(
      backgroundColor: _bgBlue,
      body: content,
    );
  }

  Widget _buildProviderHeader() {
    return Container(
      width: double.infinity,
      color: _bgBlue,
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            SizedBox(height: 2.h),
            Text(
              'Chat with your customers',
              style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    // On blue body: light icon tile + white copy for contrast.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40.sp,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            _searchQuery.isEmpty ? 'No messages yet' : 'No results found',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          Text(
            _searchQuery.isEmpty
                ? (_isProvider
                    ? 'Customer messages will appear here'
                    : 'Book a service to start chatting with providers')
                : 'Try searching with different keywords',
            style: TextStyle(
              fontSize: 15.sp,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    required this.chat,
    required this.statusColors,
    required this.statusLabel,
    required this.onTap,
  });

  final ChatListItem chat;
  final (Color bg, Color text) statusColors;
  final String statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = chat.providerName.isNotEmpty
        ? chat.providerName[0].toUpperCase()
        : '?';

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: chat.providerAvatar.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: chat.providerAvatar,
                              width: 56.w,
                              height: 56.h,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  _avatarPlaceholder(initial),
                              errorWidget: (_, __, ___) =>
                                  _avatarPlaceholder(initial),
                            )
                          : _avatarPlaceholder(initial),
                    ),
                    if (chat.unreadCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 24.w,
                          height: 24.h,
                          decoration: const BoxDecoration(
                            color: Color(0xFF408AF1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${chat.unreadCount}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chat.providerName,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF111827),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  chat.categoryName,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                chat.timeAgo,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColors.$1,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w500,
                                    color: statusColors.$2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        chat.lastMessage,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: chat.unreadCount > 0
                              ? const Color(0xFF111827)
                              : const Color(0xFF4B5563),
                          fontWeight: chat.unreadCount > 0
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.chevron_right,
                  size: 20.sp,
                  color: const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(String initial) {
    return Container(
      width: 56.w,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF408AF1), Color(0xFF5ca3f5)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
