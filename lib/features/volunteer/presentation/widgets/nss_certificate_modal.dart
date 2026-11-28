import 'package:flutter/material.dart';
import '../../../../core/services/volunteer_gamification_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Modal for the NSS / College volunteer service certificate with live
/// gamification metrics and a PDF download/print action.
class NssCertificateModal extends StatelessWidget {
  final VolunteerKarmaSummary summary;
  final String collegeName;

  const NssCertificateModal({
    super.key,
    required this.summary,
    this.collegeName = '',
  });

  static Future<void> show(BuildContext context, VolunteerKarmaSummary summary, {String collegeName = ''}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NssCertificateModal(summary: summary, collegeName: collegeName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school, color: AppColors.primaryGreen, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NSS / College Volunteer Certificate',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.charcoal,
                        ),
                      ),
                      Text(
                        'विद्यार्थी स्वयंसेवक सेवा प्रमाणपत्र',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textDarkSecondary : AppColors.mutedGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : const Color(0xFFF9FDF9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text(
                    'राष्ट्रीय सेवा योजना (NSS) • FOODBRIDGE',
                    style: TextStyle(
                      letterSpacing: 1.2,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'VOLUNTEER SERVICE CERTIFICATE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Presented with official civic recognition to',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary.volunteerName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  Container(
                    width: 160,
                    height: 1.2,
                    color: const Color(0xFFD97706),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  Text(
                    'या विद्यार्थ्याने ${summary.totalHours} तास स्वयंसेवक म्हणून काम करून ${summary.totalMeals} भुकेल्यांपर्यंत अन्न पोहोचवले (${summary.totalDeliveries} डिलिव्हरी).',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                  if (collegeName.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Verify College: $collegeName',
                      style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.mutedGrey),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox(
                          icon: Icons.timer,
                          color: AppColors.primaryGreen,
                          value: '${summary.totalHours} h',
                          label: 'Hours Served',
                        ),
                        _buildStatBox(
                          icon: Icons.local_shipping,
                          color: Colors.blueAccent,
                          value: '${summary.totalDeliveries}',
                          label: 'Deliveries',
                        ),
                        _buildStatBox(
                          icon: Icons.restaurant,
                          color: const Color(0xFFB45309),
                          value: '${summary.totalMeals}',
                          label: 'Meals',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Karma Points: ${summary.karmaPoints}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.mutedGrey),
                      ),
                      Text(
                        'Rank #${summary.rank}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text(
                'Download / Print Official PDF',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              onPressed: () async {
                await VolunteerGamificationService.generateNssCertificatePdf(
                  summary: summary,
                  collegeName: collegeName,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('प्रमाणपत्र तयार झाले! (Certificate generated)'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.mutedGrey, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
