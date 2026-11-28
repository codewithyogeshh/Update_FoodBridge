import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/app_update_service.dart';
import '../theme/app_colors.dart';

/// Modal dialog that informs users about a new release and offers 1-tap in-app download and update.
class AppUpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
  });

  /// Static helper to prompt the dialog if an update is available.
  static Future<void> showIfAvailable(
    BuildContext context, {
    bool showToastIfUpToDate = false,
  }) async {
    final bool isTestMode =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (isTestMode && !showToastIfUpToDate) return;

    final info = await AppUpdateService.instance.checkForUpdate();
    if (!context.mounted) return;

    if (info != null && info.hasUpdate) {
      await showDialog(
        context: context,
        barrierDismissible: !info.isMandatory,
        builder: (ctx) => AppUpdateDialog(updateInfo: info),
      );
    } else if (showToastIfUpToDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('आपले ॲप आधीच अद्ययावत (Latest Version) आहे!'),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';
  File? _downloadedFile;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusText = 'डाऊनलोड सुरू होत आहे...';
    });

    final file = await AppUpdateService.instance.downloadApk(
      apkUrl: widget.updateInfo.apkDownloadUrl,
      onProgress: (prog, received, total) {
        if (!mounted) return;
        setState(() {
          _progress = prog;
          if (total > 0) {
            final recMb = (received / (1024 * 1024)).toStringAsFixed(1);
            final totMb = (total / (1024 * 1024)).toStringAsFixed(1);
            final percent = (prog * 100).clamp(0, 100).toInt();
            _statusText = '$percent% डाऊनलोड झाले ($recMb MB / $totMb MB)';
          } else {
            final recMb = (received / (1024 * 1024)).toStringAsFixed(1);
            _statusText = '$recMb MB डाऊनलोड झाले...';
          }
        });
      },
    );

    if (!mounted) return;

    if (file != null) {
      setState(() {
        _isDownloading = false;
        _downloadedFile = file;
        _statusText = 'डाऊनलोड पूर्ण! आता इन्स्टॉल करा.';
      });
      // Automatically trigger package installer
      await AppUpdateService.instance.installApk(file);
    } else {
      setState(() {
        _isDownloading = false;
        _statusText = 'डाऊनलोड अयशस्वी. कृपया ब्राउझरमधून डाऊनलोड करा.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = widget.updateInfo;

    return PopScope(
      canPop: !info.isMandatory && !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top glowing update emblem
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF10B981),
                        Color(0xFF059669),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              const Text(
                'नवीन अपडेट उपलब्ध आहे! 🚀',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepGreen,
                ),
              ),
              const SizedBox(height: 6),

              // Version Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'v${info.latestVersion} उपलब्ध (चालू: v${info.currentVersion})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Release notes / description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'या अपडेटमधील नवीन सुधारणा:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.releaseNotes.isNotEmpty
                          ? info.releaseNotes
                          : 'नवीन अचूक ट्रॅकिंग, वेगवान कार्यक्षमता आणि बग फिक्सेस.',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark ? Colors.white70 : AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Download Progress State
              if (_isDownloading || _statusText.isNotEmpty) ...[
                if (_isDownloading)
                  LinearProgressIndicator(
                    value: _progress >= 0 ? _progress : null,
                    backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                const SizedBox(height: 8),
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedGrey,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Actions
              if (_downloadedFile != null) ...[
                ElevatedButton.icon(
                  onPressed: () => AppUpdateService.instance.installApk(_downloadedFile!),
                  icon: const Icon(Icons.install_mobile, color: Colors.white),
                  label: const Text(
                    'आत्ता इन्स्टॉल करा (Install Now)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ] else if (!_isDownloading) ...[
                ElevatedButton.icon(
                  onPressed: _startDownload,
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  label: const Text(
                    'थेट ॲपमध्ये अपडेट करा (1-Tap Update)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      AppUpdateService.instance.launchDownloadInBrowser(info.apkDownloadUrl),
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: const Text('ब्राउझरमधून डाऊनलोड करा'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                if (!info.isMandatory) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('नंतर करा (Later)'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
