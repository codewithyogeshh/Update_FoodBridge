import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/certificate_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/donation.dart';

class FoodHeroCertificateModal extends StatelessWidget {
  final Donation donation;

  const FoodHeroCertificateModal({
    super.key,
    required this.donation,
  });

  static Future<void> show(BuildContext context, Donation donation) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodHeroCertificateModal(donation: donation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metrics = CertificateService.instance.calculateImpact(donation);
    final dateStr = DateFormat('dd MMM yyyy').format(donation.deliveredAt ?? DateTime.now());

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium, color: AppColors.primaryGreen, size: 24),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Food Hero Certificate',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textDarkPrimary : AppColors.charcoal,
                          ),
                        ),
                        Text(
                          'पर्यावरण व सामाजिक प्रभाव प्रमाणपत्र',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.mutedGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                    'FOODBRIDGE ZERO HUNGER ALLIANCE',
                    style: TextStyle(
                      letterSpacing: 1.5,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'CERTIFICATE OF SOCIAL IMPACT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Presented with gratitude to',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    donation.donorName,
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
                    'फूडब्रिज नेटवर्कद्वारे ${donation.claimedByNgoName ?? "आशा आश्रमास"} ${donation.quantity.toStringAsFixed(0)} ${donation.unit} "${donation.title}" यशस्वीरित्या सुपूर्द करण्यात आले.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
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
                          icon: Icons.eco,
                          color: AppColors.primaryGreen,
                          value: '${metrics.co2SavedKg} kg',
                          label: 'CO₂ Averted',
                        ),
                        _buildStatBox(
                          icon: Icons.people,
                          color: Colors.blueAccent,
                          value: '${metrics.peopleNourished}',
                          label: 'Nourished',
                        ),
                        _buildStatBox(
                          icon: Icons.water_drop,
                          color: Colors.cyan,
                          value: '${metrics.waterSavedLiters} L',
                          label: 'Water Saved',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cert ID: ${metrics.certificateId}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.mutedGrey),
                      ),
                      Text(
                        'Date: $dateStr',
                        style: const TextStyle(fontSize: 10, color: AppColors.mutedGrey),
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
                'Download / Print Official PDF (प्रमाणपत्र डाउनलोड)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              onPressed: () async {
                await CertificateService.instance.shareOrPrintCertificate(donation);
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
