import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/models/town.dart';
import 'package:renizo/features/bookings/data/bookings_mock_data.dart';
import 'package:renizo/features/home/widgets/customer_header.dart';
import 'package:renizo/features/messages/data/chat_api_service.dart';
import 'package:renizo/features/nav_bar/screen/bottom_nav_bar.dart';
import 'package:renizo/features/town/screens/town_selection_screen.dart';

import '../../notifications/screens/notifications_screen.dart';

/// Single chat message – mirrors React ChatScreen Message interface.
/// Optional [imageUrl] for photo messages; [content] can be caption or empty.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.sent = true,
    this.read = false,
    this.imageUrl,
  });

  final String id;
  final String senderId; // 'user' | 'provider'
  final String content;
  final String timestamp;
  final bool sent;
  final bool read;

  /// Optional image URL for photo messages (displayed in bubble via CachedNetworkImage).
  final String? imageUrl;
}

/// Chat partner info for header.
class ChatPartner {
  const ChatPartner({required this.name, this.avatar, this.isOnline = true});
  final String name;
  final String? avatar;
  final bool isOnline;
}

/// Chat screen – Flutter conversion of ChatScreen.tsx.
/// Same app header and bottom nav as CustomerHomeScreen; chat bar, messages, input.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    this.threadId,
    this.bookingId,
    this.userRole = 'customer',
    this.providerId,
    this.providerName,
    this.providerAvatar,
    this.onBack,
    this.selectedTownId,
    this.selectedTownName,
    this.onChangeTown,
    this.onNotifications,
  });

  /// From API GET /chat/threads – when set, load/send messages via API.
  final String? threadId;
  /// When provided with userRole, loads booking and generates conversation (mock when no threadId).
  final String? bookingId;
  final String userRole; // 'customer' | 'provider'
  /// When no bookingId, use provider info for header and initial messages.
  final String? providerId;
  final String? providerName;
  final String? providerAvatar;
  final VoidCallback? onBack;
  final String? selectedTownId;
  final String? selectedTownName;
  final VoidCallback? onChangeTown;
  final VoidCallback? onNotifications;

  static const String routeName = '/chat';

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatApiService _chatApi = ChatApiService();

  List<ChatMessage> _messages = [];
  ChatPartner? _chatPartner;
  bool _loading = true;
  bool _isTyping = false;
  bool _showWarning = false;
  String _warningType = 'phone';
  String? _selectedTownName;
  String? _selectedTownId;
  /// When opening with bookingId only, we resolve thread via API and store here for load/send.
  String? _resolvedThreadId;

  /// Display name in header: from messages_screen (providerName = other party name) or fallback.
  String get _partnerDisplayName {
    final n = widget.providerName;
    if (n != null && n.trim().isNotEmpty) return n.trim();
    return 'Chat Partner';
  }

  static const Color _bgBlue = Color(0xFF2384F4);
  static const Color _gradientStart = Color(0xFF408AF1);
  static const Color _gradientEnd = Color(0xFF5ca3f5);

  Future<void> _onChangeTown() async {
    widget.onChangeTown?.call();
    if (widget.onChangeTown != null) return;
    if (!mounted) return;
    final town = await Navigator.of(context).push<Town>(
      MaterialPageRoute<Town>(
        // Old  code ;
        // builder: (context) => TownSelectionScreenWithProvider(
        //   onSelectTown: (t) => Navigator.of(context).pop(t),
        //   canClose: true,
        // ),

        //Update code.
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

  void _onNavTabTap(int index) {
    if (index == 3) return; // Already on Messages
    Navigator.of(context).pop();
    ref.read(selectedIndexProvider.notifier).state = index;
  }

  String? get _effectiveThreadId => widget.threadId ?? _resolvedThreadId;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() => setState(() {}));
    if (widget.threadId != null) {
      _chatPartner = ChatPartner(
        name: _partnerDisplayName,
        avatar: widget.providerAvatar,
        isOnline: true,
      );
      _loadMessagesFromApi();
      _chatApi.markThreadRead(widget.threadId!);
    } else if (widget.bookingId != null && widget.userRole.isNotEmpty) {
      _chatPartner = ChatPartner(
        name: _partnerDisplayName,
        avatar: widget.providerAvatar,
        isOnline: true,
      );
      _resolveThreadAndLoadMessages();
    } else if (widget.providerName != null && widget.providerName!.trim().isNotEmpty) {
      setState(() {
        _chatPartner = ChatPartner(
          name: widget.providerName!.trim(),
          avatar: widget.providerAvatar,
          isOnline: true,
        );
        _messages = _generateInitialMessages(widget.providerName!);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  /// When we have bookingId but no threadId: POST /chat/threads to get/create thread, then load messages.
  Future<void> _resolveThreadAndLoadMessages() async {
    final bookingId = widget.bookingId;
    if (bookingId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final threadId = await _chatApi.getOrCreateThread(bookingId);
    if (!mounted) return;
    if (threadId != null) {
      _resolvedThreadId = threadId;
      await _chatApi.markThreadRead(threadId);
      if (!mounted) return;
      await _loadMessagesFromApi();
    } else {
      _loadChatData();
    }
  }

  

  Future<void> _loadMessagesFromApi() async {
    final threadId = _effectiveThreadId;
    if (threadId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final list = await _chatApi.getMessages(threadId, limit: 30);
    if (!mounted) return;
    final uiMessages = list.map((m) {
      final content = m.isBlocked
          ? (m.blockedReason ?? '[Message blocked - Contact information not allowed]')
          : m.message;
      return ChatMessage(
        id: m.id,
        senderId: m.senderRole,
        content: content,
        timestamp: _formatTime(m.createdAt),
        sent: true,
        read: true,
      );
    }).toList();
    setState(() {
      _messages = uiMessages;
      _loading = false;
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatData() async {
    if (widget.bookingId == null) return;
    setState(() => _loading = true);
    final booking = await getBookingById(widget.bookingId!);
    if (!mounted) return;
    if (booking == null) {
      setState(() => _loading = false);
      return;
    }

    if (widget.userRole == 'customer') {
      setState(() {
        _chatPartner = ChatPartner(
          name: booking.providerName,
          avatar: booking.providerAvatar.isNotEmpty
              ? booking.providerAvatar
              : null,
          isOnline: true,
        );
        _messages = _generateBookingConversation(booking);
        _loading = false;
      });
    } else {
      setState(() {
        _chatPartner = const ChatPartner(name: 'Customer', isOnline: true);
        _messages = _generateBookingConversation(booking);
        _loading = false;
      });
    }
  }

  List<ChatMessage> _generateInitialMessages(String providerName) {
    final now = DateTime.now();
    String fmt(DateTime d) => _formatTime(d);
    return [
      ChatMessage(
        id: '1',
        senderId: 'provider',
        content: "Hi! I'm $providerName. How can I help you today?",
        timestamp: fmt(now.subtract(const Duration(hours: 1))),
        sent: true,
        read: true,
      ),
      ChatMessage(
        id: '2',
        senderId: 'user',
        content: 'Hi! I was wondering about your availability this week.',
        timestamp: fmt(now.subtract(const Duration(minutes: 50))),
        sent: true,
        read: true,
      ),
      ChatMessage(
        id: '3',
        senderId: 'provider',
        content:
            'I have openings on Tuesday and Thursday afternoon. Would either of those work for you?',
        timestamp: fmt(now.subtract(const Duration(minutes: 40))),
        sent: true,
        read: true,
      ),
    ];
  }

  List<ChatMessage> _generateBookingConversation(BookingDetailsModel booking) {
    final now = DateTime.now();
    String fmt(DateTime d) => _formatTime(d);
    final list = <ChatMessage>[
      ChatMessage(
        id: '1',
        senderId: 'provider',
        content: "Thanks for booking with us! I've received your request.",
        timestamp: fmt(now.subtract(const Duration(hours: 2))),
        sent: true,
        read: true,
      ),
      ChatMessage(
        id: '1b',
        senderId: 'provider',
        content: 'Here’s a reference photo of the service area.',
        timestamp: fmt(now.subtract(const Duration(hours: 1, minutes: 50))),
        sent: true,
        read: true,
        imageUrl: 'https://picsum.photos/200/150',
      ),
      ChatMessage(
        id: '2',
        senderId: 'user',
        content: 'Great! What time works best for you?',
        timestamp: fmt(now.subtract(const Duration(hours: 1, minutes: 55))),
        sent: true,
        read: true,
      ),
    ];

    final status = booking.status;
    if (status == BookingStatus.confirmed ||
        status == BookingStatus.inProgress ||
        status == BookingStatus.completed) {
      list.add(
        ChatMessage(
          id: '3',
          senderId: 'provider',
          content:
              "I've confirmed your appointment for ${booking.scheduledDate} at ${booking.scheduledTime}. See you then!",
          timestamp: fmt(now.subtract(const Duration(hours: 1))),
          sent: true,
          read: true,
        ),
      );
    }
    if (status == BookingStatus.inProgress) {
      list.add(
        ChatMessage(
          id: '4',
          senderId: 'provider',
          content: "I'm on my way to your location now!",
          timestamp: fmt(now.subtract(const Duration(minutes: 30))),
          sent: true,
          read: true,
        ),
      );
    }
    if (status == BookingStatus.completed) {
      list.add(
        ChatMessage(
          id: '4',
          senderId: 'provider',
          content: 'Service completed! Thank you for choosing us.',
          timestamp: fmt(now.subtract(const Duration(minutes: 15))),
          sent: true,
          read: true,
        ),
      );
      list.add(
        ChatMessage(
          id: '5',
          senderId: 'user',
          content: 'Thank you! Great service.',
          timestamp: fmt(now.subtract(const Duration(minutes: 10))),
          sent: true,
          read: true,
        ),
      );
    }
    return list;
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Simple contact attempt detection (phone, email, common phrases).
  ({bool isViolation, String? violationType}) _detectContactAttempt(
    String text,
  ) {
    final lower = text.toLowerCase();
    final phone = RegExp(r'\+?\d{10,}|\d{3}[-.\s]?\d{3}[-.\s]?\d{4}');
    final email = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    if (phone.hasMatch(text)) {
      return (isViolation: true, violationType: 'phone');
    }
    if (email.hasMatch(text)) {
      return (isViolation: true, violationType: 'email');
    }
    if (lower.contains('my number is') ||
        lower.contains('call me at') ||
        lower.contains('email me at')) {
      return (isViolation: true, violationType: 'phrase');
    }
    return (isViolation: false, violationType: null);
  }

  void _onMessageChanged(String text) {
    final detection = _detectContactAttempt(text);
    setState(() {
      if (detection.isViolation && detection.violationType != null) {
        _showWarning = true;
        _warningType = detection.violationType!;
      } else {
        _showWarning = false;
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final threadId = _effectiveThreadId;
    if (threadId != null) {
      final sent = await _chatApi.sendMessage(threadId, text);
      if (!mounted) return;
      if (sent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
        return;
      }
      if (sent.isBlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sent.blockedReason ?? 'Message blocked'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final newMsg = ChatMessage(
        id: sent.id,
        senderId: sent.senderRole,
        content: sent.message,
        timestamp: _formatTime(sent.createdAt),
        sent: true,
        read: false,
      );
      setState(() {
        _messages = [..._messages, newMsg];
        _messageController.clear();
        _showWarning = false;
      });
      _scrollToBottom();
      return;
    }

    final detection = _detectContactAttempt(text);
    if (detection.isViolation) {
      setState(() {
        _showWarning = true;
        if (detection.violationType != null) {
          _warningType = detection.violationType!;
        }
      });
      _showContactWarningDialog();
      return;
    }

    final now = DateTime.now();
    final newMsg = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      senderId: 'user',
      content: text,
      timestamp: _formatTime(now),
      sent: true,
      read: false,
    );
    setState(() {
      _messages = [..._messages, newMsg];
      _messageController.clear();
      _showWarning = false;
    });
    _scrollToBottom();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Message sent')));

    if (DateTime.now().millisecondsSinceEpoch % 3 != 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() => _isTyping = true);
      });
      final responses = [
        "Thanks for your message! I'll get back to you shortly.",
        "Got it! I'll check my schedule and confirm.",
        "Absolutely! That works for me.",
        "No problem at all. I'm happy to help!",
        "Great question! Let me provide some details...",
      ];
      final delay = 2000 + (DateTime.now().millisecondsSinceEpoch % 2000);
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _messages = [
            ..._messages,
            ChatMessage(
              id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
              senderId: 'provider',
              content:
                  responses[DateTime.now().millisecondsSinceEpoch %
                      responses.length],
              timestamp: _formatTime(DateTime.now()),
              sent: true,
              read: false,
            ),
          ];
        });
        _scrollToBottom();
      });
    }
  }

  void _onAttachment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attachment feature coming soon')),
    );
  }

  void _onImage() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Image sharing coming soon')));
  }

  void _showContactWarningDialog() {
    final type = _warningType;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact warning'),
        content: Text(
          type == 'phone'
              ? 'Sharing phone numbers is not allowed in chat. Please use the app to communicate.'
              : type == 'email'
              ? 'Sharing email addresses is not allowed in chat. Please use the app to communicate.'
              : 'Please avoid sharing contact details outside the app.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _showWarning = false);
            },
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _showWarning = false);
            },
            child: const Text('Edit message'),
          ),
        ],
      ),
    );
  }

  bool get _isProvider => widget.userRole == 'provider';

  @override
  Widget build(BuildContext context) {
    final bodyContent = Column(
      children: [
        if (!_isProvider)
          CustomerHeader(
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
              : Column(
                  children: [
                    _buildHeader(_chatPartner),
                    Expanded(
                      child: _messages.isEmpty && !_isTyping
                          ? Center(
                              child: Text(
                                'No messages yet.\nStart the conversation.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.only(
                                left: 16.w,
                                right: 16.w,
                                top: 12.h,
                                bottom: 4.h,
                              ),
                              itemCount: _messages.length + (_isTyping ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (_isTyping && index == _messages.length) {
                                  return _buildTypingIndicator(_chatPartner);
                                }
                                return _buildMessageBubble(
                                  _messages[index],
                                  _chatPartner,
                                  index > 0 &&
                                      _messages[index - 1].senderId ==
                                          _messages[index].senderId,
                                );
                              },
                            ),
                    ),
                    _buildInputBar(),
                  ],
                ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: _bgBlue,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: _isProvider
          ? null
          : CustomerBottomNavBar(
              currentIndex: 3,
              onTabTap: _onNavTabTap,
            ),
      body: bodyContent,
    );
  }

  Widget _buildHeader(ChatPartner? partner) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                widget.onBack?.call();
                if (widget.onBack != null) return;
                if (mounted) Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.chevron_left,
                size: 28.sp,
                color: const Color(0xFF374151),
              ),
              style: IconButton.styleFrom(backgroundColor: Colors.transparent),
            ),
            SizedBox(width: 12.w),
            _buildAvatar(
              partner?.avatar,
              partner?.name ?? _partnerDisplayName,
              44.r,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    partner?.name ?? _partnerDisplayName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.more_vert,
                size: 24.sp,
                color: const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String name, double size) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: size.toInt() * 2,
          memCacheHeight: size.toInt() * 2,
          placeholder: (_, __) => _avatarPlaceholder(size, initial),
          errorWidget: (_, __, ___) => _avatarPlaceholder(size, initial),
        ),
      );
    }
    return _avatarPlaceholder(size, initial);
  }

  Widget _avatarPlaceholder(double size, String initial) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientEnd],
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: (size * 0.45).clamp(14.0, 22.0),
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage msg,
    ChatPartner? partner,
    bool hideAvatar,
  ) {
    final isUser = msg.senderId == 'user' || msg.senderId == widget.userRole;
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            SizedBox(
              width: 32.w,
              height: 32.h,
              child: hideAvatar
                  ? const SizedBox.shrink()
                  : _buildAvatar(partner?.avatar, partner?.name ?? '', 32.r),
            ),
          if (!isUser) SizedBox(width: 8.w),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [_gradientStart, _gradientEnd],
                      )
                    : null,
                color: isUser ? null : Colors.white,
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFFF3F4F6)),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: SizedBox(
                        width: 200.w,
                        height: 150.h,
                        child: CachedNetworkImage(
                          imageUrl: msg.imageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 400,
                          memCacheHeight: 300,
                          placeholder: (_, __) => Center(
                            child: SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isUser
                                      ? Colors.white70
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: isUser
                                ? Colors.white24
                                : const Color(0xFFF3F4F6),
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 32.sp,
                              color: isUser
                                  ? Colors.white70
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (msg.content.isNotEmpty) SizedBox(height: 8.h),
                  ],
                  if (msg.content.isNotEmpty)
                    Text(
                      msg.content,
                      style: TextStyle(
                        fontSize: 15.sp,
                        height: 1.4,
                        color: isUser ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Text(
                        msg.timestamp,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isUser
                              ? Colors.white70
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      if (isUser) ...[
                        SizedBox(width: 4.w),
                        Icon(
                          msg.read ? Icons.done_all : Icons.done,
                          size: 14.sp,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) SizedBox(width: 8.w),
          if (isUser) const SizedBox(width: 32, height: 32),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ChatPartner? partner) {
    return Padding(
      padding: EdgeInsets.only(bottom: 9.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 32.w,
            height: 32.h,
            child: _buildAvatar(partner?.avatar, partner?.name ?? '', 32.r),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bouncingDot(0),
                SizedBox(width: 6.w),
                _bouncingDot(150),
                SizedBox(width: 6.w),
                _bouncingDot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bouncingDot(int delayMs) {
    return Container(
      width: 8.w,
      height: 8.h,
      decoration: const BoxDecoration(
        color: Color(0xFF9CA3AF),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16.w, 5.h, 16.w, 8.h),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // IconButton(
          //   onPressed: _onAttachment,
          //   icon: Icon(
          //     Icons.attach_file,
          //     size: 22.sp,
          //     color: const Color(0xFF4B5563),
          //   ),
          //   style: IconButton.styleFrom(
          //     backgroundColor: const Color(0xFFF3F4F6),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(12.r),
          //     ),
          //   ),
          // ),
          // SizedBox(width: 8.w),
          // IconButton(
          //   onPressed: _onImage,
          //   icon: Icon(
          //     Icons.image_outlined,
          //     size: 22.sp,
          //     color: const Color(0xFF4B5563),
          //   ),
          //   style: IconButton.styleFrom(
          //     backgroundColor: const Color(0xFFF3F4F6),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(12.r),
          //     ),
          //   ),
          // ),
          // SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: _onMessageChanged,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF9CA3AF),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(color: _gradientStart, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 6.h,
                ),
              ),
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF111827)),
              maxLines: 4,
              minLines: 1,
            ),
          ),
          SizedBox(width: 8.w),
          Padding(
            padding:  EdgeInsets.only(bottom: 12.h),
            child: Material(
              elevation: 4,
              shadowColor: _gradientStart.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16.r),
              child: InkWell(
                onTap: () {
                  if (_messageController.text.trim().isNotEmpty) _sendMessage();
                },
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: _messageController.text.trim().isEmpty
                        ? null
                        : const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [_gradientStart, _gradientEnd],
                          ),
                    color: _messageController.text.trim().isEmpty
                        ? const Color(0xFFE5E7EB)
                        : null,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    size: 22.sp,
                    color: _messageController.text.trim().isEmpty
                        ? const Color(0xFF9CA3AF)
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
