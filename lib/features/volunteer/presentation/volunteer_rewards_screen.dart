import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/volunteer_gamification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/delivery_truck_illustration.dart';
import '../../../core/widgets/golden_trophy_illustration.dart';
import '../../authentication/presentation/auth_provider.dart';
import '../../donations/presentation/donation_provider.dart';
import 'widgets/nss_certificate_modal.dart';
import 'widgets/volunteer_bottom_nav.dart';

/// Screen 8: Volunteer Rewards & Badges Screen
/// Matches Bottom Row Screen 4 of reference mockup, enhanced with live
/// gamification (karma points, leaderboard, NSS/College certificate).
class VolunteerRewardsScreen extends StatefulWidget {
  const VolunteerRewardsScreen({super.key});

  @override
  State<VolunteerRewardsScreen> createState() => _VolunteerRewardsScreenState();
}

class _VolunteerRewardsScreenState extends State<VolunteerRewardsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final donationProvider = context.watch<DonationProvider>();
    final auth = context.watch<AuthProvider>();
    final volunteerId = auth.user?.id ?? 'usr-vol-301';

    final liveSummary = VolunteerGamificationService.summaryFor(
      allDonations: donationProvider.allDonations,
      volunteerId: volunteerId,
      volunteerName: auth.user?.fullName ?? 'Volunteer',
    );
    // Build a volunteer-name lookup from the live delivery ledger so the
    // leaderboard shows real names instead of generic placeholders.
    final volunteerNames = <String, String>{};
    final selfName = auth.user?.fullName.trim();
    if (selfName != null && selfName.isNotEmpty) {
      volunteerNames[volunteerId] = selfName;
    }
    for (final d in donationProvider.allDonations) {
      final vid = d.assignedVolunteerId?.trim();
      final vname = d.assignedVolunteerName?.trim();
      if (vid != null && vid.isNotEmpty && vname != null && vname.isNotEmpty) {
        volunteerNames.putIfAbsent(vid, () => vname);
      }
    }
    final leaderboard = VolunteerGamificationService.leaderboard(
      allDonations: donationProvider.allDonations,
      volunteerNames: volunteerNames,
    );

    final hasLiveData = liveSummary.totalDeliveries > 0;
    final karmaPoints = hasLiveData ? liveSummary.karmaPoints : 485;
    final hours = hasLiveData ? liveSummary.totalHours : 72;
    final earnedCount = hasLiveData ? liveSummary.badgesEarned.length : 4;
    final badges = hasLiveData
        ? liveSummary.badgesEarned
        : const ['First Rescue', 'Community Hero', 'Speedy Deliverer', 'Zero Waste Champion'];
    final myRank = leaderboard.isNotEmpty
        ? leaderboard.firstWhere(
            (l) => l.volunteerId == volunteerId,
            orElse: () => leaderboard.first,
          ).rank
        : 1;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAF9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/volunteer'),
        ),
        title: const Text(
          'Rewards',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Top Hero Trophy Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const GoldenTrophyIllustration(size: 130),
                  const SizedBox(height: 12),
                  const Text(
                    'Keep Helping, Keep Growing!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.deepGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your contributions unlock special volunteer milestones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.mutedGrey),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeroStat(
                        label: 'Karma Points',
                        value: '$karmaPoints',
                        icon: Icons.stars,
                        color: AppColors.primaryGreen,
                      ),
                      _buildHeroStat(
                        label: 'Your Rank',
                        value: '#$myRank',
                        icon: Icons.leaderboard,
                        color: const Color(0xFFD97706),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Next Badge Progress Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E5),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.orange, width: 2),
                        ),
                        child: const Icon(Icons.military_tech, color: AppColors.orange, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Badge',
                            style: TextStyle(fontSize: 11, color: AppColors.mutedGrey, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '100 Hours Club',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progress', style: TextStyle(fontSize: 12, color: AppColors.mutedGrey)),
                      Text(
                        '$hours / 100 h',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (hours / 100).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: const Color(0xFFEAF8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // "Your Badges" Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Badges',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepGreen,
                  ),
                ),
                Text(
                  '$earnedCount Earned',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Badges Row (Live badges when available)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < badges.length && i < 4; i++)
                  _buildBadgeItem(
                    icon: _badgeIcon(badges[i]),
                    iconColor: _badgeColor(badges[i]),
                    borderColor: _badgeColor(badges[i]),
                    label: badges[i].replaceAll(' ', '\n'),
                    isDark: isDark,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Leaderboard Section (Live Gamification)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Leaderboard 🏆',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepGreen,
                  ),
                ),
                Text(
                  'This Month',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (leaderboard.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No deliveries yet — complete your first mission to climb the board!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.mutedGrey),
                      ),
                    )
                  else
                    ..._buildLeaderboardRows(leaderboard, volunteerId, auth.user?.fullName ?? 'Volunteer', isDark),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // NSS / College Certificate Action
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E824C), Color(0xFF0F4D2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NSS / College Certificate',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'विद्यार्थी स्वयंसेवक सेवा प्रमाणपत्र',
                              style: TextStyle(fontSize: 12, color: Color(0xFFD4EDDA)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text(
                        'Generate NSS Certificate (PDF)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _openNssCertificate(context, liveSummary, hasLiveData),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Motivation Banner: "Volunteer Today... Build a Hunger-Free Tomorrow"
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F4D2E), // Deep emerald
                    Color(0xFF1E824C), // Primary green
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Volunteer Today...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Build a Hunger-Free Tomorrow',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFD4EDDA),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 70,
                    height: 50,
                    child: DeliveryTruckIllustration(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const VolunteerBottomNav(currentIndex: 4),
    );
  }

  List<Widget> _buildLeaderboardRows(
    List<VolunteerKarmaSummary> board,
    String volunteerId,
    String selfName,
    bool isDark,
  ) {
    final top = board.take(5).toList();
    return [
      for (int i = 0; i < top.length; i++)
        _buildLeaderboardRow(top[i], i + 1, volunteerId, selfName, i < top.length - 1, isDark),
    ];
  }

  Widget _buildLeaderboardRow(
    VolunteerKarmaSummary entry,
    int rank,
    String volunteerId,
    String selfName,
    bool showDivider,
    bool isDark,
  ) {
    final isMe = entry.volunteerId == volunteerId;
    final displayName = isMe ? selfName : (entry.volunteerName.isNotEmpty ? entry.volunteerName : 'Volunteer #$rank');
    final Color rankColor;
    switch (rank) {
      case 1:
        rankColor = const Color(0xFFD97706);
        break;
      case 2:
        rankColor = const Color(0xFF94A3B8);
        break;
      case 3:
        rankColor = const Color(0xFFB45309);
        break;
      default:
        rankColor = AppColors.primaryGreen;
    }

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: rankColor, width: 1.5),
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: rankColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isMe ? AppColors.primaryGreen : AppColors.charcoal,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'You',
                      style: TextStyle(fontSize: 11, color: AppColors.mutedGrey),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars, size: 15, color: AppColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.karmaPoints}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepGreen,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${entry.totalDeliveries} deliveries',
                  style: const TextStyle(fontSize: 11, color: AppColors.mutedGrey),
                ),
              ],
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _openNssCertificate(
    BuildContext context,
    VolunteerKarmaSummary liveSummary,
    bool hasLiveData,
  ) async {
    final collegeController = TextEditingController();
    final summary = hasLiveData
        ? liveSummary
        : VolunteerKarmaSummary(
            volunteerId: 'usr-vol-301',
            volunteerName: 'FoodBridge Volunteer',
            totalDeliveries: 18,
            totalMeals: 500,
            totalClothingItems: 0,
            totalHours: 72,
            karmaPoints: 485,
            badgesEarned: const ['First Rescue', 'Community Hero', 'Speedy Deliverer', 'Zero Waste Champion'],
            rank: 1,
          );

    final collegeName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: const Text('NSS / College Certificate'),
          content: TextField(
            controller: collegeController,
            decoration: const InputDecoration(
              labelText: 'College / University Name',
              hintText: 'e.g. Sinhgad College',
              prefixIcon: Icon(Icons.school),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.primaryAccentDark : AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, collegeController.text.trim()),
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );

    if (collegeName == null || !context.mounted) return;
    await NssCertificateModal.show(context, summary, collegeName: collegeName);
  }

  Widget _buildHeroStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.mutedGrey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  IconData _badgeIcon(String badge) {
    final lower = badge.toLowerCase();
    if (lower.contains('rescue')) return Icons.favorite;
    if (lower.contains('hero')) return Icons.handshake;
    if (lower.contains('speedy')) return Icons.star;
    if (lower.contains('zero')) return Icons.eco;
    if (lower.contains('gold')) return Icons.military_tech;
    if (lower.contains('hours')) return Icons.schedule;
    return Icons.emoji_events;
  }

  Color _badgeColor(String badge) {
    final lower = badge.toLowerCase();
    if (lower.contains('rescue')) return const Color(0xFFE74C3C);
    if (lower.contains('hero')) return const Color(0xFF2980B9);
    if (lower.contains('speedy')) return const Color(0xFFF39C12);
    if (lower.contains('zero')) return AppColors.primaryGreen;
    if (lower.contains('gold')) return const Color(0xFFD97706);
    if (lower.contains('hours')) return const Color(0xFF7C3AED);
    return AppColors.primaryGreen;
  }

  Widget _buildBadgeItem({
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required String label,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: iconColor, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: isDark ? Colors.white : AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}
