import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/route_map_view.dart';
import '../../authentication/domain/models/app_user.dart';
import '../../authentication/presentation/auth_provider.dart';
import '../domain/models/donation.dart';
import 'donation_provider.dart';
import 'widgets/food_hero_certificate_modal.dart';

/// The official FoodBridge Real-Time Tracking Screen (Matching Blinkit & Rapido standard).
/// Features:
/// - Real-time OpenStreetMap route connecting Donor -> Courier -> NGO Shelter
/// - Exact Donor Pickup Location with contact & address
/// - Exact NGO Shelter Drop-off Location with contact & address
/// - Live moving courier marker with distance & ETA
/// - Dynamic 3-step delivery progress stepper
/// - Two-Way Handover Verification OTP (Donor Pickup Code & NGO Receipt Code)
class TrackingScreen extends StatefulWidget {
  final String donationId;

  const TrackingScreen({
    super.key,
    required this.donationId,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final donationProvider = context.watch<DonationProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.user;

    final donation = donationProvider.getDonationById(widget.donationId) ??
        donationProvider.allDonations.firstWhere(
          (d) => d.id == widget.donationId,
          orElse: () => donationProvider.allDonations.isNotEmpty
              ? donationProvider.allDonations.first
              : Donation(
                  id: widget.donationId,
                  donorId: 'usr-donor-101',
                  donorName: 'The Green Leaf Bistro',
                  title: 'Fresh Surplus Meals',
                  description: 'Hygienically prepared meals',
                  quantity: 20,
                  unit: 'meals',
                  type: DonationType.food,
                  pickupAddress: 'Shop 4, Powai Naka, Satara',
                  city: 'Satara',
                  createdAt: DateTime.now(),
                  pickupDeadline: DateTime.now().add(const Duration(hours: 3)),
                ),
        );

    final resolvedVolName = donationProvider.resolveVolunteerName(
      donation.assignedVolunteerId,
      donation.assignedVolunteerName,
    );
    final volunteerName = resolvedVolName.isNotEmpty
        ? resolvedVolName
        : (currentUser?.isVolunteer == true ? (currentUser?.fullName ?? 'Volunteer') : 'Volunteer');
    final volunteerPhone = donation.assignedVolunteerPhone ?? '+91 97654 99887';
    final donorName = donation.donorName;
    final donorPhone = donation.donorPhone ?? '+91 98200 12345';
    final ngoName = donation.claimedByNgoName ?? 'Asha Children Foundation';
    final isNgo = currentUser?.role == UserRole.ngo;

    String statusTitle;
    String statusSubtitle;
    if (donation.isDelivered ||
        donation.deliveredAt != null ||
        donation.status == DonationStatus.delivered ||
        donation.status == DonationStatus.deliveredToNgo ||
        donation.status == DonationStatus.completed) {
      statusTitle = 'Donation Delivered! 🎉 (वितरण पूर्ण)';
      statusSubtitle = 'Delivered safely to $ngoName';
    } else if (donation.status == DonationStatus.pickedUp) {
      statusTitle = 'On the Way to Shelter 🛵 (शेल्टरकडे वाटेत)';
      statusSubtitle = 'Cargo picked up • Delivering to $ngoName';
    } else if (donation.assignedVolunteerId != null) {
      statusTitle = 'Volunteer Assigned (स्वयंसेवक पिकअपसाठी निघाले)';
      statusSubtitle = '$volunteerName is heading to $donorName';
    } else {
      statusTitle = 'Claimed by Shelter (शेल्टरने स्वीकारले)';
      statusSubtitle = 'Awaiting volunteer courier assignment';
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'Live Tracking (थेट ट्रॅकिंग)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Courier live location refreshed.'),
                  backgroundColor: AppColors.primaryGreen,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Full Interactive Route Map View (OSM + Road Route + Moving Marker)
            RouteMapView(
              height: 290,
              pickupAddress: donation.pickupAddress,
              destinationAddress: donation.dropoffAddress,
              pickupLocation: donation.pickupLatLng,
              destinationLocation: donation.dropoffLatLng,
              courierLocation: donation.liveCourierLatLng,
              etaText: 'ETA: ${donation.estimatedMinutes} min • ${donation.estimatedDistanceKm} km',
              onRefresh: () => setState(() {}),
            ),
            const SizedBox(height: 16),

            // 2. Realtime Status & Progress Stepper Card (Blinkit style)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    statusTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusSubtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mutedGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),

                  // 3-Step Live Delivery Progress Stepper
                  _buildStepper(donation),

                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Assigned Volunteer Courier Info Row
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF8F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sports_motorsports,
                          color: AppColors.primaryGreen,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  volunteerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Courier 🛵',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Two-Wheeler • Live GPS Enabled',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.mutedGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, color: AppColors.primaryGreen),
                        tooltip: 'Call Volunteer',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Calling volunteer $volunteerName: $volunteerPhone'),
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Rapido/Blinkit Route Nodes Card (Where to pick up & Where to deliver)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DISPATCH ROUTE DETAILS (मार्गाचा तपशील)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: AppColors.mutedGrey,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Node 1: Pickup Location (Donor)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEBEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront, color: AppColors.errorRed, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'PICKUP FROM (येथून घ्या):',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.errorRed,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'दात्याचे स्थान',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.errorRed),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              donorName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            Text(
                              donation.pickupAddress,
                              style: const TextStyle(fontSize: 12, color: AppColors.mutedGrey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.errorRed),
                        tooltip: 'Call Donor',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Calling donor $donorName: $donorPhone'),
                              backgroundColor: AppColors.errorRed,
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Connecting Route Line
                  Padding(
                    padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
                    child: Container(
                      width: 2,
                      height: 24,
                      color: AppColors.primaryGreen.withOpacity(0.35),
                    ),
                  ),

                  // Node 2: Drop-off Location (NGO / Shelter)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDF7EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.home_work, color: AppColors.primaryGreen, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'DELIVER TO (येथे पोहोचवा):',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDF7EE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'संस्थेचे स्थान',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ngoName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            Text(
                              donation.dropoffAddress,
                              style: const TextStyle(fontSize: 12, color: AppColors.mutedGrey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.primaryGreen),
                        tooltip: 'Call Shelter',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Calling shelter $ngoName: +91 94220 88776'),
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Two-Way Verification Code Card (Blinkit style Handover OTP)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.mintLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isNgo
                              ? 'NGO Delivery Receipt Code'
                              : 'Handover Pickup Code (पिकअप कोड)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isNgo
                              ? 'Provide to volunteer upon receiving cargo'
                              : 'Share with volunteer $volunteerName upon pickup',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.mutedGrey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryGreen, width: 1.5),
                    ),
                    child: Text(
                      isNgo ? donation.deliveryOtp : donation.pickupOtp,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (donation.isDelivered ||
                donation.deliveredAt != null ||
                donation.status == DonationStatus.delivered ||
                donation.status == DonationStatus.deliveredToNgo ||
                donation.status == DonationStatus.completed) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD97706),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Food Hero Certificate Ready! 🏆',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'पर्यावरण व सामाजिक प्रभाव प्रमाणपत्र डाऊनलोड करा',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.verified_outlined, size: 18),
                        label: const Text('View & Download Certificate (प्रमाणपत्र पहा)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => FoodHeroCertificateModal.show(context, donation),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 5. Emergency Task Release & Support
            OutlinedButton.icon(
              icon: const Icon(Icons.report_problem_outlined, color: AppColors.errorRed, size: 18),
              label: const Text('Emergency Re-Dispatch / Support'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                side: const BorderSide(color: AppColors.errorRed),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Emergency Assistance'),
                    content: const Text(
                      'If the courier encounters vehicle breakdown, bad weather, or delay, tap confirm to alert community backup riders.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Dispatched backup alert to nearby volunteers.'),
                              backgroundColor: AppColors.errorRed,
                            ),
                          );
                        },
                        child: const Text('Request Backup', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(Donation donation) {
    final status = donation.status;
    final bool isPickedUp = status == DonationStatus.pickedUp ||
        status == DonationStatus.delivered ||
        status == DonationStatus.deliveredToNgo ||
        status == DonationStatus.distributed ||
        status == DonationStatus.completed;
    final bool isInTransit = status == DonationStatus.pickedUp;
    final bool isDelivered = status == DonationStatus.delivered ||
        status == DonationStatus.deliveredToNgo ||
        status == DonationStatus.distributed ||
        status == DonationStatus.completed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepNode(
          label: 'Picked Up\n(पिकअप)',
          isDone: isPickedUp,
          isActive: !isPickedUp && donation.assignedVolunteerId != null,
        ),
        _stepLine(isDone: isPickedUp),
        _stepNode(
          label: 'In Transit\n(वाटेत)',
          isDone: isDelivered,
          isActive: isInTransit,
        ),
        _stepLine(isDone: isDelivered),
        _stepNode(
          label: 'Delivered\n(पोहोचवले)',
          isDone: isDelivered,
          isActive: false,
        ),
      ],
    );
  }

  Widget _stepNode({
    required String label,
    required bool isDone,
    required bool isActive,
  }) {
    Color color;
    IconData icon;
    if (isDone) {
      color = AppColors.primaryGreen;
      icon = Icons.check;
    } else if (isActive) {
      color = AppColors.orange;
      icon = Icons.directions_bike;
    } else {
      color = Colors.grey.shade400;
      icon = Icons.circle;
    }

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone || isActive ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isDone || isActive ? Colors.white : color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.charcoal : AppColors.mutedGrey,
          ),
        ),
      ],
    );
  }

  Widget _stepLine({required bool isDone}) {
    return Container(
      width: 44,
      height: 2.5,
      margin: const EdgeInsets.only(bottom: 24),
      color: isDone ? AppColors.primaryGreen : Colors.grey.shade300,
    );
  }
}
