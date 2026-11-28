import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_update_dialog.dart';
import '../../../core/widgets/exit_confirmation_dialog.dart';
import '../../../core/widgets/donation_image_widget.dart';
import '../../../core/utils/avatar_image_helper.dart';
import '../../../core/widgets/fb_appearance_selector.dart';
import '../../../core/widgets/fb_button.dart';
import '../../../core/widgets/fb_empty_state.dart';
import '../../../core/widgets/fb_text_field.dart';
import '../../authentication/domain/models/app_user.dart';
import '../../authentication/presentation/auth_provider.dart';
import '../../authentication/presentation/widgets/terms_and_conditions_modal.dart';
import '../../donations/domain/models/donation.dart';
import 'widgets/ngo_handover_qr_modal.dart';
import '../../donations/presentation/donation_provider.dart';

class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TermsAndConditionsModal.showIfNeeded(context);
      AppUpdateDialog.showIfAvailable(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final donationProvider = context.watch<DonationProvider>();
    final currentUser = auth.user;

    // Filter available donations & network claims
    final allAvailable = donationProvider.availableDonations;
    final networkClaimed = donationProvider.networkClaimedDonations;
    final List<Donation> feedList;
    if (_selectedFilter == 'network_claims') {
      feedList = networkClaimed;
    } else {
      feedList = allAvailable.where((d) {
        if (_selectedFilter == 'food') return d.isFood;
        if (_selectedFilter == 'clothing') return d.isClothing;
        if (_selectedFilter == 'urgent') return d.isUrgent;
        return true;
      }).toList();
    }

    // Claimed by this NGO
    final claimedByMe = donationProvider.getDonationsClaimedByNgo(
      currentUser?.id ?? 'usr-ngo-202',
    );

    final tr = context.tr;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FoodBridgeExitScope(
      child: Scaffold(
      appBar: AppBar(
        title: Text(tr.ngoPortal),
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
      body: RefreshIndicator(
        onRefresh: () => donationProvider.refreshDonations(),
        color: AppColors.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Verified Shelter Header Banner
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push('/ngo/verification'),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.deepGreen,
                    border: isDark ? Border.all(color: AppColors.borderDark) : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.primaryGreen.withOpacity(0.2) : AppColors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified,
                          color: isDark ? AppColors.primaryGreen : AppColors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.organizationName ??
                                  'Asha Children Foundation',
                              style: TextStyle(
                                color: isDark ? AppColors.textDarkPrimary : AppColors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Darpan: ${currentUser?.darpanId ?? "MH/2019/0219482"} • ${tr.tapToViewVerification}',
                              style: TextStyle(
                                color: isDark ? AppColors.textDarkSecondary : Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: isDark ? AppColors.textDarkSecondary : Colors.white70),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Live Realtime Network Summary Tiles (Available vs Our Claims vs Network Claims)
              Row(
                children: [
                  Expanded(
                    child: _buildNgoStatTile(
                      title: 'Available (उपलब्ध)',
                      subtitle: 'कोणाचेही क्लेम नाही',
                      count: '${donationProvider.totalAvailableCount}',
                      icon: Icons.storefront_outlined,
                      color: AppColors.primaryGreen,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildNgoStatTile(
                      title: 'Our Claims (आमचे)',
                      subtitle: 'आम्ही स्वीकारलेले',
                      count: '${claimedByMe.length}',
                      icon: Icons.assignment_turned_in_outlined,
                      color: AppColors.orange,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildNgoStatTile(
                      title: 'Network Claims',
                      subtitle: 'शहरातील एकूण क्लेम्स',
                      count: '${donationProvider.totalClaimedCount}',
                      icon: Icons.hub_outlined,
                      color: const Color(0xFF2980B9),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Portal Actions
              Row(
                children: [
                  Expanded(
                    child: _PortalQuickCard(
                      icon: Icons.assignment_outlined,
                      label: tr.claims,
                      badge: '${claimedByMe.length}',
                      color: AppColors.primaryGreen,
                      onTap: () => context.push('/ngo/my-claims'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PortalQuickCard(
                      icon: Icons.handshake_outlined,
                      label: tr.distributions,
                      badge: '${donationProvider.getNgoDistributionRecords(currentUser?.id ?? "usr-ngo-202").length}',
                      color: AppColors.orange,
                      onTap: () => context.push('/ngo/distribution-records'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PortalQuickCard(
                      icon: Icons.verified_user_outlined,
                      label: tr.verification,
                      badge: currentUser?.ngoVerificationStatus == NgoVerificationStatus.verified ? tr.activeStatus : tr.pendingStatus,
                      color: AppColors.deepGreen,
                      onTap: () => context.push('/ngo/verification'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', '${tr.allDonations} (${allAvailable.length})'),
                    const SizedBox(width: 8),
                    _filterChip('food', tr.filterFood),
                    const SizedBox(width: 8),
                    _filterChip('clothing', tr.filterClothing),
                    const SizedBox(width: 8),
                    _filterChip('urgent', tr.filterUrgent),
                    const SizedBox(width: 8),
                    _filterChip('network_claims', 'इतर संस्थांचे क्लेम (${networkClaimed.length})'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Available Donations Feed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedFilter == 'network_claims'
                          ? 'Network Claims (इतर संस्थांचे क्लेम)'
                          : tr.availableNearYou,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${feedList.length} ${tr.listings}',
                    style: const TextStyle(
                      color: AppColors.mutedGrey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (feedList.isEmpty)
                FBEmptyState(
                  title: tr.get('no_donations_matching'),
                  description: tr.get('no_donations_matching_desc'),
                  icon: Icons.search_off_rounded,
                )
              else
                ...feedList.map((d) {
                  final dateFormat = DateFormat('hh:mm a');
                  return _DonationFeedCard(
                    donation: d,
                    title: d.title,
                    category: d.isFood ? tr.get('cooked_meals') : tr.get('clothing'),
                    donor: d.donorName,
                    location: '${d.city} (${tr.localityMasked}) • ~${d.estimatedDistanceKm.toStringAsFixed(1)} km',
                    quantityText: '${d.quantity.toStringAsFixed(0)} ${d.unit}',
                    expiryText:
                        '${tr.deadline}: ${dateFormat.format(d.pickupDeadline)}',
                    isUrgent: d.isUrgent,
                    icon: d.isFood ? Icons.soup_kitchen : Icons.checkroom,
                    onTap: () => context.push('/donation-detail/${d.id}'),
                    onClaim: () => _handleClaim(
                      context,
                      d,
                      donationProvider,
                      currentUser,
                    ),
                  );
                }),

            const SizedBox(height: 28),

            // Shelter Active Claims
            if (claimedByMe.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${tr.ourActiveClaims} (${claimedByMe.length})',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/ngo/my-claims'),
                    child: Text(tr.viewAll),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...claimedByMe.map((d) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: DonationImageWidget(
                          imageUrl: d.imageUrl,
                          isFood: d.isFood,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      d.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Builder(
                      builder: (context) {
                        final volName = donationProvider.resolveVolunteerName(
                          d.assignedVolunteerId,
                          d.assignedVolunteerName,
                        );
                        if (d.isDelivered || d.deliveredAt != null) {
                          return Text(
                            'वितरण पूर्ण ✓ • Volunteer: $volName',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                        return Text(
                          (d.assignedVolunteerName != null || d.assignedVolunteerId != null)
                              ? 'Volunteer: $volName (${d.status.displayName})'
                              : tr.awaitingVolunteerPickup,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (d.assignedVolunteerName != null || d.status == DonationStatus.pickedUp)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () => context.push('/tracking/${d.id}'),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.two_wheeler, color: AppColors.primaryGreen, size: 18),
                              ),
                            ),
                          ),
                        InkWell(
                          onTap: () => showNgoHandoverQrModal(context, d),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.qr_code_2, size: 14, color: AppColors.primaryGreen),
                                const SizedBox(width: 4),
                                Text(
                                  'OTP: ${d.deliveryOtp}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.mutedGrey,
                        ),
                      ],
                    ),
                    onTap: () => context.push('/donation-detail/${d.id}'),
                  ),
                );
              }),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryGreen.withOpacity(0.18),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.deepGreen : AppColors.mutedGrey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = key);
      },
    );
  }

  Widget _buildNgoStatTile({
    required String title,
    required String subtitle,
    required String count,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  count,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.textDarkPrimary : AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDarkPrimary : AppColors.deepGreen,
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
    );
  }

  void _handleClaim(
    BuildContext context,
    Donation donation,
    DonationProvider donationProvider,
    AppUser? currentUser,
  ) {
    if (donation.isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ही नोंद कालबाह्य झाली आहे (Expired), ती स्वीकारता येणार नाही.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final ngoId = currentUser?.id ?? 'usr-ngo-202';
    final ngoName = currentUser?.organizationName ?? 'Asha Children Foundation';
    final isVerified = currentUser == null ||
        currentUser.ngoVerificationStatus == NgoVerificationStatus.verified ||
        currentUser.role != UserRole.ngo;

    if (!isVerified) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: AppColors.orange, size: 26),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verification Required',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          content: const Text(
            'Your NGO registration is currently pending administrative verification. Only verified NGOs with active 80G and Darpan credentials can claim donations to ensure food safety and community integrity.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                context.push('/ngo/verification');
              },
              child: const Text('View Verification'),
            ),
          ],
        ),
      );
      return;
    }

    final qtyController = TextEditingController(text: donation.quantity.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 24.0,
              bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24.0,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Claim ${donation.title}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Available: ${donation.quantity.toStringAsFixed(0)} ${donation.unit} • Must collect before ${DateFormat('hh:mm a').format(donation.pickupDeadline)}',
                    style: const TextStyle(
                      color: AppColors.mutedGrey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FBTextField(
                    label: 'Quantity to Claim (${donation.unit})',
                    controller: qtyController,
                    hint: 'e.g. ${donation.quantity.toStringAsFixed(0)}',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  FBButton(
                    label: 'Confirm Claim (Broadcast for Volunteer)',
                    onPressed: () async {
                      final requestedQty = double.tryParse(qtyController.text.trim()) ?? donation.quantity;
                      Navigator.pop(bottomSheetContext);
                      final success = await donationProvider.claimDonation(
                        donationId: donation.id,
                        ngoId: ngoId,
                        ngoName: ngoName,
                        requestedQuantity: requestedQty,
                        isVerifiedNgo: isVerified,
                      );
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Donation claimed! Broadcasted to volunteers for pickup.',
                              ),
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(donationProvider.errorMessage ?? 'Claim failed.'),
                              backgroundColor: AppColors.errorRed,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  FBButton(
                    label: 'Cancel',
                    variant: FBButtonVariant.secondary,
                    onPressed: () => Navigator.pop(bottomSheetContext),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DonationFeedCard extends StatelessWidget {
  final Donation donation;
  final String title;
  final String category;
  final String donor;
  final String location;
  final String quantityText;
  final String expiryText;
  final bool isUrgent;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onClaim;

  const _DonationFeedCard({
    required this.donation,
    required this.title,
    required this.category,
    required this.donor,
    required this.location,
    required this.quantityText,
    required this.expiryText,
    required this.isUrgent,
    required this.icon,
    required this.onTap,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final donationProvider = context.watch<DonationProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.charcoal,
                                ),
                              ),
                            ),
                            if (donation.isExpired) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.errorRed,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer_off_outlined, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Expired',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$donor • $location',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warmCream,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        quantityText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepGreen,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: isUrgent
                              ? AppColors.errorRed
                              : AppColors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          expiryText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isUrgent
                                ? AppColors.errorRed
                                : AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Status and Claim details banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: donation.isExpired
                      ? AppColors.errorRed.withOpacity(0.08)
                      : (donation.isAvailable
                          ? AppColors.primaryGreen.withOpacity(0.08)
                          : AppColors.orange.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(8),
                  border: donation.isExpired ? Border.all(color: AppColors.errorRed.withOpacity(0.25)) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      donation.isExpired
                          ? Icons.timer_off_outlined
                          : (donation.isAvailable ? Icons.check_circle_outline : Icons.verified),
                      size: 14,
                      color: donation.isExpired
                          ? AppColors.errorRed
                          : (donation.isAvailable ? AppColors.primaryGreen : AppColors.orange),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        donation.isExpired
                            ? 'कालबाह्य झाले (Expired) • ही नोंद कोणालाही स्वीकारता येणार नाही'
                            : (donation.isDelivered || donation.deliveredAt != null
                                ? 'वितरण पूर्ण (Delivered safely to shelter) ✓'
                                : (donation.isAvailable
                                    ? 'उपलब्ध (अजून कोणाचेही क्लेम नाही • Ready to Claim)'
                                    : 'Shelter: ${donation.claimedByNgoName ?? "Shelter"} ने स्वीकारले ✓ • Volunteer: ${donationProvider.resolveVolunteerName(donation.assignedVolunteerId, donation.assignedVolunteerName)}')),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: donation.isExpired
                              ? AppColors.errorRed
                              : ((donation.isDelivered || donation.deliveredAt != null || donation.isAvailable)
                                  ? AppColors.deepGreen
                                  : AppColors.orange),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (donation.isExpired)
                Container(
                  width: double.infinity,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 16, color: AppColors.errorRed),
                      SizedBox(width: 6),
                      Text(
                        'कालबाह्य झाले (Expired - Closed)',
                        style: TextStyle(
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else if (donation.isAvailable)
                FBButton(label: context.tr.claimDonation, height: 44, onPressed: onClaim)
              else
                FBButton(label: 'View Claim Details', height: 44, onPressed: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortalQuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String badge;
  final Color color;
  final VoidCallback onTap;

  const _PortalQuickCard({
    required this.icon,
    required this.label,
    required this.badge,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              badge,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
