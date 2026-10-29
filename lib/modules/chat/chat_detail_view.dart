import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/language_service.dart';
import '../../data/local/token_store_local.dart';
import '../../models/chat/chat_model.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/chat_avatar_widget.dart';
import '../student/visit_requests/request_visit_dialog.dart';

class ChatDetailView extends StatefulWidget {
  const ChatDetailView({super.key});

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  final _chatService = Get.find<ChatService>();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late String _conversationId;
  ChatConversationModel? _conversation;

  @override
  void initState() {
    super.initState();
    _setupInitialConversation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_conversationId.isNotEmpty) {
        _chatService.markAsRead(_conversationId);
      }
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupInitialConversation() {
    final args = Get.arguments;

    if (args is ChatConversationModel) {
      _conversation = args;
      _conversationId = args.id;
    } else if (args is Map) {
      final ownerId = args['ownerId']?.toString() ?? '1';
      final propertyId = args['propertyId'] is int ? args['propertyId'] : int.tryParse(args['propertyId']?.toString() ?? '');
      final studentId = TokenStoreLocal.getUserId().isNotEmpty ? TokenStoreLocal.getUserId() : "student_demo";
      final computedId = args['conversationId']?.toString() ?? "conv_${ownerId}_${studentId}_${propertyId ?? 'gen'}";

      final existingIdx = _chatService.conversations.indexWhere((c) => c.id == computedId || (c.ownerId == ownerId && c.studentId == studentId && c.propertyId == propertyId));
      if (existingIdx != -1) {
        _conversation = _chatService.conversations[existingIdx];
        _conversationId = _conversation!.id;
      } else {
        _conversation = _chatService.buildConversationModel(
          ownerId: ownerId,
          ownerName: args['ownerName']?.toString() ?? 'Owner',
          ownerAvatar: args['ownerAvatar']?.toString(),
          ownerPhone: args['ownerPhone']?.toString(),
          propertyId: propertyId,
          propertyName: args['propertyName']?.toString(),
          roomId: args['roomId'] is int ? args['roomId'] : int.tryParse(args['roomId']?.toString() ?? ''),
          roomNumber: args['roomNumber']?.toString(),
          roomPrice: args['roomPrice'] is num ? (args['roomPrice'] as num).toDouble() : double.tryParse(args['roomPrice']?.toString() ?? ''),
        );
        _conversationId = _conversation!.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_chatService.conversations.every((c) => c.id != _conversationId)) {
            _chatService.conversations.insert(0, _conversation!);
            _chatService.saveConversations();
          }
        });
      }

      if (args['initialMessage'] != null && args['initialMessage'].toString().isNotEmpty) {
        _textController.text = args['initialMessage'].toString();
      }
    } else {
      if (_chatService.conversations.isNotEmpty) {
        _conversation = _chatService.conversations.first;
        _conversationId = _conversation!.id;
      } else {
        _conversation = _chatService.buildDefaultDemoConversation();
        _conversationId = _conversation!.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_chatService.conversations.isEmpty) {
            _chatService.conversations.add(_conversation!);
            _chatService.saveConversations();
          }
        });
      }
    }
  }

  void _sendMessage([String? textToSend]) {
    final text = (textToSend ?? _textController.text).trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(_conversationId, text, fallbackConversation: _conversation);
    if (textToSend == null) {
      _textController.clear();
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCallDialog(String name, String phone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.phone_rounded, color: Colors.green, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                LanguageService.isKhmer ? "ទូរស័ព្ទទៅកាន់" : "Call",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_iphone_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    phone,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LanguageService.isKhmer ? "បិទ" : "Close"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Get.snackbar(
                LanguageService.isKhmer ? "កំពុងតេស្តខល..." : "Calling...",
                "$name ($phone)",
                backgroundColor: Colors.green.shade50,
                colorText: Colors.green.shade900,
                icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.green),
              );
            },
            icon: const Icon(Icons.call, size: 16),
            label: Text(LanguageService.isKhmer ? "ខលឥឡូវនេះ" : "Call Now"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = TokenStoreLocal.isOwner();

    return Obx(() {
      LanguageService.currentLocale.value;

      final currentConv = _chatService.conversations.firstWhere(
        (c) => c.id == _conversationId,
        orElse: () => _conversation ?? (_chatService.conversations.isNotEmpty ? _chatService.conversations.first : _chatService.buildDefaultDemoConversation()),
      );

      final currentUserAvatar = TokenStoreLocal.getCurrentUserProfileImage();
      final currentUserName = TokenStoreLocal.getUser()?['username']?.toString();
      final otherPartyName = currentConv.getOtherPartyName(isOwner);
      final otherPartyAvatar = currentConv.getOtherPartyAvatar(
        isOwner,
        currentUserAvatar: currentUserAvatar,
        currentUserName: currentUserName,
      );
      final otherPartyPhone = currentConv.getOtherPartyPhone(isOwner) ?? "098 765 432";
      final messages = currentConv.messages;

      // Quick questions for students to ask owners
      final quickQuestions = [
        LanguageService.isKhmer ? "បន្ទប់នេះនៅទំនេរទេបាទ?" : "Is this room still available?",
        LanguageService.isKhmer ? "តើខ្ញុំអាចមកមើលផ្ទាល់នៅថ្ងៃណាបាន?" : "When can I come to view it?",
        LanguageService.isKhmer ? "តើថ្លៃបន្ទប់អាចចុះបានខ្លះទេ?" : "Is the monthly rent negotiable?",
        LanguageService.isKhmer ? "ថ្លៃទឹក និងភ្លើងគិតយ៉ាងណាដែរ?" : "How are water and electricity charged?",
      ];

      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
            onPressed: () => Get.back(),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              ChatAvatarWidget(
                name: otherPartyName,
                avatarUrl: otherPartyAvatar,
                size: 40,
                isOwner: isOwner,
                showOnlineBadge: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherPartyName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOwner
                              ? (LanguageService.isKhmer ? "និស្សិតចាប់អារម្មណ៍" : "Interested Student")
                              : (LanguageService.isKhmer ? "ម្ចាស់អចលនទ្រព្យ • កំពុងមានវត្តមាន" : "Property Owner • Online"),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone_rounded, size: 18, color: Colors.green),
              ),
              tooltip: LanguageService.isKhmer ? "ខលទូរស័ព្ទ" : "Call",
              onPressed: () => _showCallDialog(otherPartyName, otherPartyPhone),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Property / Room Context Banner
            if (currentConv.propertyName != null || currentConv.roomNumber != null)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.meeting_room_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentConv.propertyName ?? "អចលនទ្រព្យ",
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              if (currentConv.roomNumber != null) ...[
                                Text(
                                  "${'room_label_prefix'.tr} ${currentConv.roomNumber}",
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (currentConv.roomPrice != null) ...[
                                Text(
                                  "\$${currentConv.roomPrice!.toStringAsFixed(0)} / mo",
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isOwner) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => RequestVisitDialog(
                              propertyId: currentConv.propertyId ?? 1,
                              roomId: currentConv.roomId,
                              roomNumber: currentConv.roomNumber,
                              propertyName: currentConv.propertyName ?? "Property",
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_month_outlined, size: 13),
                        label: Text(
                          LanguageService.isKhmer ? "ស្នើទស្សនា" : "Visit",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Message List
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            LanguageService.isKhmer ? "ចាប់ផ្តើមការសន្ទនា" : "Start Conversation",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            LanguageService.isKhmer
                                ? "សួរសំណួរអំពីតម្លៃ បន្ទប់ ឬកំណត់ពេលមកមើល"
                                : "Ask about price, room features, or schedule a visit",
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = messages[i];
                        final isMyMessage = isOwner
                            ? msg.senderRole == "OWNER"
                            : msg.senderRole == "STUDENT";

                        final effectiveMsg = msg.senderAvatar == null
                            ? msg.copyWith(
                                senderAvatar: msg.senderRole == "OWNER"
                                    ? currentConv.ownerAvatar
                                    : (currentConv.studentAvatar ?? (isMyMessage ? currentUserAvatar : null)),
                              )
                            : msg;

                        return _buildMessageBubble(effectiveMsg, isMyMessage);
                      },
                    ),
            ),

            // Quick Questions (For Students)
            if (!isOwner) ...[
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: quickQuestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final q = quickQuestions[idx];
                    return ActionChip(
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      label: Text(
                        q,
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                      ),
                      onPressed: () => _sendMessage(q),
                    );
                  },
                ),
              ),
            ],

            // Bottom Input Bar
            Container(
              padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLines: 4,
                              minLines: 1,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary, size: 20),
                            tooltip: LanguageService.isKhmer ? "ផ្ញើរូបភាព" : "Attach photo",
                            onPressed: () {
                              _sendMessage(LanguageService.isKhmer ? "📷 [បានផ្ញើរូបភាព]" : "📷 [Sent a photo]");
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    DateTime? dt;
    try {
      dt = DateTime.parse(msg.timestamp);
    } catch (_) {}
    final timeStr = dt != null
        ? "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}"
        : "";

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        border: isMe ? null : Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            msg.text,
            style: TextStyle(
              fontSize: 13.5,
              color: isMe ? Colors.white : AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 9.5,
                  color: isMe ? Colors.white.withValues(alpha: 0.75) : AppColors.textSecondary,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.done_all_rounded,
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (isMe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Align(
          alignment: Alignment.centerRight,
          child: bubble,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ChatAvatarWidget(
            name: msg.senderName,
            avatarUrl: msg.senderAvatar,
            size: 28,
            isOwner: msg.senderRole == "OWNER",
          ),
          const SizedBox(width: 8),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}
