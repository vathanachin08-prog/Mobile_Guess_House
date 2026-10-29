import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/constant_uri.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/language_service.dart';
import '../../../routes/app_route_name.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/owner_app_bar_helper.dart';
import '../owner_main_controller.dart';
import '../reviews/owner_reviews_view.dart';
import 'owner_dashboard_controller.dart';

class OwnerDashboardView extends StatefulWidget {
  final bool showHeaderInBody;
  const OwnerDashboardView({super.key, this.showHeaderInBody = false});

  @override
  State<OwnerDashboardView> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<OwnerDashboardView> {
  final OwnerDashboardController controller = Get.find<OwnerDashboardController>();
  final PageController _promoPageController = PageController();
  final ValueNotifier<int> _activePromoNotifier = ValueNotifier<int>(0);
  Timer? _promoAutoSlideTimer;
  bool _isInvoiceBannerVisible = false;
  Timer? _invoiceBannerShowTimer;
  Timer? _invoiceBannerHideTimer;
  Worker? _tabWorker;

  @override
  void initState() {
    super.initState();
    _startPromoAutoSlide();
    _startInvoiceBannerSchedule();

    if (Get.isRegistered<OwnerMainController>()) {
      _tabWorker = ever(Get.find<OwnerMainController>().currentIndex, (int index) {
        if (index == 0) {
          _startInvoiceBannerSchedule();
        } else {
          _invoiceBannerShowTimer?.cancel();
          _invoiceBannerHideTimer?.cancel();
          if (mounted && _isInvoiceBannerVisible) {
            setState(() {
              _isInvoiceBannerVisible = false;
            });
          }
        }
      });
    }
  }

  void _startInvoiceBannerSchedule() {
    _invoiceBannerShowTimer?.cancel();
    _invoiceBannerHideTimer?.cancel();
    if (mounted && _isInvoiceBannerVisible) {
      setState(() {
        _isInvoiceBannerVisible = false;
      });
    }

    // Wait 5 seconds, then show for 10 seconds, then close it
    _invoiceBannerShowTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _isInvoiceBannerVisible = true;
      });

