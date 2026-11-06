import 'package:device_preview/device_preview.dart';
import 'package:device_preview/presets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class IosDevicePreviewToolbar extends StatefulWidget {
  const IosDevicePreviewToolbar({super.key});

  @override
  State<IosDevicePreviewToolbar> createState() => _IosDevicePreviewToolbarState();
}

class _IosDevicePreviewToolbarState extends State<IosDevicePreviewToolbar> {
  Orientation _orientation = Orientation.portrait;

  final List<Map<String, dynamic>> _iosDevices = [
    {'name': 'iPhone 16 Pro', 'category': 'iPhone', 'preset': DevicePresets.iPhone16Pro, 'icon': Icons.phone_iphone_rounded},
    {'name': 'iPhone 16 Pro Max', 'category': 'iPhone', 'preset': DevicePresets.iPhone16ProMax, 'icon': Icons.phone_iphone_rounded},
    {'name': 'iPhone 16', 'category': 'iPhone', 'preset': DevicePresets.iPhone16, 'icon': Icons.phone_iphone_rounded},
    {'name': 'iPhone 16 Plus', 'category': 'iPhone', 'preset': DevicePresets.iPhone16Plus, 'icon': Icons.phone_iphone_rounded},
    {'name': 'iPhone 17 Pro Max', 'category': 'iPhone', 'preset': DevicePresets.iPhone17ProMax, 'icon': Icons.phone_iphone_rounded},
    {'name': 'iPhone SE (3rd Gen)', 'category': 'iPhone', 'preset': DevicePresets.iPhoneSe3, 'icon': Icons.phone_iphone_rounded},
    {'name': 'iPad Pro 13" (M4)', 'category': 'iPad', 'preset': DevicePresets.iPadPro13M4, 'icon': Icons.tablet_mac_rounded},
    {'name': 'iPad Air 11" (M4)', 'category': 'iPad', 'preset': DevicePresets.iPadAir11M4, 'icon': Icons.tablet_mac_rounded},
    {'name': 'iPad Mini', 'category': 'iPad', 'preset': DevicePresets.iPadMini, 'icon': Icons.tablet_mac_rounded},
    {'name': 'iPad 10th Gen', 'category': 'iPad', 'preset': DevicePresets.iPad10, 'icon': Icons.tablet_mac_rounded},
  ];

  void _showDeviceSelector(BuildContext context) {
    final controller = DevicePreview.maybeController;
    if (controller == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.apple, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'iOS Device Preview (Web)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Controls Row (Orientation & Reset)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() {
                          _orientation = _orientation == Orientation.portrait
                              ? Orientation.landscape
                              : Orientation.portrait;
                        });
                        await controller.setOrientation(_orientation);
                      },
                      icon: const Icon(Icons.screen_rotation_rounded, size: 16, color: Colors.white),
                      label: Text(
                        _orientation == Orientation.portrait ? 'Landscape' : 'Portrait',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await controller.reset();
                      },
                      icon: const Icon(Icons.fullscreen_rounded, size: 16, color: Colors.amber),
                      label: const Text(
                        'Full Window',
                        style: TextStyle(color: Colors.amber, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.amber),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),
              const Text(
                'SELECT AN APPLE DEVICE',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _iosDevices.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = _iosDevices[index];
                    final preset = item['preset'] as DevicePreset;
                    final isCurrent = controller.simulation?.presetId == preset.id;

                    return Material(
                      color: isCurrent ? const Color(0xFF334155) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          item['icon'] as IconData,
                          color: isCurrent ? Colors.greenAccent : Colors.white70,
                          size: 20,
                        ),
                        title: Text(
                          item['name'] as String,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${preset.portraitSize.width.toInt()} x ${preset.portraitSize.height.toInt()} pt • @${preset.devicePixelRatio.toInt()}x',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        trailing: isCurrent
                            ? const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isCurrent ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.transparent,
                          ),
                        ),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await controller.applyPreset(preset, orientation: _orientation);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    final controller = DevicePreview.maybeController;
    if (controller == null) return const SizedBox.shrink();

    return Positioned(
      top: 14,
      right: 14,
      child: SafeArea(
        child: Material(
          elevation: 6,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () => _showDeviceSelector(context),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.apple, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'iOS Preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.tune_rounded, color: Colors.white70, size: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
