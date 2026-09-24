import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/firebase_service.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/button_custom_widget.dart';

class OwnerPricingView extends StatefulWidget {
  const OwnerPricingView({super.key});

  @override
  State<OwnerPricingView> createState() => _OwnerPricingViewState();
}

class _OwnerPricingViewState extends State<OwnerPricingView> {
  final _rentPriceController = TextEditingController(text: "120.00");
  final _electricityController = TextEditingController(text: "1000");
  final _waterController = TextEditingController(text: "1500");
  final _garbageController = TextEditingController(text: "2.00");
  late final TextEditingController _exchangeRateController;
  final _accountNameController = TextEditingController(text: "CHIN VATHANA");
  final _accountNumberController = TextEditingController(text: "098765432");

  String _qrType = "DYNAMIC"; // DYNAMIC or STATIC
  bool _isLoading = false;
  bool _isFetchingRemoteConfig = false;

  @override
  void initState() {
    super.initState();
    // 1. Initialize directly from Firebase Remote Config
    _exchangeRateController = TextEditingController(
      text: AppFirebaseService.exchangeRate.toString(),
    );
    // 2. Fetch fresh update from Firebase Remote Config server
    _syncRemoteConfig();
  }

  Future<void> _syncRemoteConfig() async {
    setState(() => _isFetchingRemoteConfig = true);
    await AppFirebaseService.fetchRemoteConfig();
    if (mounted) {
      setState(() {
        _isFetchingRemoteConfig = false;
        _exchangeRateController.text = AppFirebaseService.exchangeRate.toString();
      });
      Get.snackbar(
        "Firebase Remote Config",
        "អត្រាប្តូរប្រាក់បច្ចុប្បន្នពី Firebase: ${AppFirebaseService.exchangeRate} ៛",
        backgroundColor: AppColors.primarySoft,
        colorText: AppColors.primary,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  void dispose() {
    _rentPriceController.dispose();
    _electricityController.dispose();
    _waterController.dispose();
    _garbageController.dispose();
    _exchangeRateController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    setState(() => _isLoading = true);
    final rentPrice = double.tryParse(_rentPriceController.text.trim()) ?? 0.0;
    AppFirebaseService.logPricingSettingsForm(
      rentPrice: rentPrice,
      electricity: _electricityController.text.trim(),
      water: _waterController.text.trim(),
      exchangeRate: _exchangeRateController.text.trim(),
      success: true,
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Get.snackbar(
          "ជោគជ័យ",
          "ការកំណត់តម្លៃ និង KHQR ត្រូវបានរក្សាទុកដោយជោគជ័យ",
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        propertyName: "My Home",
        subtitle: "settings".tr,
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
            // Title Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ការកំណត់តម្លៃ និងសេវាកម្ម",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "កំណត់ថ្លៃបន្ទប់ អគ្គិសនី ទឹក និង QR Code",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card 1: Utility Rates & Base Rent
            Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.monetization_on_outlined, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "ថ្លៃបន្ទប់ និងថ្លៃសេវាប្រចាំខែ",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Base room price
                    _buildInputField(
                      label: "ថ្លៃបន្ទប់មូលដ្ឋាន (\$/ខែ)",
                      hint: "120.00",
                      controller: _rentPriceController,
                      prefixIcon: Icons.home_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 14),

                    // Electricity
                    _buildInputField(
                      label: "ថ្លៃអគ្គិសនី (៛/kWh)",
                      hint: "1000",
                      controller: _electricityController,
                      prefixIcon: Icons.bolt,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),

                    // Water
                    _buildInputField(
                      label: "ថ្លៃទឹកស្អាត (៛/m³)",
                      hint: "1500",
                      controller: _waterController,
                      prefixIcon: Icons.water_drop_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),

                    // Garbage
                    _buildInputField(
                      label: "ថ្លៃសំរាម (\$/ខែ)",
                      hint: "2.00",
                      controller: _garbageController,
                      prefixIcon: Icons.delete_outline,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 14),

                    // Exchange Rate with Firebase Remote Config indicator
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "អត្រាប្តូរប្រាក់ (1\$ = ៛)",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            InkWell(
                              onTap: _syncRemoteConfig,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _isFetchingRemoteConfig
                                        ? const SizedBox(
                                            width: 11,
                                            height: 11,
                                            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                                          )
                                        : const Icon(Icons.cloud_sync_outlined, size: 13, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Firebase: ${AppFirebaseService.exchangeRate}៛",
                                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _exchangeRateController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "5000",
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.currency_exchange, color: AppColors.primary, size: 18),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
                              tooltip: "ទាញយកពី Firebase Remote Config ឡើងវិញ",
                              onPressed: _syncRemoteConfig,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card 2: Payment QR Code
            Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.qr_code_2, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "វិធីសាស្ត្រទូទាត់ប្រាក់ (Bakong KHQR)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Radio Selection
                    RadioListTile<String>(
                      value: "DYNAMIC",
                      groupValue: _qrType,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Dynamic KHQR (ស្វ័យប្រវត្តិតាមវិក្កយបត្រ)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text("បង្កើត QR Code ដោយស្វ័យប្រវត្តិតាមចំនួនទឹកប្រាក់ជាក់ស្តែងក្នុងវិក្កយបត្រ", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      onChanged: (val) => setState(() => _qrType = val!),
                    ),
                    RadioListTile<String>(
                      value: "STATIC",
                      groupValue: _qrType,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Static KHQR (រូបភាព QR ថេរ)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text("ប្រើរូបភាព KHQR ថេររបស់ម្ចាស់ផ្ទះសម្រាប់អ្នកជួលស្កេនបង់ប្រាក់", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      onChanged: (val) => setState(() => _qrType = val!),
                    ),
                    const SizedBox(height: 14),

                    // Account Name
                    _buildInputField(
                      label: "ឈ្មោះគណនី Bakong / ធនាគារ",
                      hint: "e.g. CHIN VATHANA",
                      controller: _accountNameController,
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 14),

                    // Account Number / Bakong ID
                    _buildInputField(
                      label: "លេខទូរស័ព្ទ ឬ Bakong ID",
                      hint: "e.g. 098765432@aba",
                      controller: _accountNumberController,
                      prefixIcon: Icons.account_balance_wallet_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Static QR Upload Container (Matching Reference UI Photo 2)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 36),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "ចុចដើម្បីប្តូរ ឬបង្ហោះរូបភាព QR Code Bakong",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "គាំទ្រប្រភេទ PNG, JPG (ទំហំអតិបរមា 5MB)",
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Get.snackbar(
                                "បង្ហោះរូបភាព",
                                "បានជ្រើសរើសរូបភាព Bakong KHQR ជោគជ័យ",
                                backgroundColor: AppColors.surface,
                                colorText: AppColors.textPrimary,
                                snackPosition: SnackPosition.BOTTOM,
                                margin: const EdgeInsets.all(16),
                              );
                            },
                            icon: const Icon(Icons.upload_file, size: 16, color: AppColors.primary),
                            label: const Text("ជ្រើសរើសឯកសារ", style: TextStyle(color: AppColors.primary, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ButtonCustomWidget(
              title: "រក្សាទុកការកំណត់",
              isLoading: _isLoading,
              icon: Icons.save_outlined,
              onPressed: _saveSettings,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 18),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
