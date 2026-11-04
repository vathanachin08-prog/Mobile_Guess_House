import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../constants/constant_uri.dart';
import 'app_colors.dart';

class ServerConfigDialog extends StatefulWidget {
  final VoidCallback? onSaved;

  const ServerConfigDialog({super.key, this.onSaved});

  static void show(BuildContext context, {VoidCallback? onSaved}) {
    showDialog(
      context: context,
      builder: (_) => ServerConfigDialog(onSaved: onSaved),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ConstantUri.baseUri);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final targetUrl = _urlController.text.trim();
    try {
      final uri = Uri.parse(targetUrl.endsWith("/") ? targetUrl.substring(0, targetUrl.length - 1) : targetUrl);
      final testUri = uri.replace(path: "/actuator/health");
      final response = await http.get(testUri).timeout(const Duration(seconds: 4));

      setState(() {
        _isTesting = false;
        if (response.statusCode >= 200 && response.statusCode < 400) {
          _isSuccess = true;
          _testResult = "Connection successful! Server responded with HTTP ${response.statusCode}.";
        } else {
          _isSuccess = true; // server reachable
          _testResult = "Server reachable (HTTP ${response.statusCode}).";
        }
      });
    } catch (e) {
      // Try root ping
      try {
        final uri = Uri.parse(targetUrl);
        final res = await http.get(uri).timeout(const Duration(seconds: 3));
        setState(() {
          _isTesting = false;
          _isSuccess = true;
          _testResult = "Server reachable! (HTTP ${res.statusCode})";
        });
      } catch (err) {
        setState(() {
          _isTesting = false;
          _isSuccess = false;
          _testResult = "Connection failed: $err";
        });
      }
    }
  }

  void _applyPreset(String url) {
    setState(() {
      _urlController.text = url;
      _testResult = null;
    });
  }

  void _save() {
    final clean = _urlController.text.trim();
    if (clean.isNotEmpty) {
      ConstantUri.setBaseUri(clean);
      Get.back();
      Get.snackbar(
        'Server Updated',
        'Connected to $clean',
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
      widget.onSaved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.dns_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dynamic API Server',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Configure backend REST host & port',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Server URL Input
            const Text('Backend Base URL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'e.g. http://localhost:30033',
                prefixIcon: const Icon(Icons.link_rounded, size: 20, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () => _urlController.clear(),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Presets
            const Text('Quick Presets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip('💻 Localhost (30033)', 'http://localhost:30033'),
                _buildPresetChip('📱 Android (10.0.2.2:30033)', 'http://10.0.2.2:30033'),
                _buildPresetChip('🌐 LAN (10.10.1.153:30033)', 'http://10.10.1.153:30033'),
                _buildPresetChip('☁️ Cloud AWS (30033)', 'http://44.210.204.147:30033'),
              ],
            ),
            const SizedBox(height: 16),

            // Test Connection Status
            if (_testResult != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _isSuccess ? Colors.green.shade200 : Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      color: _isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isSuccess ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTesting ? null : _testConnection,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isTesting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Test Ping'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save & Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String url) {
    final isSelected = _urlController.text.trim() == url;
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
      backgroundColor: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: () => _applyPreset(url),
    );
  }
}

