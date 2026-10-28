class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String senderRole; // "STUDENT" or "OWNER"
  final String text;
  final String? imageUrl;
  final String timestamp;
  final bool isRead;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.senderRole,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    this.isRead = false,
  });

  bool isMe(String currentUserId, String currentUserRole) {
    if (senderId == currentUserId && currentUserId.isNotEmpty) return true;
    return senderRole == currentUserRole;
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? 'User',
      senderAvatar: json['senderAvatar']?.toString(),
      senderRole: json['senderRole']?.toString() ?? 'STUDENT',
      text: json['text']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      isRead: json['isRead'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      if (senderAvatar != null) 'senderAvatar': senderAvatar,
      'senderRole': senderRole,
      'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? senderRole,
    String? text,
    String? imageUrl,
    String? timestamp,
    bool? isRead,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class ChatConversationModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerAvatar;
  final String? ownerPhone;
  final String studentId;
  final String studentName;
  final String? studentAvatar;
  final String? studentPhone;
  final int? propertyId;
  final String? propertyName;
  final int? roomId;
  final String? roomNumber;
  final double? roomPrice;
  final String lastMessage;
  final String lastMessageTime;
  final int studentUnreadCount;
  final int ownerUnreadCount;
  final List<ChatMessageModel> messages;

  ChatConversationModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatar,
    this.ownerPhone,
    required this.studentId,
    required this.studentName,
    this.studentAvatar,
    this.studentPhone,
    this.propertyId,
    this.propertyName,
    this.roomId,
    this.roomNumber,
    this.roomPrice,
    required this.lastMessage,
    required this.lastMessageTime,
    this.studentUnreadCount = 0,
    this.ownerUnreadCount = 0,
    this.messages = const [],
  });

  int getUnreadCount(bool isOwner) => isOwner ? ownerUnreadCount : studentUnreadCount;

  String getOtherPartyName(bool isOwner) => isOwner ? studentName : ownerName;

  String? getOtherPartyAvatar(bool isOwner, {String? currentUserAvatar, String? currentUserName}) {
    final avatar = isOwner ? studentAvatar : ownerAvatar;
    if (avatar != null && avatar.trim().isNotEmpty) return avatar;

    final otherName = getOtherPartyName(isOwner);
    if (currentUserName != null &&
        otherName.trim().toLowerCase() == currentUserName.trim().toLowerCase() &&
        currentUserAvatar != null &&
        currentUserAvatar.trim().isNotEmpty) {
      return currentUserAvatar;
    }
    return null;
  }

  String? getOtherPartyPhone(bool isOwner) => isOwner ? studentPhone : ownerPhone;

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    List<ChatMessageModel> msgs = [];
    if (json['messages'] is List) {
      msgs = (json['messages'] as List)
          .map((m) => ChatMessageModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    return ChatConversationModel(
      id: json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? 'Owner',
      ownerAvatar: json['ownerAvatar'],
      ownerPhone: json['ownerPhone'],
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? 'Student',
      studentAvatar: json['studentAvatar'],
      studentPhone: json['studentPhone'],
      propertyId: json['propertyId'] is int ? json['propertyId'] : int.tryParse(json['propertyId']?.toString() ?? ''),
      propertyName: json['propertyName'],
      roomId: json['roomId'] is int ? json['roomId'] : int.tryParse(json['roomId']?.toString() ?? ''),
      roomNumber: json['roomNumber']?.toString(),
      roomPrice: json['roomPrice'] is num ? (json['roomPrice'] as num).toDouble() : double.tryParse(json['roomPrice']?.toString() ?? ''),
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageTime: json['lastMessageTime']?.toString() ?? DateTime.now().toIso8601String(),
      studentUnreadCount: json['studentUnreadCount'] ?? 0,
      ownerUnreadCount: json['ownerUnreadCount'] ?? 0,
      messages: msgs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerAvatar': ownerAvatar,
      'ownerPhone': ownerPhone,
      'studentId': studentId,
      'studentName': studentName,
      'studentAvatar': studentAvatar,
      'studentPhone': studentPhone,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'roomPrice': roomPrice,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'studentUnreadCount': studentUnreadCount,
      'ownerUnreadCount': ownerUnreadCount,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  ChatConversationModel copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? ownerAvatar,
    String? ownerPhone,
    String? studentId,
    String? studentName,
    String? studentAvatar,
    String? studentPhone,
    int? propertyId,
    String? propertyName,
    int? roomId,
    String? roomNumber,
    double? roomPrice,
    String? lastMessage,
    String? lastMessageTime,
    int? studentUnreadCount,
    int? ownerUnreadCount,
    List<ChatMessageModel>? messages,
  }) {
    return ChatConversationModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatar: ownerAvatar ?? this.ownerAvatar,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentAvatar: studentAvatar ?? this.studentAvatar,
      studentPhone: studentPhone ?? this.studentPhone,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      roomPrice: roomPrice ?? this.roomPrice,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      studentUnreadCount: studentUnreadCount ?? this.studentUnreadCount,
      ownerUnreadCount: ownerUnreadCount ?? this.ownerUnreadCount,
      messages: messages ?? this.messages,
    );
  }
}
