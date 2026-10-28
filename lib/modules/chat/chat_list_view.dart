import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/language_service.dart';
import '../../data/local/token_store_local.dart';
import '../../models/chat/chat_model.dart';
import '../../routes/app_route_name.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/chat_avatar_widget.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final _chatService = Get.find<ChatService>();
  final _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "ALL"; // ALL, UNREAD

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = TokenStoreLocal.isOwner();

    return Obx(() {
      LanguageService.currentLocale.value;

      final allConversations = _chatService.conversations;

      // Filter by search & unread
      final filtered = allConversations.where((c) {
        final otherName = c.getOtherPartyName(isOwner).toLowerCase();
        final propName = (c.propertyName ?? '').toLowerCase();
        final lastMsg = c.lastMessage.toLowerCase();
        final query = _searchQuery.toLowerCase();

        final matchesSearch = query.isEmpty ||
            otherName.contains(query) ||
            propName.contains(query) ||
            lastMsg.contains(query);

        if (!matchesSearch) return false;

        if (_selectedFilter == "UNREAD") {
          return c.getUnreadCount(isOwner) > 0;
        }

        return true;
      }).toList();

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
            onPressed: () => Get.back(),
          ),
          title: Text(
            isOwner
                ? (LanguageService.isKhmer ? "សារជជែកពីសិស្ស" : "Student Inquiries")
                : (LanguageService.isKhmer ? "សារជជែកជាមួយម្ចាស់ផ្ទះ" : "Messages with Owners"),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
          ),
          actions: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Obx(() {
                  final totalUnread = _chatService.totalUnreadCount;
                  return Text(
                    totalUnread > 0
                        ? (LanguageService.isKhmer ? "$totalUnread សារថ្មី" : "$totalUnread unread")
                        : (LanguageService.isKhmer ? "${allConversations.length} ការសន្ទនា" : "${allConversations.length} chats"),
                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  );
                }),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar & Filter Chips
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              color: AppColors.surface,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: isOwner
                          ? (LanguageService.isKhmer ? "ស្វែងរកឈ្មោះសិស្ស ឬអចលនទ្រព្យ..." : "Search student or property...")
                          : (LanguageService.isKhmer ? "ស្វែងរកឈ្មោះម្ចាស់ផ្ទះ ឬអចលនទ្រព្យ..." : "Search owner or property..."),
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = "");
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFilterChip("ALL", LanguageService.isKhmer ? "ទាំងអស់ (${allConversations.length})" : "All (${allConversations.length})"),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        "UNREAD",
                        LanguageService.isKhmer
                            ? "មិនទាន់អាន (${_chatService.totalUnreadCount})"
                            : "Unread (${_chatService.totalUnreadCount})",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Conversation List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.forum_outlined, size: 40, color: AppColors.primary),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _searchQuery.isNotEmpty
                                ? (LanguageService.isKhmer ? "រកមិនឃើញការសន្ទនាទេ" : "No conversations found")
                                : (LanguageService.isKhmer ? "មិនទាន់មានការសន្ទនានៅឡើយទេ" : "No messages yet"),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              isOwner
                                ? (LanguageService.isKhmer
                                    ? "នៅពេលមានសិស្សផ្ញើសារសាកសួរអំពីបន្ទប់ សារនឹងបង្ហាញនៅទីនេះ"
                                    : "When students inquire about rooms, their chats will appear here")
                                : (LanguageService.isKhmer
                                    ? "ចុច 'ឆាតជាមួយម្ចាស់ផ្ទះ' លើទំព័រអចលនទ្រព្យ ឬបន្ទប់ ដើម្បីចាប់ផ្តើមជជែក"
                                    : "Tap 'Chat with Owner' on any property or room to start chatting"),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                            ),
                          ),
                          if (!isOwner && _searchQuery.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => Get.toNamed(AppRouteName.search),
                              icon: const Icon(Icons.search, size: 16),
                              label: Text(LanguageService.isKhmer ? "ស្វែងរកផ្ទះជួលឥឡូវនេះ" : "Browse Properties"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final conv = filtered[i];
                        return _buildConversationCard(conv, isOwner);
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationCard(ChatConversationModel conv, bool isOwner) {
    final otherName = conv.getOtherPartyName(isOwner);
    final currentUserAvatar = TokenStoreLocal.getCurrentUserProfileImage();
    final currentUserName = TokenStoreLocal.getUser()?['username']?.toString();
    final otherAvatar = conv.getOtherPartyAvatar(
      isOwner,
      currentUserAvatar: currentUserAvatar,
      currentUserName: currentUserName,
    );
    final unread = conv.getUnreadCount(isOwner);

    DateTime? dt;
    try {
      dt = DateTime.parse(conv.lastMessageTime);
    } catch (_) {}
    final timeStr = dt != null
        ? "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}"
        : "";

    return Dismissible(
      key: Key(conv.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      onDismissed: (_) => _chatService.deleteConversation(conv.id),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Get.toNamed(AppRouteName.chatDetail, arguments: conv);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: unread > 0 ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
            ),
            child: Row(
              children: [
                // Avatar with online status
                ChatAvatarWidget(
                  name: otherName,
                  avatarUrl: otherAvatar,
                  size: 48,
                  isOwner: isOwner,
                  showOnlineBadge: true,
                ),
                const SizedBox(width: 12),

                // Name, Property, Last Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              otherName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: unread > 0 ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Property / Room badge
                      if (conv.propertyName != null || conv.roomNumber != null) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                "${conv.propertyName ?? 'Room'}${conv.roomNumber != null ? ' • #${conv.roomNumber}' : ''}",
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conv.lastMessage,
                              style: TextStyle(
                                fontSize: 12,
                                color: unread > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$unread",
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ],
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
