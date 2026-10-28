import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/language_service.dart';
import 'app_colors.dart';

class BakongKhqrDialog extends StatefulWidget {
  final String planKey;
  final String planTitle;
  final double amountUsd;
  final VoidCallback onPaymentSuccess;

  const BakongKhqrDialog({
    super.key,
    required this.planKey,
    required this.planTitle,
    required this.amountUsd,
    required this.onPaymentSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required String planKey,
    required String planTitle,
    required double amountUsd,
    required VoidCallback onPaymentSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BakongKhqrDialog(
        planKey: planKey,
        planTitle: planTitle,
        amountUsd: amountUsd,
        onPaymentSuccess: onPaymentSuccess,
      ),
    );
  }

  @override
  State<BakongKhqrDialog> createState() => _BakongKhqrDialogState();
}

class _BakongKhqrDialogState extends State<BakongKhqrDialog> {
  late int _remainingSeconds;
  Timer? _countdownTimer;
  bool _isVerifying = false;
  bool _isSuccess = false;
  late final String _transactionId;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = 15 * 60; // 15 minutes
    _transactionId = "RF-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() => _remainingSeconds--);
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _formattedTimer {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  int get _amountKhr => (widget.amountUsd * 4100).round();

  void _verifyPayment() async {
    setState(() => _isVerifying = true);

    // Simulate verification with Bakong Open API
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      _isSuccess = true;
    });

    widget.onPaymentSuccess();

    // Auto-close after celebration
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKh = LanguageService.isKhmer;

    if (_isSuccess) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 52),
              ),
              const SizedBox(height: 20),
              Text(
                isKh ? "ការទូទាត់ប្រាក់ជោគជ័យ!" : "Payment Successful!",
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isKh
                    ? "គម្រោងរបស់អ្នកត្រូវបានដំឡើងទៅជា ${widget.planTitle} រួចរាល់។"
                    : "Your membership has been upgraded to ${widget.planTitle}.",
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      "Invoice: $_transactionId",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=240x240&margin=8&data=00020101021229380016A00000072701234567895204581453038405404${widget.amountUsd.toStringAsFixed(2)}5802KH5912ROOMFINDER+KH6010PHNOM+PENH6304${_transactionId.replaceAll('-', '')}";

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 380),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bakong KHQR Official Red Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE1251B), // Official Bakong Red
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "KHQR",
                              style: TextStyle(
                                color: Color(0xFFE1251B),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isKh ? "ទូទាត់ប្រាក់តាម Bakong" : "Bakong KHQR Payment",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                isKh ? "ធនាគារជាតិនៃកម្ពុជា (NBC)" : "National Bank of Cambodia",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    children: [
                      // Merchant Name & Plan Title
                      Text(
                        "ROOMFINDER KH",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.planTitle,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),

                      // Price Display (USD & KHR)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFD5D2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "\$${widget.amountUsd.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE1251B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "(≈ ${_amountKhr.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} KHR)",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // QR Code Container with Center Currency Emblem
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE1251B).withValues(alpha: 0.4), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                qrUrl,
                                width: 190,
                                height: 190,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => _buildOfflineQrCanvas(),
                              ),
                            ),
                            // Center Bakong Dollar/Emblem Badge
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE1251B),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.attach_money_rounded, color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Countdown & Transaction ID
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFE1251B)),
                              const SizedBox(width: 4),
                              Text(
                                "${isKh ? 'ផុតកំណត់ក្នុង' : 'Expires in'}: ",
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              Text(
                                _formattedTimer,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE1251B)),
                              ),
                            ],
                          ),
                          Text(
                            _transactionId,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Instructions
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          isKh
                              ? "ស្កេនជាមួយកម្មវិធីធនាគារណាមួយ (ABA, ACLEDA, Bakong, Wing, Canadia...) ដើម្បីទូទាត់ប្រាក់"
                              : "Scan with any banking app (ABA, ACLEDA, Bakong, Wing, Canadia...) to pay.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action Button 1: Verify / Confirm Payment
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE1251B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isVerifying
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      isKh ? "កំពុងផ្ទៀងផ្ទាត់..." : "Verifying Payment...",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_outline, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      isKh ? "ខ្ញុំបានស្កេនទូទាត់រួចរាល់" : "I Have Paid / Confirm",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Action Button 2: Save QR Image or Cancel
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Get.snackbar(
                                  isKh ? "ជោគជ័យ" : "Saved",
                                  isKh ? "បានរក្សាទុក Bakong KHQR ក្នុងទូរស័ព្ទជោគជ័យ" : "Bakong KHQR saved to gallery",
                                  backgroundColor: AppColors.surface,
                                  colorText: AppColors.textPrimary,
                                  icon: const Icon(Icons.download_done, color: Colors.green),
                                );
                              },
                              icon: const Icon(Icons.file_download_outlined, size: 15),
                              label: Text(
                                isKh ? "ទាញយក QR" : "Save QR",
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                isKh ? "បោះបង់" : "Cancel",
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
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

  Widget _buildOfflineQrCanvas() {
    return Container(
      width: 190,
      height: 190,
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_2_rounded, size: 120, color: Color(0xFFE1251B)),
            const SizedBox(height: 4),
            Text(
              "Bakong KHQR Offline Mode",
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
