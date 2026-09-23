import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';

class OwnerMembershipView extends StatefulWidget {
  const OwnerMembershipView({super.key});

  @override
  State<OwnerMembershipView> createState() => _OwnerMembershipViewState();
}

class _OwnerMembershipViewState extends State<OwnerMembershipView> {
  String _selectedPlan = "STANDARD";

  void _upgradePlan(String planName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.workspace_premium, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 10),
            Text("ដំឡើង $planName", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("តើអ្នកចង់ដំឡើងគម្រោងទៅជា $planName មែនទេ?"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.qr_code_2, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "ទូទាត់ប្រាក់ងាយស្រួល និងរហ័សតាមរយៈ Bakong KHQR",
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("បោះបង់", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _selectedPlan = planName);
              Get.snackbar(
                "ជោគជ័យ",
                "អ្នកបានដំឡើងគម្រោងទៅ $planName ដោយជោគជ័យ!",
                backgroundColor: AppColors.primary,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(16),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("បង់ប្រាក់ឥឡូវនេះ"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        propertyName: "My Home",
        subtitle: "membership".tr,
        onPropertyTap: () {},
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.darkEmerald, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.star, color: Colors.amber, size: 24),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "កញ្ចប់សមាជិកភាព E-Home KH",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "ជ្រើសរើសគម្រោងដែលស័ក្តិសមបំផុតសម្រាប់អាជីវកម្មផ្ទះជួលរបស់អ្នកដើម្បីបង្កើនប្រសិទ្ធភាពគ្រប់គ្រង",
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Plan 1: Basic
            _buildPlanCard(
              title: "Basic (ឥតគិតថ្លៃ)",
              price: "\$0.00",
              period: "/ ជារៀងរហូត",
              isCurrent: _selectedPlan == "BASIC",
              isPopular: false,
              badgeText: null,
              features: [
                "គ្រប់គ្រងបន្ទប់រហូតដល់ 5 បន្ទប់",
                "កត់ត្រាព័ត៌មានអ្នកជួល",
                "បង្កើតវិក្កយបត្រសាមញ្ញ",
                "ការគាំទ្រតាមអ៊ីមែល",
              ],
              onTap: () {
                setState(() => _selectedPlan = "BASIC");
              },
            ),
            const SizedBox(height: 16),

            // Plan 2: Standard (Popular)
            _buildPlanCard(
              title: "Standard",
              price: "\$9.99",
              period: "/ ខែ",
              isCurrent: _selectedPlan == "STANDARD",
              isPopular: true,
              badgeText: "ពេញនិយមបំផុត",
              features: [
                "គ្រប់គ្រងបន្ទប់រហូតដល់ 20 បន្ទប់",
                "បង្កើត Bakong KHQR ដោយស្វ័យប្រវត្តិតាមវិក្កយបត្រ",
                "ផ្ញើវិក្កយបត្រតាម Telegram ទៅកាន់អ្នកជួល",
                "របាយការណ៍ចំណូល និងចំណាយលម្អិត",
                "ជំនួយបច្ចេកទេសរហ័ស 24/7",
              ],
              onTap: () => _upgradePlan("Standard"),
            ),
            const SizedBox(height: 16),

            // Plan 3: Premium
            _buildPlanCard(
              title: "Premium (គ្មានដែនកំណត់)",
              price: "\$19.99",
              period: "/ ខែ",
              isCurrent: _selectedPlan == "PREMIUM",
              isPopular: false,
              badgeText: "គ្មានដែនកំណត់",
              features: [
                "ចំនួនបន្ទប់មិនកំណត់",
                "គ្រប់គ្រងអគារ និងសាខាច្រើន (Multi-Property)",
                "គ្រប់គ្រងបុគ្គលិក និងកំណត់សិទ្ធិចូលប្រើប្រព័ន្ធ",
                "អាទិភាពបង្ហាញលើទំព័រដើមរបស់សិស្ស (Top Listing)",
                "នាំចេញទិន្នន័យរបាយការណ៍ជា Excel / PDF",
                "ជំនួយបច្ចេកទេសផ្ទាល់ខ្លួនពិសេស",
              ],
              onTap: () => _upgradePlan("Premium"),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required bool isCurrent,
    required bool isPopular,
    required String? badgeText,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? AppColors.primary
              : isPopular
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.border,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badgeText != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Text(
                badgeText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "កំពុងប្រើ",
                          style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      period,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: isCurrent ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent ? AppColors.border : AppColors.primary,
                      foregroundColor: isCurrent ? AppColors.textSecondary : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isCurrent ? "គម្រោងបច្ចុប្បន្ន" : "ជ្រើសរើសគម្រោង",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