      _invoiceBannerHideTimer = Timer(const Duration(seconds: 10), () {
        if (!mounted) return;
        setState(() {
          _isInvoiceBannerVisible = false;
        });
      });
    });
  }

  void _startPromoAutoSlide() {
    _promoAutoSlideTimer?.cancel();
    _promoAutoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_promoPageController.hasClients) return;
      final nextIndex = (_activePromoNotifier.value + 1) % 3;
      _promoPageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _tabWorker?.dispose();
    _invoiceBannerShowTimer?.cancel();
    _invoiceBannerHideTimer?.cancel();
    _promoAutoSlideTimer?.cancel();
    _promoPageController.dispose();
    _activePromoNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      LanguageService.currentLocale.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              await controller.loadDashboard();
            },
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Header (only rendered in body when showHeaderInBody is true)
                  if (widget.showHeaderInBody) ...[
                    _buildTopHeader(context),
                    const SizedBox(height: 16),
                  ],

                  // 2. Alert Banner (Orange Gradient Banner like ABA)
                  _buildAlertBanner(context),

                  // 3. Featured Account / Revenue Card (ABA Account/Savings Card style in clean white)
                  _buildMainAccountCard(context),

                  const SizedBox(height: 18),

                  // 4. Quick Services 3x2 Grid (6 Rounded White Surface Tiles like ABA)
                  _buildServicesGrid(context),

                  const SizedBox(height: 14),

                  // 5. 3 Horizontal Pill Action Buttons below Grid
                  _buildPillActionButtons(context),

                  // 6. Latest Pending Visit Request (if any)
                  if (controller.latestVisitRequest.value != null) ...[
                    const SizedBox(height: 18),
                    _buildPendingVisitCard(context),
                  ],

                  const SizedBox(height: 24),

                  // 7. "ដំណឹង & ប្រូម៉ូសិន" (News & Promotions) Section
                  _buildPromotionsSection(context),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ==========================================
  // 1. TOP HEADER (Avatar, Greeting, Actions)
  // ==========================================
  Widget _buildTopHeader(BuildContext context) {
    final ownerName = controller.ownerNameRx.value;
    final initial = ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'O';
    final hasAlert = controller.unpaidInvoices.value > 0 || controller.pendingVisitRequestsCount.value > 0;

    return Row(
      children: [
        // Avatar with status indicator ring
        GestureDetector(
          onTap: () => Get.find<OwnerMainController>().changeTab(5),
          child: Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00A86B), Color(0xFF10B981)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Obx(() => _buildAvatarImage(controller.profileImagePath.value, initial)),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: hasAlert ? AppColors.accentOrange : AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Greeting & Owner Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LanguageService.isKhmer ? "ទិវាសួស្តី!" : "Good day!",
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ownerName,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Action Icons Row (Chat, Bell with badge, Property switch, Language)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chat / Messages with Students
            _buildHeaderIconButton(
              icon: Icons.chat_bubble_outline_rounded,
              hasBadge: Get.isRegistered<ChatService>() && ChatService.to.totalUnreadCount > 0,
              onTap: () => Get.toNamed(AppRouteName.chatList),
            ),

            const SizedBox(width: 8),

            // Notification Bell with Badge
            _buildHeaderIconButton(
              icon: Icons.notifications_none_rounded,
              hasBadge: controller.pendingVisitRequestsCount.value > 0 || controller.unpaidInvoices.value > 0,
              onTap: () => OwnerAppBarHelper.showNotifications(context),
            ),

            const SizedBox(width: 8),

            // Property Picker Button
            _buildHeaderIconButton(
              icon: Icons.apartment_rounded,
              onTap: () => OwnerAppBarHelper.showPropertyPicker(context),
            ),

            const SizedBox(width: 8),

            // Language Switcher
            GestureDetector(
              onTap: () => LanguageService.toggleLanguage(showSnackbar: true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      LanguageService.isKhmer ? "🇰🇭" : "🇺🇸",
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      LanguageService.isKhmer ? "KH" : "EN",
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 19),
          ),
          if (hasBadge)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(String path, String initial) {
    if (path.isEmpty) {
      return _buildFallbackInitial(initial);
    }

    if (path.startsWith('data:image')) {
      try {
        final base64Part = path.split(',').last;
        return Image.memory(
          base64Decode(base64Part),
          fit: BoxFit.cover,
          width: 48,
          height: 48,
          errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(initial),
        );
      } catch (_) {
        return _buildFallbackInitial(initial);
      }
    }

    return Image.network(
      path,
      fit: BoxFit.cover,
      width: 48,
      height: 48,
      errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(initial),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildFallbackInitial(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  // ==========================================
  // 2. ALERT BANNER (Orange Gradient like ABA)
  // ==========================================
  Widget _buildAlertBanner(BuildContext context) {
    final hasUnpaid = controller.unpaidInvoices.value > 0;
    final hasPending = controller.pendingVisitRequestsCount.value > 0;

    // Only show alert banner if there is a real action required (unpaid bill or pending visit)
    if (!hasUnpaid && !hasPending) {
      return const SizedBox.shrink();
    }

    String title;
    String subtitle;
    VoidCallback onTap;

    if (hasUnpaid) {
      title = LanguageService.isKhmer
          ? "អ្នកមានវិក្កយបត្រមិនទាន់ទូទាត់ ${controller.unpaidInvoices.value} ច្បាប់"
          : "You have ${controller.unpaidInvoices.value} unpaid invoice(s)";
      subtitle = LanguageService.isKhmer
          ? "សូមពិនិត្យដើម្បីបន្តការគ្រប់គ្រង និងប្រមូលប្រាក់"
          : "Tap to review details and collect payments";
      onTap = () => Get.find<OwnerMainController>().changeTab(4);
    } else {
      title = LanguageService.isKhmer
          ? "មានសំណើណាត់ជួបថ្មី ${controller.pendingVisitRequestsCount.value} កំពុងរង់ចាំ"
          : "You have ${controller.pendingVisitRequestsCount.value} pending visit request(s)";
      subtitle = LanguageService.isKhmer
          ? "សូមឆ្លើយតបទៅកាន់និស្សិតដើម្បីបញ្ជាក់ការណាត់ជួប"
          : "Tap to review and confirm appointments";
      onTap = () => Get.toNamed(AppRouteName.ownerVisitRequests);
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      child: _isInvoiceBannerVisible
          ? AnimatedOpacity(
              opacity: _isInvoiceBannerVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9500), Color(0xFFFF5E00)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5E00).withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ==========================================
  // 3. MAIN ACCOUNT / REVENUE CARD (Building Background)
  // ==========================================
  Widget _buildMainAccountCard(BuildContext context) {
    return Obx(() {
      controller.currentProperty.value;
      if (Get.isRegistered<OwnerMainController>()) {
        Get.find<OwnerMainController>().selectedPropertyId.value;
      }
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // 1. Building Background Image (Watermarked with 80% transparency matching user request)
              Positioned.fill(
                child: _buildBuildingBackgroundImage(),
              ),

              // 2. Foreground Content in clean original ABA style
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onLongPress: () => _showBuildingImageSheet(context),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Balance with Eye Toggle + Photo Edit
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Balance + Eye Toggle
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: controller.toggleBalanceVisibility,
                                  child: controller.isBalanceHidden.value
                                      ? Container(
                                          height: 36,
                                          constraints: const BoxConstraints(minWidth: 135),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.white, width: 1.5),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(9),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                                alignment: Alignment.center,
                                                color: Colors.white.withValues(alpha: 0.45),
                                                child: ImageFiltered(
                                                  imageFilter: ImageFilter.blur(sigmaX: 9.0, sigmaY: 9.0),
                                                  child: Text(
                                                    "\$${controller.totalRevenue.value.toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey.shade400,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          "\$${controller.totalRevenue.value.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: controller.toggleBalanceVisibility,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Icon(
                                      controller.isBalanceHidden.value
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: AppColors.textSecondary,
                                      size: 17,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Quick Camera button to change building photo
                            // GestureDetector(
                            //   onTap: () => _showBuildingImageSheet(context),
                            //   child: Container(
                            //     padding: const EdgeInsets.all(6),
                            //     decoration: BoxDecoration(
                            //       color: AppColors.primarySoft.withValues(alpha: 0.92),
                            //       shape: BoxShape.circle,
                            //       border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                            //     ),
                            //     child: const Icon(
                            //       Icons.camera_alt_rounded,
                            //       color: AppColors.primary,
                            //       size: 15,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Subtitle Row
                        Row(
                          children: [
                            Text(
                              LanguageService.isKhmer
                                  ? "ចំណូលសរុបប្រចាំខែ • Revenue Collected"
                                  : "Total Monthly Collected Revenue",
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (controller.currentProperty.value == null) ...[
                              const Spacer(),
                              GestureDetector(
                                onTap: () => OwnerAppBarHelper.showPropertyPicker(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add_business_rounded, size: 11, color: AppColors.primary),
                                      const SizedBox(width: 3),
                                      Text(
                                        LanguageService.isKhmer ? "បង្កើតអគារ" : "Add Property",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 14),

                        // 3 Action Pills at bottom of card
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCardPillAction(
                              icon: Icons.south_west_rounded,
                              iconColor: AppColors.primary,
                              title: LanguageService.isKhmer ? "ទទួលលុយ" : "Invoices",
                              value: "\$${controller.totalRevenue.value.toStringAsFixed(0)}",
                              onTap: () => Get.find<OwnerMainController>().changeTab(4),
                            ),
                            Container(width: 1, height: 26, color: AppColors.divider),
                            _buildCardPillAction(
                              icon: Icons.people_alt_rounded,
                              iconColor: AppColors.primary,
                              title: LanguageService.isKhmer ? "អ្នកជួល" : "Tenants",
                              value: "${controller.totalTenants.value}",
                              onTap: () => Get.find<OwnerMainController>().changeTab(3),
                            ),
                            Container(width: 1, height: 26, color: AppColors.divider),
                            _buildCardPillAction(
                              icon: Icons.pie_chart_rounded,
                              iconColor: AppColors.primary,
                              title: LanguageService.isKhmer ? "អត្រាស្នាក់នៅ" : "Occupancy",
                              value: "${controller.occupancyRate.round()}%",
                              onTap: () => Get.find<OwnerMainController>().changeTab(2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Builds the building background image with 80% white transparency watermark effect
  /// Only renders if an actual property image exists; otherwise returns empty so card stays Clean White.
  Widget _buildBuildingBackgroundImage() {
    final prop = controller.currentProperty.value;
    final imageSource = controller.getBuildingImageSource(prop);

    if (imageSource == null || imageSource.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final src = imageSource.trim();
    Widget imgWidget;

    if (src.startsWith('assets/')) {
      imgWidget = Image.asset(
        src,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    } else if (src.startsWith('data:image')) {
      try {
        final base64Part = src.split(',').last;
        imgWidget = Image.memory(
          base64Decode(base64Part),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    } else {
      final fullUrl = src.startsWith('http')
          ? src
          : "${ConstantUri.baseUri}/api/public/view/image?filename=$src";
      imgWidget = Image.network(
        fullUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        imgWidget,
        // Apply 80% white transparency overlay so card text and numbers remain crystal clear
        Container(
          color: Colors.white.withValues(alpha: 0.80),
        ),
      ],
    );
  }

  /// Sheet to take photo with camera, choose from gallery, or reset building photo
  void _showBuildingImageSheet(BuildContext context) {
    final currentProp = controller.currentProperty.value;
    if (currentProp == null) {
      Get.snackbar(
        LanguageService.isKhmer ? "មិនទាន់មានអគារ" : "No Property Yet",
        LanguageService.isKhmer
            ? "សូមបង្កើតអគារ ឬផ្ទះជួលដំបូងរបស់អ្នកជាមុនសិន"
            : "Please create your first property first",
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        colorText: AppColors.textPrimary,
        icon: const Icon(Icons.apartment_rounded, color: AppColors.primary),
        mainButton: TextButton(
          onPressed: () {
            OwnerAppBarHelper.showPropertyPicker(context);
          },
          child: Text(
            LanguageService.isKhmer ? "បង្កើតអគារ" : "Create",
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    final propName = currentProp.name ?? (LanguageService.isKhmer ? "អគារ" : "Property");
    final hasCustomImg = controller.getBuildingImageSource(currentProp) != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    LanguageService.isKhmer ? "រូបភាពផ្ទៃខាងក្រោយអគារ" : "Building Background Photo",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                propName,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: Text(
                  LanguageService.isKhmer ? "ថតរូបអគារថ្មី (Camera)" : "Take New Photo (Camera)",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  LanguageService.isKhmer ? "ប្រើកាមេរ៉ាដើម្បីថតរូបអគារជាក់ស្តែង" : "Use camera to take real building photo",
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  controller.updateBuildingPhoto(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: Text(
                  LanguageService.isKhmer ? "ជ្រើសរើសពីរូបភាព (Gallery)" : "Choose from Gallery",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  LanguageService.isKhmer ? "ជ្រើសរើសរូបភាពអគារពីទូរស័ព្ទរបស់អ្នក" : "Select property photo from your gallery",
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  controller.updateBuildingPhoto(ImageSource.gallery);
                },
              ),
              if (hasCustomImg) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.refresh_rounded, color: AppColors.danger),
                  ),
                  title: Text(
                    LanguageService.isKhmer ? "កំណត់រូបដើមឡើងវិញ" : "Reset to Default Photo",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.danger),
                  ),
                  subtitle: Text(
                    LanguageService.isKhmer ? "ប្រើរូបភាពស្ថាបត្យកម្មដើម" : "Use default architectural photo",
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    controller.resetBuildingPhoto();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPillAction({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. SERVICES 3x2 GRID (6 Rounded Tiles)
  // ==========================================
  Widget _buildServicesGrid(BuildContext context) {
    final unpaid = controller.unpaidInvoices.value;
    final pending = controller.pendingVisitRequestsCount.value;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.08,
      children: [
        // 1. Floors
        _buildServiceTile(
          icon: Icons.layers_rounded,
          iconColor: AppColors.primary,
          label: LanguageService.isKhmer ? "ជាន់" : "Floors",
          subtitle: "${controller.totalFloors.value}",
          onTap: () => Get.find<OwnerMainController>().changeTab(1),
        ),

        // 2. Rooms
        _buildServiceTile(
          icon: Icons.meeting_room_rounded,
          iconColor: AppColors.primary,
          label: LanguageService.isKhmer ? "បន្ទប់" : "Rooms",
          subtitle: "${controller.totalRooms.value}",
          onTap: () => Get.find<OwnerMainController>().changeTab(2),
        ),

        // 3. Invoices
        _buildServiceTile(
          icon: Icons.receipt_long_rounded,
          iconColor: AppColors.primary,
          label: LanguageService.isKhmer ? "វិក្កយបត្រ" : "Invoices",
          subtitle: LanguageService.isKhmer ? "ទូទាត់" : "Payments",
          onTap: () => Get.find<OwnerMainController>().changeTab(4),
        ),

        // 4. Tenants
        _buildServiceTile(
          icon: Icons.people_alt_rounded,
          iconColor: AppColors.primary,
          label: LanguageService.isKhmer ? "អ្នកជួល" : "Tenants",
          subtitle: "${controller.totalTenants.value}",
          onTap: () => Get.find<OwnerMainController>().changeTab(3),
        ),

        // 5. Appointments / Visit Requests
        _buildServiceTile(
          icon: Icons.calendar_month_rounded,
          iconColor: AppColors.primary,
          label: LanguageService.isKhmer ? "ការណាត់ជួប" : "Appointments",
          subtitle: pending > 0 ? "$pending រង់ចាំ" : "កាលវិភាគ",
          badgeCount: pending > 0 ? pending : null,
          badgeColor: AppColors.danger,
          onTap: () => Get.toNamed(AppRouteName.ownerVisitRequests),
        ),

        // 6. Reviews & Ratings
        _buildServiceTile(
          icon: Icons.star_rounded,
          iconColor: AppColors.primary,
          label: LanguageService.isKhmer ? "ការវាយតម្លៃ" : "Reviews",
          subtitle: LanguageService.isKhmer ? "មតិយោបល់" : "Feedback",
          onTap: () => Get.to(() => const OwnerReviewsView()),
        ),
      ],
    );
  }

  Widget _buildServiceTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    int? badgeCount,
    Color badgeColor = AppColors.danger,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            if (badgeCount != null)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$badgeCount",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 5. 3 PILL ACTION BUTTONS BELOW GRID
  // ==========================================
  Widget _buildPillActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSmallPillButton(
            icon: Icons.add_home_work_rounded,
            label: LanguageService.isKhmer ? "បន្ថែមបន្ទប់" : "Add Room",
            onTap: () => Get.find<OwnerMainController>().changeTab(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSmallPillButton(
            icon: Icons.domain_add_rounded,
            label: LanguageService.isKhmer ? "បន្ថែមជាន់" : "Add Floor",
            onTap: () => Get.find<OwnerMainController>().changeTab(1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSmallPillButton(
            icon: Icons.tune_rounded,
            label: LanguageService.isKhmer ? "មីនុយច្រើនទៀត" : "More",
            hasBadge: true,
            onTap: () => _showMoreActionsBottomSheet(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: AppColors.primary, size: 16),
                if (hasBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 6. PENDING VISIT REQUEST QUICK ACTION
  // ==========================================
  Widget _buildPendingVisitCard(BuildContext context) {
    final latest = controller.latestVisitRequest.value!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_pin, color: AppColors.primary, size: 17),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${'student_tenant'.tr}: ${latest.studentName ?? 'not_specified'.tr}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ),
              if (latest.propertyName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    latest.propertyName!,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                "${latest.requestedDate ?? ''}  ${latest.requestedTime ?? ''}",
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              if (latest.studentPhone != null && latest.studentPhone!.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  latest.studentPhone!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
          if (latest.message != null && latest.message!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"${latest.message}"',
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (latest.id != null) {
                      controller.quickRejectVisitRequest(latest.id!);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                  child: Text('reject_visit'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (latest.id != null) {
                      controller.quickAcceptVisitRequest(latest.id!);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    elevation: 0,
                  ),
                  child: Text('accept_visit'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. PROMOTIONS / NEWS CAROUSEL SECTION
  // ==========================================
  Widget _buildPromotionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LanguageService.isKhmer ? "ដំណឹង & ប្រូម៉ូសិន" : "News & Promotions",
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                Get.snackbar(
                  LanguageService.isKhmer ? "ដំណឹងថ្មីៗ" : "News",
                  LanguageService.isKhmer
                      ? "គ្មានការផ្សព្វផ្សាយបន្ថែមនាពេលនេះទេ"
                      : "No further announcements right now",
                  backgroundColor: AppColors.surface,
                  colorText: AppColors.textPrimary,
                );
              },
              child: Text(
                LanguageService.isKhmer ? "មើលទាំងអស់" : "View All",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Carousel Banner Card
        SizedBox(
          height: 145,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification && notification.dragDetails != null) {
                // User is dragging manually: pause auto-slide
                _promoAutoSlideTimer?.cancel();
              } else if (notification is ScrollEndNotification) {
                // User finished drag: restart auto-slide smoothly
                _startPromoAutoSlide();
              }
              return false;
            },
            child: PageView(
              controller: _promoPageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                _activePromoNotifier.value = index;
              },
              children: [
                _buildPromoBannerCard(
                  tag: "KHQR",
                  title: LanguageService.isKhmer
                      ? "បង់ថ្លៃភ្លើង & ថ្លៃឈ្នួលតាម KHQR"
                      : "Pay Electricity & Rent with KHQR",
                  desc: LanguageService.isKhmer
                      ? "ងាយស្រួល រហ័ស និងមានសុវត្ថិភាព តាមរយៈគ្រប់ធនាគារក្នុងប្រទេសកម្ពុជា"
                      : "Fast, seamless and instant reconciliation via all Cambodian banks",
                  gradient: const [Color(0xFF065F46), Color(0xFF047857)],
                  accentColor: const Color(0xFF10B981),
                  icon: Icons.qr_code_scanner_rounded,
                ),
                _buildPromoBannerCard(
                  tag: "NEW",
                  title: LanguageService.isKhmer
                      ? "ស្វែងរកអ្នកជួល 10,000+ នាក់"
                      : "Reach 10,000+ University Students",
                  desc: LanguageService.isKhmer
                      ? "ផ្សព្វផ្សាយបន្ទប់ទំនេរដល់និស្សិតសាកលវិទ្យាល័យជិតអ្នកបំផុត"
                      : "Showcase your vacant rooms directly to nearby university students",
                  gradient: const [Color(0xFF312E81), Color(0xFF4338CA)],
                  accentColor: const Color(0xFF818CF8),
                  icon: Icons.school_rounded,
                ),
                _buildPromoBannerCard(
                  tag: "SMART",
                  title: LanguageService.isKhmer
                      ? "គ្រប់គ្រងកិច្ចសន្យា & វិក្កយបត្រស្វ័យប្រវត្តិ"
                      : "Automated Contracts & Billing",
                  desc: LanguageService.isKhmer
                      ? "កាត់បន្ថយពេលវេលា និងបង្កើនប្រសិទ្ធភាពចំណូលជួលរបស់អ្នក"
                      : "Save time with automatic monthly recurring invoice generation",
                  gradient: const [Color(0xFF92400E), Color(0xFFB45309)],
                  accentColor: const Color(0xFFFBBF24),
                  icon: Icons.electric_bolt_rounded,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Pagination Dots (Isolated via ValueListenableBuilder: does NOT trigger whole page rebuilds!)
        ValueListenableBuilder<int>(
          valueListenable: _activePromoNotifier,
          builder: (context, activeIndex, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isActive = activeIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPromoBannerCard({
    required String tag,
    required String title,
    required String desc,
    required List<Color> gradient,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient icon decoration
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              size: 80,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MORE ACTIONS BOTTOM SHEET
  // ==========================================
  void _showMoreActionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LanguageService.isKhmer ? "មុខងារគ្រប់គ្រងទាំងអស់" : "All Management Features",
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  LanguageService.isKhmer ? "ប្តូរអគារផ្ទះជួល" : "Switch Property",
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  OwnerAppBarHelper.showPropertyPicker(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  LanguageService.isKhmer ? "គ្រប់គ្រងវិក្កយបត្រ" : "Manage Invoices",
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Get.find<OwnerMainController>().changeTab(4);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  LanguageService.isKhmer ? "បញ្ជីឈ្មោះអ្នកជួល" : "Tenants List",
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Get.find<OwnerMainController>().changeTab(3);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings_outlined, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  LanguageService.isKhmer ? "ការកំណត់គណនី" : "Account Settings",
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Get.find<OwnerMainController>().changeTab(5);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
