/// API response models for chat – threads list and messages.
library;

class ApiChatThreadUser {
  const ApiChatThreadUser({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });
  final String id;
  final String fullName;
  final String? avatarUrl;

  factory ApiChatThreadUser.fromJson(Map<String, dynamic> json) {
    return ApiChatThreadUser(
      id: json['_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class ApiChatThreadBooking {
  const ApiChatThreadBooking({
    required this.id,
    this.scheduledAt,
    this.status,
  });
  final String id;
  final String? scheduledAt;
  final String? status;

  factory ApiChatThreadBooking.fromJson(Map<String, dynamic> json) {
    return ApiChatThreadBooking(
      id: json['_id']?.toString() ?? '',
      scheduledAt: json['scheduledAt']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

class ApiChatThread {
  const ApiChatThread({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderUserId,
    this.lastSenderRole,
    this.unreadByCustomer = 0,
    this.unreadByProvider = 0,
    required this.createdAt,
    required this.updatedAt,
    this.booking,
  });
  final String id;
  final String bookingId;
  final ApiChatThreadUser customerId;
  final ApiChatThreadUser providerId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderUserId;
  final String? lastSenderRole;
  final int unreadByCustomer;
  final int unreadByProvider;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ApiChatThreadBooking? booking;

  /// Thread ID from API: use this as {{thread_Id}} in /chat/threads/:threadId/read and /chat/threads/:threadId/messages.
  String get threadId => id;

  factory ApiChatThread.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? '';
    String bookingId = id;
    ApiChatThreadBooking? booking;
    if (json['bookingId'] != null) {
      if (json['bookingId'] is String) {
        bookingId = json['bookingId'] as String;
      } else {
        final b = json['bookingId'] as Map<String, dynamic>?;
        if (b != null) {
          booking = ApiChatThreadBooking.fromJson(b);
          bookingId = booking.id;
        }
      }
    }
    final cust = json['customerId'];
    final prov = json['providerId'];
    return ApiChatThread(
      id: id,
      bookingId: bookingId,
      customerId: ApiChatThreadUser.fromJson(
        cust is Map<String, dynamic> ? cust : <String, dynamic>{},
      ),
      providerId: ApiChatThreadUser.fromJson(
        prov is Map<String, dynamic> ? prov : <String, dynamic>{},
      ),
      lastMessage: json['lastMessage']?.toString(),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      lastSenderUserId: json['lastSenderUserId']?.toString(),
      lastSenderRole: json['lastSenderRole']?.toString(),
      unreadByCustomer: (json['unreadByCustomer'] is int)
          ? json['unreadByCustomer'] as int
          : int.tryParse(json['unreadByCustomer']?.toString() ?? '0') ?? 0,
      unreadByProvider: (json['unreadByProvider'] is int)
          ? json['unreadByProvider'] as int
          : int.tryParse(json['unreadByProvider']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      booking: booking,
    );
  }
}

class ApiChatMessageDetected {
  const ApiChatMessageDetected({
    this.hasPhone = false,
    this.hasEmail = false,
    this.hasContactIntent = false,
  });
  final bool hasPhone;
  final bool hasEmail;
  final bool hasContactIntent;

  factory ApiChatMessageDetected.fromJson(Map<String, dynamic> json) {
    return ApiChatMessageDetected(
      hasPhone: json['hasPhone'] == true,
      hasEmail: json['hasEmail'] == true,
      hasContactIntent: json['hasContactIntent'] == true,
    );
  }
}

class ApiChatMessage {
  const ApiChatMessage({
    required this.id,
    required this.threadId,
    required this.senderUserId,
    required this.senderRole,
    required this.message,
    this.isBlocked = false,
    this.blockedReason,
    required this.detected,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id;
  final String threadId;
  final String senderUserId;
  final String senderRole; // 'customer' | 'provider'
  final String message;
  final bool isBlocked;
  final String? blockedReason;
  final ApiChatMessageDetected detected;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ApiChatMessage.fromJson(Map<String, dynamic> json) {
    final det = json['detected'];
    return ApiChatMessage(
      id: json['_id']?.toString() ?? '',
      threadId: json['threadId']?.toString() ?? '',
      senderUserId: json['senderUserId']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? 'customer',
      message: json['message']?.toString() ?? '',
      isBlocked: json['isBlocked'] == true,
      blockedReason: json['blockedReason']?.toString(),
      detected: ApiChatMessageDetected.fromJson(
        det is Map<String, dynamic> ? det : <String, dynamic>{},
      ),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
