import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/constant_uri.dart';
import 'web_url_launcher.dart';

class UrlService {
  /// Opens Telegram support link (defaults to [ConstantUri.telegramSupportUrl]).
  static Future<bool> openTelegram([String? url]) async {
    final targetUrl = (url != null && url.isNotEmpty)
        ? url
        : ConstantUri.telegramSupportUrl;
    return launchExternalUrl(targetUrl);
  }

  /// Opens an external URL safely across Web, Android, iOS, and Desktop.
  static Future<bool> launchExternalUrl(String urlString) async {
    try {
      // 1. If running on Flutter Web, use direct browser window opening
      // This bypasses browser popup blockers and works immediately without requiring
      // a dev server restart for the url_launcher_web plugin.
      if (kIsWeb) {
        final webSuccess = openUrlOnWeb(urlString);
        if (webSuccess) return true;
      }

      // 2. Mobile (Android/iOS) and Desktop native platforms
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return true;
    } catch (e) {
      debugPrint("Error launching URL ($urlString): $e");
      try {
        final uri = Uri.parse(urlString);
        return await launchUrl(uri);
      } catch (fallbackError) {
        debugPrint("Fallback URL launch failed: $fallbackError");
        Get.snackbar(
          "Telegram",
          "Could not open link: $urlString",
          backgroundColor: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    }
  }

  /// Sends invoice payment alert / reminder via Telegram
  static Future<bool> sendInvoiceToTelegram({
    required String tenantName,
    required String roomNumber,
    required double totalAmount,
    String? invoiceNo,
    String? dueDate,
  }) async {
    final message = "🔔 RoomFinder KH - Invoice Payment Alert\n\n"
        "👤 Tenant: $tenantName\n"
        "🚪 Room: $roomNumber\n"
        "${invoiceNo != null && invoiceNo.isNotEmpty ? '🧾 Invoice: $invoiceNo\n' : ''}"
        "💰 Total Due: \$${totalAmount.toStringAsFixed(2)}\n"
        "${dueDate != null && dueDate.isNotEmpty ? '📅 Due Date: $dueDate\n' : ''}"
        "⚠️ Status: UNPAID\n\n"
        "Please complete the payment on time. Thank you!";
    final encoded = Uri.encodeComponent(message);
    final targetUrl = "${ConstantUri.telegramSupportUrl}?text=$encoded";
    return openTelegram(targetUrl);
  }

  /// Sends an SMS payment reminder to tenant's phone number
  static Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uriStr = "sms:$cleanPhone?body=${Uri.encodeComponent(message)}";
    return launchExternalUrl(uriStr);
  }

  /// Initiates a phone call to tenant
  static Future<bool> makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uriStr = "tel:$cleanPhone";
    return launchExternalUrl(uriStr);
  }
}
