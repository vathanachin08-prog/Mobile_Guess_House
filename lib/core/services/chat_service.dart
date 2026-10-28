import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../data/local/token_store_local.dart';
import '../../models/chat/chat_model.dart';

class ChatService extends GetxService {
  static ChatService get to => Get.find<ChatService>();

  final _storage = GetStorage();
  static const String _storageKey = "APP_CHAT_CONVERSATIONS";

  final conversations = <ChatConversationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadConversations();
  }

  int get totalUnreadCount {
    final isOwner = TokenStoreLocal.isOwner();
    int count = 0;
    for (final c in conversations) {
      count += c.getUnreadCount(isOwner);
    }
    return count;
  }

  void loadConversations() {
    try {
      final data = _storage.read(_storageKey);
      if (data is List && data.isNotEmpty) {
        final currentAvatar = TokenStoreLocal.getCurrentUserProfileImage();
        final currentUserId = TokenStoreLocal.getUserId();
        final currentUserName = TokenStoreLocal.getUser()?['username']?.toString() ?? '';

        final list = data
            .map((item) {
              var c = ChatConversationModel.fromJson(Map<String, dynamic>.from(item));
              // Backfill demo avatars or user avatar if null
              if (c.ownerAvatar == null || c.ownerAvatar!.trim().isEmpty) {
                if (c.ownerName.contains("សុខា")) {
                  c = c.copyWith(ownerAvatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150");
                } else if (c.ownerName.contains("គឹមសួរ")) {
                  c = c.copyWith(ownerAvatar: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150");
                } else if (currentAvatar != null && (c.ownerId == currentUserId || c.ownerName.toLowerCase() == currentUserName.toLowerCase())) {
                  c = c.copyWith(ownerAvatar: currentAvatar);
                }
              }
              if (c.studentAvatar == null || c.studentAvatar!.trim().isEmpty) {
                if (currentAvatar != null && (c.studentId == currentUserId || c.studentName.toLowerCase() == currentUserName.toLowerCase())) {
                  c = c.copyWith(studentAvatar: currentAvatar);
                } else if (c.studentName.contains("វឌ្ឍនៈ")) {
                  c = c.copyWith(studentAvatar: currentAvatar ?? "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150");
                }
              }
              return c;
            })
            .toList();
        conversations.assignAll(list);
        return;
      }
    } catch (e) {
      debugPrint("Error loading conversations: $e");
    }

    // Seed realistic default conversations if none exist
    _seedDefaultConversations();
  }

  void _saveConversations() {
    try {
      final jsonList = conversations.map((c) => c.toJson()).toList();
      _storage.write(_storageKey, jsonList);
    } catch (e) {
      debugPrint("Error saving conversations: $e");
    }
  }

  void saveConversations() {
    _saveConversations();
  }

  ChatConversationModel buildConversationModel({
    required String ownerId,
    required String ownerName,
    String? ownerAvatar,
    String? ownerPhone,
    int? propertyId,
    String? propertyName,
    int? roomId,
    String? roomNumber,
    double? roomPrice,
  }) {
    final user = TokenStoreLocal.getUser();
    final currentAvatar = TokenStoreLocal.getCurrentUserProfileImage();
    final studentId = TokenStoreLocal.getUserId().isNotEmpty ? TokenStoreLocal.getUserId() : "student_demo";
    final studentName = user != null && user['username'] != null ? user['username'].toString() : "និស្សិត (Student)";
    final studentPhone = user != null && user['phoneNumber'] != null ? user['phoneNumber'].toString() : "012 345 678";
    final convId = "conv_${ownerId}_${studentId}_${propertyId ?? 'gen'}";

    final effectiveStudentAvatar = TokenStoreLocal.isStudent() ? currentAvatar : null;
    final effectiveOwnerAvatar = ownerAvatar ?? (TokenStoreLocal.isOwner() ? currentAvatar : null);

    return ChatConversationModel(
      id: convId,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerAvatar: effectiveOwnerAvatar,
      ownerPhone: ownerPhone ?? "098 765 432",
      studentId: studentId,
      studentName: studentName,
      studentAvatar: effectiveStudentAvatar,
      studentPhone: studentPhone,
      propertyId: propertyId,
      propertyName: propertyName,
      roomId: roomId,
      roomNumber: roomNumber,
      roomPrice: roomPrice,
      lastMessage: "បានចាប់ផ្តើមការសន្ទនា",
      lastMessageTime: DateTime.now().toIso8601String(),
      studentUnreadCount: 0,
      ownerUnreadCount: 0,
      messages: [],
    );
  }

  ChatConversationModel buildDefaultDemoConversation() {
    return buildConversationModel(
      ownerId: "1",
      ownerName: "លោក សុខា (ម្ចាស់ផ្ទះ)",
      ownerAvatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
      propertyName: "Apartment Toul Kork",
      roomNumber: "01",
      roomPrice: 50.0,
    );
  }

  ChatConversationModel startOrGetConversation({
    required String ownerId,
    required String ownerName,
    String? ownerAvatar,
    String? ownerPhone,
    int? propertyId,
    String? propertyName,
    int? roomId,
    String? roomNumber,
    double? roomPrice,
    String? initialMessage,
  }) {
    final user = TokenStoreLocal.getUser();
    final currentAvatar = TokenStoreLocal.getCurrentUserProfileImage();
    final studentId = TokenStoreLocal.getUserId().isNotEmpty ? TokenStoreLocal.getUserId() : "student_demo";
    final studentName = user != null && user['username'] != null ? user['username'].toString() : "និស្សិត (Student)";
    final studentPhone = user != null && user['phoneNumber'] != null ? user['phoneNumber'].toString() : "012 345 678";

    final effectiveStudentAvatar = TokenStoreLocal.isStudent() ? currentAvatar : null;
    final effectiveOwnerAvatar = ownerAvatar ?? (TokenStoreLocal.isOwner() ? currentAvatar : null);

    // Build unique conversation key
    final convId = "conv_${ownerId}_${studentId}_${propertyId ?? 'gen'}";

    final existingIdx = conversations.indexWhere((c) => c.id == convId || (c.ownerId == ownerId && c.studentId == studentId && c.propertyId == propertyId));

    if (existingIdx != -1) {
      var conv = conversations[existingIdx];
      // Update property or room if provided
      conv = conv.copyWith(
        propertyName: propertyName ?? conv.propertyName,
        propertyId: propertyId ?? conv.propertyId,
        roomId: roomId ?? conv.roomId,
        roomNumber: roomNumber ?? conv.roomNumber,
        roomPrice: roomPrice ?? conv.roomPrice,
        studentAvatar: effectiveStudentAvatar ?? conv.studentAvatar,
        ownerAvatar: effectiveOwnerAvatar ?? conv.ownerAvatar,
      );
      conversations[existingIdx] = conv;
      _saveConversations();

      return conversations[existingIdx];
    }

    // Create new conversation
    final newConv = ChatConversationModel(
      id: convId,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerAvatar: effectiveOwnerAvatar,
      ownerPhone: ownerPhone ?? "098 765 432",
      studentId: studentId,
      studentName: studentName,
      studentAvatar: effectiveStudentAvatar,
      studentPhone: studentPhone,
      propertyId: propertyId,
      propertyName: propertyName,
      roomId: roomId,
      roomNumber: roomNumber,
      roomPrice: roomPrice,
      lastMessage: "បានចាប់ផ្តើមការសន្ទនា",
      lastMessageTime: DateTime.now().toIso8601String(),
      studentUnreadCount: 0,
      ownerUnreadCount: 0,
      messages: [],
    );

    conversations.insert(0, newConv);
    _saveConversations();

    return newConv;
  }

  void sendMessage(String conversationId, String text, {String? image, ChatConversationModel? fallbackConversation}) {
    var idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) {
      if (fallbackConversation != null) {
        conversations.insert(0, fallbackConversation);
        idx = 0;
      } else {
        return;
      }
    }

    final conv = conversations[idx];
    final isOwner = TokenStoreLocal.isOwner();
    final user = TokenStoreLocal.getUser();
    final currentUserId = TokenStoreLocal.getUserId();

    final senderRole = isOwner ? "OWNER" : "STUDENT";
    final senderId = currentUserId.isNotEmpty ? currentUserId : (isOwner ? conv.ownerId : conv.studentId);
    final senderName = user != null && user['username'] != null
        ? user['username'].toString()
        : (isOwner ? conv.ownerName : conv.studentName);

    final msg = ChatMessageModel(
      id: "msg_${DateTime.now().millisecondsSinceEpoch}",
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      text: text,
      imageUrl: image,
      timestamp: DateTime.now().toIso8601String(),
      isRead: false,
    );

    final updatedMessages = List<ChatMessageModel>.from(conv.messages)..add(msg);

    final updatedConv = conv.copyWith(
      lastMessage: text,
      lastMessageTime: msg.timestamp,
      studentUnreadCount: isOwner ? conv.studentUnreadCount + 1 : 0,
      ownerUnreadCount: isOwner ? 0 : conv.ownerUnreadCount + 1,
      messages: updatedMessages,
    );

    conversations.removeAt(idx);
    conversations.insert(0, updatedConv);
    _saveConversations();

    // If sent by student, simulate friendly owner auto-reply after a brief delay
    if (!isOwner) {
      _simulateOwnerReply(conversationId, conv, text);
    }
  }

  void _simulateOwnerReply(String conversationId, ChatConversationModel conv, String studentMessage) {
    Timer(const Duration(milliseconds: 1400), () {
      final currentIdx = conversations.indexWhere((c) => c.id == conversationId);
      if (currentIdx == -1) return;

      String replyText;
      final lower = studentMessage.toLowerCase();

      if (lower.contains("available") || lower.contains("ទំនេរ")) {
        replyText = "សួស្តីប្អូន! បន្ទប់ ${conv.roomNumber ?? 'នេះ'} នៅទំនេរទេបាទ។ ប្អូនអាចមកមើលផ្ទាល់បានគ្រប់ពេល!";
      } else if (lower.contains("visit") || lower.contains("មើល") || lower.contains("ថ្ងៃ")) {
        replyText = "បានបាទ! ខ្ញុំនៅផ្ទះរាល់ថ្ងៃចាប់ពីម៉ោង ៨ព្រឹក ដល់ ៧យប់។ ប្អូនអាចទូរស័ព្ទមកលេខខ្ញុំ ${conv.ownerPhone ?? '098 765 432'} បានមុនពេលមកដល់។";
      } else if (lower.contains("price") || lower.contains("ថ្លៃ") || lower.contains("ចុះ") || lower.contains("\$")) {
        replyText = "តម្លៃ \$${(conv.roomPrice ?? 50).toStringAsFixed(0)} ក្នុង១ខែ រួមបញ្ចូល Wifi រួចជាស្រេច។ បើប្អូនស្នាក់នៅយូរ យើងអាចពិភាក្សាសម្រួលបានខ្លះៗ!";
      } else if (lower.contains("water") || lower.contains("ភ្លើង") || lower.contains("ទឹក") || lower.contains("electric")) {
        replyText = "ថ្លៃភ្លើង 1000៛/kWh និងថ្លៃទឹក 2500៛/m³ គិតតាមកុងទ័រជាក់ស្តែងក្នុងបន្ទប់ប្អូនផ្ទាល់!";
      } else {
        replyText = "សួស្តីប្អូន! អរគុណដែលបានចាប់អារម្មណ៍ផ្ទះជួលរបស់យើងខ្ញុំ។ តើប្អូនមានចម្ងល់អ្វីបន្ថែមអំពីបន្ទប់នេះទេ?";
      }

      final replyMsg = ChatMessageModel(
        id: "msg_${DateTime.now().millisecondsSinceEpoch}",
        conversationId: conversationId,
        senderId: conv.ownerId,
        senderName: conv.ownerName,
        senderRole: "OWNER",
        text: replyText,
        timestamp: DateTime.now().toIso8601String(),
        isRead: false,
      );

      final liveConv = conversations[currentIdx];
      final newMsgs = List<ChatMessageModel>.from(liveConv.messages)..add(replyMsg);
      final isNowOwner = TokenStoreLocal.isOwner();

      final updated = liveConv.copyWith(
        lastMessage: replyText,
        lastMessageTime: replyMsg.timestamp,
        studentUnreadCount: isNowOwner ? liveConv.studentUnreadCount : liveConv.studentUnreadCount + 1,
        messages: newMsgs,
      );

      conversations.removeAt(currentIdx);
      conversations.insert(0, updated);
      _saveConversations();
    });
  }

  void markAsRead(String conversationId) {
    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;

    final conv = conversations[idx];
    final isOwner = TokenStoreLocal.isOwner();
    final currentUnread = isOwner ? conv.ownerUnreadCount : conv.studentUnreadCount;
    if (currentUnread == 0) return;

    final updated = conv.copyWith(
      studentUnreadCount: isOwner ? conv.studentUnreadCount : 0,
      ownerUnreadCount: isOwner ? 0 : conv.ownerUnreadCount,
    );

    conversations[idx] = updated;
    _saveConversations();
  }

  void deleteConversation(String conversationId) {
    conversations.removeWhere((c) => c.id == conversationId);
    _saveConversations();
  }

  void _seedDefaultConversations() {
    final now = DateTime.now();
    final currentAvatar = TokenStoreLocal.getCurrentUserProfileImage();

    final conv1 = ChatConversationModel(
      id: "conv_owner1_student_demo_1",
      ownerId: "1",
      ownerName: "លោក សុខា (ម្ចាស់ផ្ទះ)",
      ownerAvatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
      ownerPhone: "012 889 900",
      studentId: "student_demo",
      studentName: "វឌ្ឍនៈ (Student)",
      studentAvatar: currentAvatar ?? "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150",
      propertyId: 1,
      propertyName: "Apartment Toul Kork",
      roomId: 1,
      roomNumber: "01",
      roomPrice: 50.0,
      lastMessage: "សួស្តីប្អូន! បន្ទប់ 01 នៅទំនេរទេបាទ ប្អូនអាចមកមើលផ្ទាល់បានគ្រប់ពេលណា៎!",
      lastMessageTime: now.subtract(const Duration(minutes: 15)).toIso8601String(),
      studentUnreadCount: 1,
      ownerUnreadCount: 0,
      messages: [
        ChatMessageModel(
          id: "m1",
          conversationId: "conv_owner1_student_demo_1",
          senderId: "student_demo",
          senderName: "វឌ្ឍនៈ",
          senderAvatar: currentAvatar ?? "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150",
          senderRole: "STUDENT",
          text: "ជម្រាបសួរលោកពូ! ខ្ញុំចាប់អារម្មណ៍បន្ទប់ 01 តម្លៃ \$50/ខែ នៅ Apartment Toul Kork",
          timestamp: now.subtract(const Duration(minutes: 25)).toIso8601String(),
          isRead: true,
        ),
        ChatMessageModel(
          id: "m2",
          conversationId: "conv_owner1_student_demo_1",
          senderId: "student_demo",
          senderName: "វឌ្ឍនៈ",
          senderAvatar: currentAvatar ?? "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150",
          senderRole: "STUDENT",
          text: "តើបន្ទប់នេះនៅទំនេរទេបាទ?",
          timestamp: now.subtract(const Duration(minutes: 24)).toIso8601String(),
          isRead: true,
        ),
        ChatMessageModel(
          id: "m3",
          conversationId: "conv_owner1_student_demo_1",
          senderId: "1",
          senderName: "លោក សុខា (ម្ចាស់ផ្ទះ)",
          senderAvatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
          senderRole: "OWNER",
          text: "សួស្តីប្អូន! បន្ទប់ 01 នៅទំនេរទេបាទ ប្អូនអាចមកមើលផ្ទាល់បានគ្រប់ពេលណា៎!",
          timestamp: now.subtract(const Duration(minutes: 15)).toIso8601String(),
          isRead: false,
        ),
      ],
    );

    final conv2 = ChatConversationModel(
      id: "conv_owner2_student_demo_2",
      ownerId: "2",
      ownerName: "អ្នកស្រី គឹមសួរ (Sky View Condo)",
      ownerAvatar: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150",
      ownerPhone: "098 123 456",
      studentId: "student_demo",
      studentName: "វឌ្ឍនៈ (Student)",
      studentAvatar: currentAvatar ?? "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150",
      propertyId: 2,
      propertyName: "Sky View Condominium",
      roomId: 3,
      roomNumber: "302",
      roomPrice: 120.0,
      lastMessage: "ប្អូនអាចមកមើលបន្ទប់នៅថ្ងៃសៅរ៍នេះបានទេ?",
      lastMessageTime: now.subtract(const Duration(hours: 3)).toIso8601String(),
      studentUnreadCount: 0,
      ownerUnreadCount: 0,
      messages: [
        ChatMessageModel(
          id: "m4",
          conversationId: "conv_owner2_student_demo_2",
          senderId: "student_demo",
          senderName: "វឌ្ឍនៈ",
          senderAvatar: currentAvatar ?? "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150",
          senderRole: "STUDENT",
          text: "សួស្តីអ្នកមីង! តើថ្លៃអគ្គិសនី និងទឹកគិតយ៉ាងណាដែរ?",
          timestamp: now.subtract(const Duration(hours: 4)).toIso8601String(),
          isRead: true,
        ),
        ChatMessageModel(
          id: "m5",
          conversationId: "conv_owner2_student_demo_2",
          senderId: "2",
          senderName: "អ្នកស្រី គឹមសួរ (Sky View Condo)",
          senderAvatar: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150",
          senderRole: "OWNER",
          text: "ភ្លើង 900៛/kWh ទឹក 2000៛/m³ ចាស៎។ ប្អូនអាចមកមើលបន្ទប់នៅថ្ងៃសៅរ៍នេះបានទេ?",
          timestamp: now.subtract(const Duration(hours: 3)).toIso8601String(),
          isRead: true,
        ),
      ],
    );

    conversations.assignAll([conv1, conv2]);
    _saveConversations();
  }
}
