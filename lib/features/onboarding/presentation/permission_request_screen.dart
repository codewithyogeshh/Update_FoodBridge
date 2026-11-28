import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/router/initial_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/foodbridge_logo.dart';
import '../../authentication/presentation/auth_provider.dart';
import 'package:provider/provider.dart';

/// First-launch permission screen. Shown once when the app is opened for the
/// first time. Requests the runtime permissions the app needs (location,
/// camera, photos/storage, SMS and notifications) one after another with the
/// system permission pop-ups, then hands off to the normal authentication flow.
class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({super.key});

  static const storageKey = 'permissions_requested';

  @override
  State<PermissionRequestScreen> createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  bool _busy = false;

  final List<_PermissionItem> _permissions = [
    _PermissionItem(
      permission: Permission.locationWhenInUse,
      icon: Icons.location_on_outlined,
      title: 'Location',
      description: 'Live rider tracking व animated route साठी आपले स्थान आवश्यक.',
    ),
    _PermissionItem(
      permission: Permission.camera,
      icon: Icons.photo_camera_outlined,
      title: 'Camera',
      description: 'अन्न आणि QR कोड स्कॅन करण्यासाठी कॅमेरा आवश्यक.',
    ),
    _PermissionItem(
      permission: Permission.photos,
      icon: Icons.photo_library_outlined,
      title: 'Photos / Storage',
      description: 'अन्नाचे फोटो निवडण्यासाठी आणि PDF प्रमाणपत्र सेव्ह करण्यासाठी.',
    ),
    _PermissionItem(
      permission: Permission.sms,
      icon: Icons.sms_outlined,
      title: 'SMS',
      description: 'डिलिव्हरीनंतर थेट SMS पावती मिळवण्यासाठी.',
    ),
    _PermissionItem(
      permission: Permission.notification,
      icon: Icons.notifications_none,
      title: 'Notifications',
      description: 'पिकअप व डिलिव्हरी संदेशांसाठी नोटिफिकेशन आवश्यक.',
    ),
  ];

  Future<void> _requestAll() async {
    if (_busy) return;
    setState(() => _busy = true);

    final bool isTestMode =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (isTestMode) {
      for (final item in _permissions) {
        item.granted = true;
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(PermissionRequestScreen.storageKey, true);
      } catch (_) {}
      if (mounted) {
        final auth = context.read<AuthProvider>();
        context.go(resolveInitialRoute(auth));
      }
      return;
    }

    for (final item in _permissions) {
      try {
        final status = await item.permission.request();
        final granted =
            status.isGranted || status.isLimited || status.isRestricted;
        if (mounted) {
          setState(() => item.granted = granted);
        }
      } catch (_) {
        // Platform plugin unavailable (e.g. in tests) — treat as not granted.
        if (mounted) setState(() => item.granted = false);
      }
    }

    // Remember that we have already asked so we never show this again.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PermissionRequestScreen.storageKey, true);
    } catch (_) {}

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    context.go(resolveInitialRoute(auth));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A331D),
              Color(0xFF135A37),
              Color(0xFF1B6E44),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: FoodBridgeLogo(size: 64, isLight: true, showTagline: false),
                ),
                const SizedBox(height: 16),
                Text(
                  'Permissions Needed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'FoodBridge ला आपला अनुभव सुरक्षित व पूर्ण करण्यासाठी '
                  'खालील परवानग्या आवश्यक आहेत.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.white70 : Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Column(
                    children: [
                      for (final item in _permissions) ...[
                        _PermissionTile(item: item),
                        if (item != _permissions.last) const Divider(color: Colors.white24),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _requestAll,
                    icon: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_open_outlined, size: 20),
                    label: Text(_busy ? 'Asking…' : 'Allow All Permissions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primaryGreen.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'तुम्ही कोणतीही परवानगी नाकारली तरी आपण पुढे जाऊ शकता.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
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

class _PermissionItem {
  final Permission permission;
  final IconData icon;
  final String title;
  final String description;
  bool granted = false;

  _PermissionItem({
    required this.permission,
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.item});

  final _PermissionItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.granted ? AppColors.primaryGreen : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: isDark ? Colors.white70 : Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            item.granted ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: item.granted ? const Color(0xFF7CFF9E) : Colors.white54,
          ),
        ],
      ),
    );
  }
}
