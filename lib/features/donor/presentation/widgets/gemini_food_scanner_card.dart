import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/media_service.dart';
import '../../../../core/theme/app_colors.dart';

class GeminiFoodScannerCard extends StatefulWidget {
  final Function(FoodFreshnessScanResult result, String? imagePath) onScanComplete;

  const GeminiFoodScannerCard({
    super.key,
    required this.onScanComplete,
  });

  @override
  State<GeminiFoodScannerCard> createState() => _GeminiFoodScannerCardState();
}

class _GeminiFoodScannerCardState extends State<GeminiFoodScannerCard>
    with SingleTickerProviderStateMixin {
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  FoodFreshnessScanResult? _scanResult;
  late AnimationController _pulseAnimController;

  @override
  void initState() {
    super.initState();
    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final bool isTestMode =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTestMode) {
      _pulseAnimController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseAnimController.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(ImageSource source) async {
    final media = MediaService.instance;
    final XFile? file = source == ImageSource.camera
        ? await media.pickImageFromCamera()
        : await media.pickImageFromGallery();

    if (file == null && !mounted) return;

    setState(() {
      _selectedImage = file;
      _isAnalyzing = true;
    });

    final bool isTest =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    final path = file?.path ?? 'food_sample.jpg';
    final result = await AIService().scanFoodFreshness(imagePath: path);

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _scanResult = result;
      });
      widget.onScanComplete(result, file?.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _scanResult != null
              ? AppColors.primaryGreen
              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: _scanResult != null ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Gemini AI Food Scanner',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textDarkPrimary : AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Multimodal AI',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'कॅमेऱ्यातून अन्नाचा प्रकार, स्वच्छता व शेल्फ लाइफ तपासा',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.mutedGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_isAnalyzing) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseAnimController.value * 0.12),
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        color: AppColors.primaryGreen,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Gemini AI अन्न व पॅकिंग स्कॅन करत आहे...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'तपासत आहे: अन्नाचा प्रकार • सुरक्षित पॅकिंग • शेल्फ लाइफ',
                    style: TextStyle(fontSize: 11, color: AppColors.mutedGrey),
                  ),
                ],
              ),
            ),
          ] else if (_scanResult != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B).withOpacity(0.2) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_selectedImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 30,
                            height: 30,
                            color: AppColors.primaryGreen.withOpacity(0.15),
                            child: const Icon(Icons.photo_camera_back_outlined, size: 18, color: AppColors.primaryGreen),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        const Icon(Icons.verified, color: AppColors.primaryGreen, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          _scanResult!.foodTitle,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepGreen,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(_scanResult!.confidenceScore * 100).round()}% Verified',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    'तपासलेले अन्न घटक (Detected Food):',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mutedGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _scanResult!.detectedItems.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.shield_outlined, size: 14, color: AppColors.primaryGreen),
                                  SizedBox(width: 4),
                                  Text(
                                    'हायजीन तपासणी',
                                    style: TextStyle(fontSize: 10.5, color: AppColors.mutedGrey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _scanResult!.hygieneStatus,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.timer_outlined, size: 14, color: Color(0xFFD97706)),
                                  SizedBox(width: 4),
                                  Text(
                                    'सुरक्षित शेल्फ लाइफ',
                                    style: TextStyle(fontSize: 10.5, color: AppColors.mutedGrey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${_scanResult!.safeShelfLifeHours} तास (Hours)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _scanResult!.marathiSummary,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textDarkSecondary : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('पुन्हा स्कॅन करा (Rescan)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _handleCapture(ImageSource.camera),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('कॅमेऱ्याने स्कॅन करा'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _handleCapture(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('गॅलरीतून निवडा'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _handleCapture(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
