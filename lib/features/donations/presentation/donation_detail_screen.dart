import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/donation_image_widget.dart';
import '../../../core/widgets/fb_button.dart';
import '../../../core/widgets/fb_status_chip.dart';
import '../../authentication/domain/models/app_user.dart';
import '../../authentication/presentation/auth_provider.dart';
import '../domain/models/donation.dart';
import '../presentation/donation_provider.dart';
import 'widgets/donation_status_timeline.dart';
import 'widgets/food_hero_certificate_modal.dart';

class DonationDetailScreen extends StatelessWidget {
  final String donationId;

  const DonationDetailScreen({
    super.key,
    required this.donationId,
  });

  @override
  Widget build(BuildContext context) {
    final donationProvider = context.watch<DonationProvider>();
    final auth = context.watch<AuthProvider>();
    final donation = donationProvider.getDonationById(donationId);

    if (donation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Donation Details')),
        body: const Center(child: Text('Donation not found or removed.')),
      );
    }

    final dateFormat = DateFormat('EEE, d MMM - hh:mm a');
    final currentUser = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(donation.type.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Donation link copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Donation Banner (Visible to everyone in app)
              Container(
                height: 220,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DonationImageWidget(
                        imageUrl: donation.imageUrl,
                        isFood: donation.isFood,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        enableFullScreenOnTap: true,
                        title: donation.title,
                        heroTag: 'donation-hero-${donation.id}',
                      ),
                      // Gradient overlay for contrast
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.65),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Top Badges
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                donation.isFood ? Icons.restaurant_menu : Icons.checkroom,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                donation.isFood
                                    ? (donation.isVeg ? 'Veg Food' : 'Non-Veg Food')
                                    : (donation.clothingCategory ?? 'Clothing'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Tap to Enlarge Indicator
                      Positioned(
                        bottom: 10,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Tap to enlarge',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FBStatusChip(
                          status: (donation.isDelivered || donation.deliveredAt != null)
                              ? 'delivered_to_ngo'
                              : (donation.isExpired ? 'expired' : donation.status.name),
                        ),
                        if (donation.isUrgent && !donation.isExpired)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer, color: AppColors.errorRed, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Urgent Pickup',
                                  style: TextStyle(
                                    color: AppColors.errorRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      donation.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                      ),
                    ),
                    if (donation.isExpired) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.timer_off_outlined, color: AppColors.errorRed, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'कालबाह्य झाले (Expired) • ही नोंद कोणालाही स्वीकारता येणार नाही.',
                                style: TextStyle(
                                  color: AppColors.errorRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${donation.quantity.toStringAsFixed(0)} ${donation.unit}',
                            style: const TextStyle(
                              color: AppColors.deepGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (donation.isFood)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: donation.isVeg
                                  ? AppColors.primaryGreen.withOpacity(0.1)
                                  : Colors.brown.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: donation.isVeg
                                      ? AppColors.primaryGreen
                                      : Colors.brown,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  donation.isVeg ? 'Veg' : 'Non-Veg',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: donation.isVeg
                                        ? AppColors.deepGreen
                                        : Colors.brown,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (donation.isClothing && donation.clothingCategory != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warningOrange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              donation.clothingCategory!.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.warningOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      donation.description,
                      style: const TextStyle(color: AppColors.mutedGrey, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Operational Logistics & Safety Specs
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Logistics & Safety',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                    ),
                    const Divider(height: 20),
                    _infoRow(
                      Icons.schedule_rounded,
                      'Must Collect Before',
                      dateFormat.format(donation.pickupDeadline),
                      highlight: donation.isUrgent,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      Icons.location_on_outlined,
                      'Pickup Address',
                      donation.pickupAddress,
                    ),
                    if (donation.isFood) ...[
                      const SizedBox(height: 10),
                      _infoRow(
                        Icons.thermostat_outlined,
                        'Holding Temp',
                        donation.storageCondition?.toUpperCase() ?? 'AMBIENT',
                      ),
                      if (donation.allergenNotes != null) ...[
                        const SizedBox(height: 10),
                        _infoRow(
                          Icons.warning_amber_rounded,
                          'Allergen Info',
                          donation.allergenNotes!,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Chain of Custody Timeline
              DonationStatusTimeline(donation: donation),
              const SizedBox(height: 16),

              // Participants Card (Donor, NGO, Volunteer)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stakeholders',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                    ),
                    const Divider(height: 20),
                    _participantTile(
                      icon: Icons.storefront_outlined,
                      role: 'Donor',
                      name: donation.donorName,
                      phone: donation.donorPhone,
                    ),
                    if (donation.claimedByNgoName != null) ...[
                      const SizedBox(height: 12),
                      _participantTile(
                        icon: Icons.volunteer_activism_outlined,
                        role: 'Claimed By NGO',
                        name: donation.claimedByNgoName!,
                        phone: '+91 98220 54321',
                      ),
                    ],
                    if (donation.assignedVolunteerName != null || donation.assignedVolunteerId != null) ...[
                      const SizedBox(height: 12),
                      _participantTile(
                        icon: Icons.two_wheeler_rounded,
                        role: 'Assigned Volunteer',
                        name: donationProvider.resolveVolunteerName(
                          donation.assignedVolunteerId,
                          donation.assignedVolunteerName,
                        ),
                        phone: donation.assignedVolunteerPhone,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic Contextual Action Buttons based on User Role & Donation Status
              _buildRoleActions(context, donation, currentUser, donationProvider),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleActions(
    BuildContext context,
    Donation donation,
    AppUser? currentUser,
    DonationProvider donationProvider,
  ) {
    if (donation.isExpired) {
      return Container(
        width: double.infinity,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 18, color: AppColors.errorRed),
            SizedBox(width: 8),
            Text(
              'कालबाह्य झाले (Expired - Closed)',
              style: TextStyle(
                color: AppColors.errorRed,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (currentUser?.role == UserRole.ngo && donation.isAvailable) {
      return FBButton(
        label: 'Claim Donation for Shelter',
        icon: Icons.check_circle_outline,
        onPressed: () async {
          final requestedQty = await showDialog<double>(
            context: context,
            builder: (ctx) {
              final qtyController = TextEditingController(
                text: donation.quantity.toStringAsFixed(0),
              );
              String? errorText;

              return StatefulBuilder(
                builder: (context, setModalState) {
                  return AlertDialog(
                    title: const Text('Claim Donation for Shelter'),
                    actionsOverflowButtonSpacing: 8,
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your shelter commits to collecting this surplus before ${DateFormat('hh:mm a').format(donation.pickupDeadline)}.',
                            style: const TextStyle(fontSize: 13, color: AppColors.mutedGrey),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: qtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Quantity to Claim (${donation.unit})',
                              errorText: errorText,
                              helperText: 'Available: ${donation.quantity.toStringAsFixed(0)} ${donation.unit}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final parsed = double.tryParse(qtyController.text.trim());
                          if (parsed == null || parsed <= 0) {
                            setModalState(() => errorText = 'Enter a valid positive number');
                            return;
                          }
                          if (parsed > donation.quantity) {
                            setModalState(() => errorText = 'Exceeds available amount (${donation.quantity.toStringAsFixed(0)})');
                            return;
                          }
                          Navigator.pop(ctx, parsed);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Confirm Claim'),
                      ),
                    ],
                  );
                },
              );
            },
          );

          if (requestedQty != null && context.mounted) {
            final success = await donationProvider.claimDonation(
              donationId: donation.id,
              ngoId: currentUser!.id,
              ngoName: currentUser.organizationName ?? currentUser.fullName,
              requestedQuantity: requestedQty,
            );
            if (context.mounted) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Successfully claimed ${requestedQty.toStringAsFixed(0)} ${donation.unit}! Ready for volunteer dispatch.',
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
          }
        },
      );
    }

    // 2. Volunteer Task Acceptance Flow
    if (currentUser?.role == UserRole.volunteer && donation.isClaimed) {
      return FBButton(
        label: 'Accept Pickup & Delivery Task',
        icon: Icons.two_wheeler_rounded,
        onPressed: () async {
          await donationProvider.acceptVolunteerTask(
            donationId: donation.id,
            volunteerId: currentUser!.id,
            volunteerName: currentUser.fullName,
            phone: currentUser.phone ?? '+91 97654 99887',
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Delivery task assigned to you! Safe riding.'),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
          }
        },
      );
    }

    // 3. Volunteer Status Transitions (In Progress)
    if (currentUser?.role == UserRole.volunteer &&
        donation.assignedVolunteerId == currentUser?.id) {
      if (donation.status == DonationStatus.assigned) {
        return FBButton(
          label: 'Confirm Food Picked Up from Donor',
          icon: Icons.inventory_2_outlined,
          onPressed: () async {
            await donationProvider.markPickedUp(donation.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Status updated: In Transit to NGO Shelter.'),
                  backgroundColor: AppColors.warningOrange,
                ),
              );
            }
          },
        );
      } else if (donation.status == DonationStatus.pickedUp) {
        return FBButton(
          label: 'Confirm Safe Handover & Delivery to NGO',
          icon: Icons.task_alt_rounded,
          onPressed: () async {
            await donationProvider.markDelivered(donation.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delivery completed! Thank you for bridging the need.'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            }
          },
        );
      }
    }

    // 4. Donor Management (Edit & Withdraw Listing)
    if (currentUser?.role == UserRole.donor &&
        donation.donorId == currentUser?.id &&
        donation.isAvailable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FBButton(
            label: 'Edit Listing Details',
            variant: FBButtonVariant.secondary,
            icon: Icons.edit_outlined,
            onPressed: () => context.push('/edit-donation/${donation.id}'),
          ),
          const SizedBox(height: 12),
          FBButton(
            label: 'Withdraw Listing',
            variant: FBButtonVariant.danger,
            icon: Icons.close_rounded,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Withdraw Listing?'),
                  content: const Text(
                    'Are you sure you want to withdraw this listing from FoodBridge? It will no longer be visible to shelters.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Keep Active'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Withdraw'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await donationProvider.withdrawDonation(donation.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Donation listing withdrawn.')),
                  );
                }
              }
            },
          ),
        ],
      );
    }

    if (donation.isDelivered || donation.deliveredAt != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FBButton(
            label: 'View Food Hero Certificate (प्रमाणपत्र पहा)',
            variant: FBButtonVariant.primary,
            icon: Icons.workspace_premium_outlined,
            onPressed: () => FoodHeroCertificateModal.show(context, donation),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _infoRow(IconData icon, String title, String value, {bool highlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: highlight ? AppColors.errorRed : AppColors.mutedGrey),
        const SizedBox(width: 10),
        SizedBox(
          width: 130,
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, color: AppColors.mutedGrey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: highlight ? AppColors.errorRed : AppColors.charcoal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _participantTile({
    required IconData icon,
    required String role,
    required String name,
    String? phone,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primaryGreen.withOpacity(0.12),
          child: Icon(icon, color: AppColors.primaryGreen, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: const TextStyle(fontSize: 11, color: AppColors.mutedGrey, fontWeight: FontWeight.bold),
              ),
              Text(
                name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.charcoal),
              ),
            ],
          ),
        ),
        if (phone != null)
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: AppColors.primaryGreen, size: 20),
            onPressed: () {},
          ),
      ],
    );
  }
}
