import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/exit_confirmation_dialog.dart';
import '../../../core/widgets/donation_image_widget.dart';
import '../../../core/widgets/fb_appearance_selector.dart';
import '../../../core/utils/avatar_image_helper.dart';
import '../../../core/widgets/fb_empty_state.dart';
import '../../../core/widgets/fb_status_chip.dart';
import '../../authentication/presentation/auth_provider.dart';
import '../../authentication/presentation/widgets/terms_and_conditions_modal.dart';
import '../../donations/domain/models/donation.dart';
import '../../donations/presentation/donation_provider.dart';
import '../../donations/presentation/widgets/food_hero_certificate_modal.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TermsAndConditionsModal.showIfNeeded(context);
    });
  }

  void _showDonationTypeSheet(BuildContext context) {
    final tr = context.tr;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.newDonation,
                style: Theme.of(sheetCtx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose category to proceed with specific safety and handling guidelines.',
                style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(color: AppColors.mutedGrey),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.primaryGreen.withOpacity(0.4)),
                ),
                tileColor: AppColors.primaryGreen.withOpacity(0.06),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.soup_kitchen, color: Colors.white),
                ),
                title: Text(tr.donateFood, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(tr.get('donate_food_sub')),
                trailing: const Icon(Icons.chevron_right, color: AppColors.primaryGreen),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  context.push('/donate-food');
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.orange.withOpacity(0.4)),
                ),
                tileColor: AppColors.orange.withOpacity(0.06),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.checkroom, color: Colors.white),
                ),
                title: Text(tr.donateClothes, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(tr.get('donate_clothes_sub')),
                trailing: const Icon(Icons.chevron_right, color: AppColors.orange),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  context.push('/donate-clothes');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final donationProvider = context.watch<DonationProvider>();
    final currentUser = auth.user;

    final myDonations = donationProvider.getDonationsByDonor(
      currentUser?.id ?? 'usr-donor-101',
    );

    return FoodBridgeExitScope(
      child: Scaffold(
      appBar: AppBar(
        title: Text(tr.donorDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: tr.language,
            onPressed: () => showLanguageBottomSheet(context),
          ),
          IconButton(
            icon: Icon(themeProvider.appearanceIcon),
            tooltip: tr.appearance,
            onPressed: () => showAppearanceBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: tr.notifications,
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: AvatarImageHelper.resolve(currentUser?.avatarUrl) != null
                ? CircleAvatar(
                    radius: 13,
                    backgroundColor: Colors.transparent,
                    backgroundImage: AvatarImageHelper.resolve(currentUser?.avatarUrl),
                  )
                : const Icon(Icons.account_circle_outlined),
            tooltip: tr.profile,
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(tr.newDonation),
        onPressed: () => _showDonationTypeSheet(context),
      ),
      body: RefreshIndicator(
        onRefresh: () => donationProvider.refreshDonations(),
        color: AppColors.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : null,
                gradient: isDark
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.deepGreen, AppColors.primaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: isDark ? Border.all(color: AppColors.borderDark) : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${currentUser?.fullName ?? "Donor"}!',
                    style: TextStyle(
                      color: isDark ? AppColors.textDarkPrimary : AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser?.organizationName ?? 'Community Donor Member',
                    style: TextStyle(
                      color: isDark ? AppColors.textDarkSecondary : AppColors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr.appTagline,
                    style: TextStyle(
                      color: isDark ? AppColors.textDarkSecondary : AppColors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroBadge(
                        icon: Icons.verified_user_outlined,
                        label: 'Verified Community',
                        isDark: isDark,
                      ),
                      _HeroBadge(
                        icon: Icons.bolt,
                        label: 'Instant Sync',
                        isDark: isDark,
                      ),
                      _HeroBadge(
                        icon: Icons.favorite_outline,
                        label: 'Zero Hunger',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Donation Action Buttons
            Text(
              tr.get('create_donation'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    title: tr.donateFood,
                    subtitle: 'Cooked, groceries, bakery',
                    icon: Icons.soup_kitchen_outlined,
                    color: AppColors.primaryGreen,
                    onTap: () => context.push('/donate-food'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    title: tr.donateClothes,
                    subtitle: 'Wearable, clean garments',
                    icon: Icons.checkroom_outlined,
                    color: AppColors.orange,
                    onTap: () => context.push('/donate-clothes'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Live Network Sync Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.mintLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.primaryGreen.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Instant Multi-Device Sync Active • Connected',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDarkPrimary : AppColors.deepGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Donations Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${tr.myDonations} (${myDonations.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/donor/my-donations'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (myDonations.isEmpty)
              FBEmptyState(
                title: 'No Active Donations',
                description: 'You haven\'t posted any food or clothing donations yet.',
                icon: Icons.volunteer_activism_outlined,
                actionLabel: tr.newDonation,
                onAction: () => _showDonationTypeSheet(context),
              )
            else
              ...myDonations.map((donation) {
                final dateFormat = DateFormat('EEE, d MMM - hh:mm a');
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push('/donation-detail/${donation.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: DonationImageWidget(
                                    imageUrl: donation.imageUrl,
                                    isFood: donation.isFood,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      donation.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${donation.quantity.toStringAsFixed(0)} ${donation.unit} • ${donation.city}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.mutedGrey),
                                    ),
                                  ],
                                ),
                              ),
                              FBStatusChip(
                                status: (donation.isDelivered || donation.deliveredAt != null)
                                    ? 'delivered_to_ngo'
                                    : (donation.isExpired ? 'expired' : donation.status.name),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 4),

                          // Vertical Delivery Progress Indicator
                          _buildVerticalProgressStepper(donation, isDark),
                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${tr.get("pickup_deadline")}: ${dateFormat.format(donation.pickupDeadline)}',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.mutedGrey),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (!donation.isAvailable)
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    foregroundColor: AppColors.primaryGreen,
                                  ),
                                  icon: const Icon(Icons.navigation, size: 14),
                                  label: const Text(
                                    'थेट ट्रॅकिंग (Live Map)',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () => context.push('/tracking/${donation.id}'),
                                )
                              else
                                const Icon(Icons.chevron_right, size: 20, color: AppColors.mutedGrey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildVerticalProgressStepper(Donation donation, bool isDark) {
    final hasNgo = donation.claimedByNgoName != null && donation.claimedByNgoName!.isNotEmpty;
    final ngoName = donation.claimedByNgoName ?? 'Asha Children Foundation';
    final hasVol = donation.assignedVolunteerName != null && donation.assignedVolunteerName!.isNotEmpty;
    final volName = donation.assignedVolunteerName ?? 'Volunteer';
    final isPickedUp = donation.status == DonationStatus.pickedUp;
    final isDelivered = donation.status == DonationStatus.delivered ||
        donation.status == DonationStatus.deliveredToNgo ||
        donation.status == DonationStatus.completed ||
        donation.status == DonationStatus.distributed;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'डिलिव्हरी प्रगती (DELIVERY PROGRESS)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.mutedGrey,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isDelivered ? AppColors.primaryGreen : (isPickedUp ? AppColors.orange : (hasNgo ? AppColors.deepGreen : AppColors.mutedGrey))).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDelivered ? 'पूर्ण (Delivered) ✓' : (isPickedUp ? 'वाटेत (In-Transit) 🛵' : (hasNgo ? 'स्वीकारले (Claimed)' : 'प्रतीक्षेत (Pending)')),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isDelivered ? AppColors.primaryGreen : (isPickedUp ? AppColors.orange : (hasNgo ? AppColors.deepGreen : AppColors.mutedGrey)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Step 1: Posted
          _buildVerticalStepNode(
            isDone: true,
            isActive: false,
            title: '१. अन्नदान नोंदवले (Donation Posted)',
            subtitle: 'FoodBridge नेटवर्कवर यशस्वीरित्या प्रकाशित झाले',
            color: AppColors.primaryGreen,
            showLine: true,
            lineColor: hasNgo ? AppColors.primaryGreen : const Color(0xFFCBD5E1),
          ),

          // Step 2: Claimed by NGO
          _buildVerticalStepNode(
            isDone: hasNgo,
            isActive: !hasNgo,
            title: hasNgo ? '२. $ngoName ने स्वीकारले ✓' : '२. शेल्टरच्या प्रतीक्षेत (Awaiting Shelter)',
            subtitle: hasNgo ? 'संस्थेने हे दान स्वीकारले आहे' : 'स्थानिक NGO क्लेम करण्याची वाट पाहत आहे',
            color: hasNgo ? AppColors.primaryGreen : AppColors.orange,
            showLine: true,
            lineColor: (hasNgo && (hasVol || isPickedUp || isDelivered)) ? AppColors.primaryGreen : const Color(0xFFCBD5E1),
          ),

          // Step 3: Picked up by Volunteer
          _buildVerticalStepNode(
            isDone: isPickedUp || isDelivered,
            isActive: hasVol && !isPickedUp && !isDelivered,
            title: isPickedUp
                ? '३. स्वयंसेवक वाटेत (In Transit 🛵)'
                : (hasVol ? '३. $volName नियुक्त' : '३. स्वयंसेवक पिकअप'),
            subtitle: isPickedUp
                ? '$volName ने ताब्यात घेतले • शेल्टरकडे वाटेत'
                : (hasVol ? '$volName पिकअपसाठी निघाले' : 'शेल्टर स्वीकृतीनंतर स्वयंसेवक नियुक्त होईल'),
            color: (isPickedUp || isDelivered) ? AppColors.primaryGreen : (hasVol ? AppColors.orange : AppColors.mutedGrey),
            showLine: true,
            lineColor: isDelivered ? AppColors.primaryGreen : const Color(0xFFCBD5E1),
          ),

          // Step 4: Delivered to Shelter
          _buildVerticalStepNode(
            isDone: isDelivered,
            isActive: false,
            title: isDelivered ? '४. शेल्टरला सुपूर्द पूर्ण! 🎉' : '४. शेल्टरला डिलिव्हरी (Delivery to NGO)',
            subtitle: isDelivered ? '$ngoName येथे अन्न सुरक्षितपणे पोहोचले ✓' : 'अद्याप डिलिव्हरी पूर्ण झालेली नाही',
            color: isDelivered ? AppColors.primaryGreen : AppColors.mutedGrey,
            showLine: false,
            lineColor: Colors.transparent,
          ),
          if (isDelivered) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.workspace_premium, size: 18),
                label: const Text('Food Hero Certificate 🏆'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => FoodHeroCertificateModal.show(context, donation),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerticalStepNode({
    required bool isDone,
    required bool isActive,
    required String title,
    required String subtitle,
    required Color color,
    required bool showLine,
    required Color lineColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isDone ? color : (isActive ? color.withOpacity(0.15) : const Color(0xFFE2E8F0)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? color : (isActive ? color : const Color(0xFFCBD5E1)),
                  width: 2,
                ),
              ),
              child: Icon(
                isDone ? Icons.check : (isActive ? Icons.hourglass_top : Icons.circle),
                size: isDone ? 11 : (isActive ? 9 : 5),
                color: isDone ? Colors.white : color,
              ),
            ),
            if (showLine)
              Container(
                width: 2,
                height: 20,
                color: lineColor,
              ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isDone || isActive ? FontWeight.bold : FontWeight.w600,
                    color: isDone || isActive ? color : AppColors.mutedGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: AppColors.mutedGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Listener(
      onPointerDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.selectionClick();
      },
      onPointerUp: (_) {
        if (mounted) setState(() => _isPressed = false);
      },
      onPointerCancel: (_) {
        if (mounted) setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : widget.color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed
                  ? widget.color.withOpacity(0.6)
                  : widget.color.withOpacity(isDark ? 0.4 : 0.25),
              width: _isPressed ? 1.5 : 1.0,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: widget.color.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onTap,
              splashColor: widget.color.withOpacity(0.12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color.withOpacity(0.85),
                            widget.color,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.mutedGrey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _HeroBadge({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withOpacity(0.6)
            : Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : Colors.white.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isDark ? AppColors.primaryAccentDark : Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDarkPrimary : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
