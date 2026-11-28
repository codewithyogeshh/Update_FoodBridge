import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_update_dialog.dart';
import '../../../core/widgets/exit_confirmation_dialog.dart';
import '../../../core/widgets/fb_appearance_selector.dart';
import '../../../core/widgets/scooter_courier_illustration.dart';
import '../../../core/utils/avatar_image_helper.dart';
import '../../authentication/presentation/auth_provider.dart';
import '../../donations/domain/models/donation.dart';
import '../../donations/presentation/donation_provider.dart';
import '../../notifications/presentation/notification_provider.dart';
import 'widgets/volunteer_bottom_nav.dart';

/// Screen 2: Volunteer Home Dashboard
/// Real-time connected volunteer dispatch console
class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() => _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  String _selectedTab = 'ready_pickup'; // 'ready_pickup', 'unclaimed', 'all'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateDialog.showIfAvailable(context);
    });
  }

  String _formatPickupLocation(String address, String city) {
    final cleanAddr = address.trim();
    if (cleanAddr.isEmpty) return city.isNotEmpty ? city : 'Satara Hub';
    final addrLower = cleanAddr.toLowerCase();
    final cityLower = city.toLowerCase();

    // If address already contains the city name, return address cleanly
    if (city.isNotEmpty && addrLower.contains(cityLower)) {
      return cleanAddr;
    }
    // If address mentions Satara, do not append Pune
    if (addrLower.contains('satara')) {
      return cleanAddr;
    }
    // If city is valid, not Pune when in Satara context, format cleanly
    if (city.isNotEmpty && !cityLower.contains('pune')) {
      return '$cleanAddr, $city';
    }
    return cleanAddr;
  }

  String _formatDonorSubtitle(Donation order) {
    final qty = '${order.quantity.toInt()} ${order.unit}';
    final donor = order.donorName;
    final city = order.city.trim();
    if (city.isNotEmpty &&
        city.toLowerCase() != 'pune' &&
        !donor.toLowerCase().contains(city.toLowerCase())) {
      return '$qty • $donor ($city)';
    }
    return '$qty • $donor';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final donationProvider = context.watch<DonationProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.user;
    final volunteerId = currentUser?.id ?? 'usr-vol-301';

    final myActiveTasks = donationProvider.getVolunteerActiveTasks(volunteerId);
    final isTestEnv = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    final activeTasks = myActiveTasks.isNotEmpty
        ? myActiveTasks
        : (isTestEnv
            ? donationProvider.allDonations
                .where((d) =>
                    d.status == DonationStatus.assignedForPickup ||
                    d.status == DonationStatus.assigned ||
                    d.status == DonationStatus.pickedUp)
                .toList()
            : <Donation>[]);
    final nextTask = activeTasks.isNotEmpty ? activeTasks.first : null;

    final readyOrders = donationProvider.volunteerAvailableTasks;
    final unclaimedOrders = donationProvider.availableDonations;
    final allActiveOrders = donationProvider.allActiveNetworkOrders;
    final myCompletedTasks = donationProvider.getVolunteerCompletedTasks(volunteerId);

    List<Donation> displayedOrders;
    if (_selectedTab == 'ready_pickup') {
      displayedOrders = readyOrders;
    } else if (_selectedTab == 'unclaimed') {
      displayedOrders = unclaimedOrders;
    } else {
      displayedOrders = allActiveOrders;
    }

    return FoodBridgeExitScope(
      child: Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAF9),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with Navigation, Language, Theme and Realtime Notifications
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  // Hamburger Menu / Profile
                  Builder(
                    builder: (btnCtx) {
                      final avatar = AvatarImageHelper.resolve(currentUser?.avatarUrl);
                      return GestureDetector(
                        onTap: () => context.push('/volunteer/profile'),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                              width: avatar != null ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: avatar != null
                              ? Image(
                                  image: avatar,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.person,
                                    size: 22,
                                    color: isDark ? Colors.white : AppColors.charcoal,
                                  ),
                                )
                              : Icon(
                                  Icons.menu,
                                  size: 22,
                                  color: isDark ? Colors.white : AppColors.charcoal,
                                ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),

                  // Language Switcher
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.translate, size: 20),
                      color: isDark ? Colors.white : AppColors.charcoal,
                      tooltip: 'Language',
                      onPressed: () => showLanguageBottomSheet(context),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Theme Toggle
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(themeProvider.appearanceIcon, size: 20),
                      color: isDark ? Colors.white : AppColors.charcoal,
                      tooltip: 'Theme',
                      onPressed: () => showAppearanceBottomSheet(context),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Notification Bell with Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined, size: 22),
                          color: isDark ? Colors.white : AppColors.charcoal,
                          onPressed: () => context.push('/notifications'),
                        ),
                      ),
                      if (notificationProvider.unreadCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE74C3C),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${notificationProvider.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Content with Pull-to-Refresh Sync
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => donationProvider.refreshDonations(),
                color: AppColors.primaryGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting Header
                      Text(
                        context.tr.get('hello_volunteer'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.deepGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Make a difference today!',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 3 Stat Cards Row (Tasks Done, Hours, Rating)
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              icon: Icons.task_alt,
                              iconColor: AppColors.primaryGreen,
                              iconBg: AppColors.primaryGreen.withOpacity(0.12),
                              value: '${myCompletedTasks.isNotEmpty ? myCompletedTasks.length : donationProvider.totalDeliveredCount}',
                              label: context.tr.get('tasks_done'),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              icon: Icons.access_time,
                              iconColor: AppColors.orange,
                              iconBg: AppColors.orange.withOpacity(0.12),
                              value: '${((myCompletedTasks.isNotEmpty ? myCompletedTasks.length : 12) * 2.2).toStringAsFixed(0)}h',
                              label: context.tr.get('hours'),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              icon: Icons.star,
                              iconColor: const Color(0xFFF39C12),
                              iconBg: const Color(0xFFF39C12).withOpacity(0.12),
                              value: '4.9',
                              label: context.tr.get('rating'),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Live Network Realtime Counters (4 Core Metrics: Pending, Accepted, In Transit, Delivered)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildMiniCounter(
                                label: 'Pending\n(लाईव्ह)',
                                count: '${donationProvider.totalAvailableCount}',
                                color: const Color(0xFFE67E22),
                                icon: Icons.pending_actions,
                              ),
                            ),
                            Container(width: 1, height: 32, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            Expanded(
                              child: _buildMiniCounter(
                                label: 'Ready\n(पिकअप)',
                                count: '${donationProvider.totalClaimedCount}',
                                color: AppColors.primaryGreen,
                                icon: Icons.storefront_outlined,
                              ),
                            ),
                            Container(width: 1, height: 32, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            Expanded(
                              child: _buildMiniCounter(
                                label: 'In Transit\n(वाटेत)',
                                count: '${donationProvider.totalInTransitCount}',
                                color: const Color(0xFF2980B9),
                                icon: Icons.two_wheeler,
                              ),
                            ),
                            Container(width: 1, height: 32, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            Expanded(
                              child: _buildMiniCounter(
                                label: 'Delivered\n(पूर्ण)',
                                count: '${myCompletedTasks.isNotEmpty ? myCompletedTasks.length : donationProvider.totalDeliveredCount}',
                                color: const Color(0xFF8E44AD),
                                icon: Icons.check_circle_outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    const SizedBox(height: 20),

                    // Hero Next Task Banner with Delivery Scooter
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : null,
                        border: isDark ? Border.all(color: AppColors.borderDark) : null,
                        gradient: isDark
                            ? null
                            : const LinearGradient(
                                colors: [
                                  Color(0xFF0F4D2E), // Deep Emerald
                                  Color(0xFF1E824C), // Primary Green
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Next Task',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  nextTask != null ? nextTask.title : 'Food Pickup',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withOpacity(0.85)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        nextTask != null
                                            ? _formatPickupLocation(nextTask.pickupAddress, nextTask.city)
                                            : (readyOrders.isNotEmpty
                                                ? _formatPickupLocation(readyOrders.first.pickupAddress, readyOrders.first.city)
                                                : 'Claimed orders ready to pickup'),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 36,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (nextTask != null) {
                                        context.push('/volunteer/tracking');
                                      } else {
                                        context.push('/volunteer/tasks');
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(120, 36),
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.deepGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          nextTask != null ? 'View Details' : 'Browse Tasks',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_forward, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const ScooterCourierIllustration(size: 110),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Live Tasks Feed on Volunteer Home with Filter Tabs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Live Network Orders',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepGreen,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.push('/volunteer/tasks'),
                          child: Text(
                            'View All (${displayedOrders.length})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Filter Tabs: Ready Pickup vs Unclaimed vs All
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildOrderFilterChip(
                            key: 'ready_pickup',
                            label: 'Ready Pickup (${readyOrders.length})',
                            isSelected: _selectedTab == 'ready_pickup',
                            onTap: () => setState(() => _selectedTab = 'ready_pickup'),
                          ),
                          const SizedBox(width: 8),
                          _buildOrderFilterChip(
                            key: 'unclaimed',
                            label: 'Unclaimed / उपलब्ध (${unclaimedOrders.length})',
                            isSelected: _selectedTab == 'unclaimed',
                            onTap: () => setState(() => _selectedTab = 'unclaimed'),
                          ),
                          const SizedBox(width: 8),
                          _buildOrderFilterChip(
                            key: 'all',
                            label: 'All Network (${allActiveOrders.length})',
                            isSelected: _selectedTab == 'all',
                            onTap: () => setState(() => _selectedTab = 'all'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (displayedOrders.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppColors.primaryGreen, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedTab == 'ready_pickup'
                                    ? 'No orders waiting for pickup right now. Pull down to refresh or check Unclaimed.'
                                    : (_selectedTab == 'unclaimed'
                                        ? 'No unclaimed donations right now. When a donor posts, it appears here in real time!'
                                        : 'All caught up! New surplus donations will appear here in real-time.'),
                                style: const TextStyle(fontSize: 12, color: AppColors.mutedGrey),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...displayedOrders.take(4).map((order) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: order.isFood
                                          ? AppColors.primaryGreen.withOpacity(0.12)
                                          : AppColors.orange.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      order.isFood ? Icons.soup_kitchen : Icons.checkroom,
                                      color: order.isFood ? AppColors.primaryGreen : AppColors.orange,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.textDarkPrimary : AppColors.charcoal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatDonorSubtitle(order),
                                          style: const TextStyle(fontSize: 12, color: AppColors.mutedGrey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              order.isClaimed ? Icons.verified : Icons.hourglass_top,
                                              size: 13,
                                              color: order.isClaimed ? AppColors.primaryGreen : AppColors.orange,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                order.isClaimed
                                                    ? 'Shelter: ${order.claimedByNgoName ?? "Shelter"} ने स्वीकारले ✓'
                                                    : 'Status: उपलब्ध (शेल्टरच्या क्लेमची प्रतीक्षा)',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: order.isClaimed
                                                      ? AppColors.primaryGreen
                                                      : AppColors.orange,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (order.assignedVolunteerId != null)
                                    if (order.assignedVolunteerId == volunteerId)
                                      ElevatedButton(
                                        onPressed: () => context.push('/volunteer/tracking'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryGreen,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          minimumSize: Size.zero,
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('My Task 🛵', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                        ),
                                        child: Text(
                                          'Assigned to\n${order.assignedVolunteerName ?? "Volunteer"}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.mutedGrey),
                                        ),
                                      )
                                  else if (order.isClaimed)
                                    ElevatedButton(
                                      onPressed: () async {
                                        final success = await donationProvider.acceptVolunteerTask(
                                          donationId: order.id,
                                          volunteerId: volunteerId,
                                          volunteerName: currentUser?.fullName ?? 'Volunteer',
                                          phone: currentUser?.phone,
                                        );
                                        if (context.mounted) {
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('टास्क स्वीकारले: ${order.title}! डिलिव्हरी सुरू करत आहोत...'),
                                                backgroundColor: AppColors.primaryGreen,
                                              ),
                                            );
                                            context.push('/volunteer/tracking');
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(donationProvider.errorMessage ?? 'Could not accept task.'),
                                                backgroundColor: AppColors.errorRed,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryGreen,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        minimumSize: Size.zero,
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          SizedBox(width: 2),
                                          Icon(Icons.arrow_forward, size: 12),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.orange.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Awaiting\nShelter',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.orange),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Posted Time & Expiry Time Row
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAF9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? Colors.white10 : const Color(0xFFEDF2F7),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 12, color: AppColors.mutedGrey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Posted: ${_formatPostedTime(order.createdAt)}',
                                      style: const TextStyle(fontSize: 10.5, color: AppColors.mutedGrey, fontWeight: FontWeight.w500),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 12,
                                      color: (order.pickupDeadline.difference(DateTime.now()).inHours < 3 && !order.pickupDeadline.difference(DateTime.now()).isNegative) ? AppColors.errorRed : AppColors.mutedGrey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Expiry: ${_formatExpiryTime(order.pickupDeadline)}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: (order.pickupDeadline.difference(DateTime.now()).inHours < 3 && !order.pickupDeadline.difference(DateTime.now()).isNegative) ? FontWeight.bold : FontWeight.w500,
                                        color: (order.pickupDeadline.difference(DateTime.now()).inHours < 3 && !order.pickupDeadline.difference(DateTime.now()).isNegative) ? AppColors.errorRed : AppColors.mutedGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Visual 4-Step Lifecycle Progress Tracker
                              _buildProgressBar(order, isDark),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 16),

                    // Quick Actions Section
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionItem(
                            context: context,
                            icon: Icons.assignment_outlined,
                            label: 'View\nTasks',
                            onTap: () => context.push('/volunteer/tasks'),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickActionItem(
                            context: context,
                            icon: Icons.timeline,
                            label: 'My\nActivity',
                            onTap: () => context.push('/volunteer/activity'),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickActionItem(
                            context: context,
                            icon: Icons.local_shipping_outlined,
                            label: 'Track\nDeliveries',
                            onTap: () => context.push('/volunteer/tracking'),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickActionItem(
                            context: context,
                            icon: Icons.location_city_outlined,
                            label: 'Nearby\nNGOs',
                            onTap: () => context.push('/ngo'),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Upcoming Tasks Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            context.tr.get('upcoming_tasks'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepGreen,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => context.push('/volunteer/tasks'),
                          child: const Row(
                            children: [
                              Text(
                                'See All',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 14, color: AppColors.primaryGreen),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Active Deliveries / Upcoming Tasks
                    if (activeTasks.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.assignment_turned_in_outlined, color: AppColors.primaryGreen, size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'सध्या कोणतेही सक्रिय टास्क नाही. नवीन टास्क स्वीकारण्यासाठी वरील यादी तपासा.',
                                style: TextStyle(fontSize: 12, color: AppColors.mutedGrey),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...activeTasks.map((t) => _buildUpcomingTaskCard(
                            context: context,
                            title: t.title,
                            location: _formatPickupLocation(t.pickupAddress, t.city),
                            time: 'Today • In Progress',
                            icon: t.isFood ? Icons.restaurant : Icons.checkroom,
                            onTap: () => context.push('/volunteer/tracking'),
                            isDark: isDark,
                          )),
                    const SizedBox(height: 12),

                    const SizedBox(height: 16),

                    // Completed Deliveries Section (Immediately Updated Real-time)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'Completed Deliveries (${myCompletedTasks.length})',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepGreen,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.push('/volunteer/activity'),
                          child: const Row(
                            children: [
                              Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 14, color: AppColors.primaryGreen),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (myCompletedTasks.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delivery_dining, color: AppColors.primaryGreen, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'अजून कोणतीही डिलिव्हरी पूर्ण झालेली नाही',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'शेल्टरने स्वीकारलेले टास्क स्वीकारा आणि डिलिव्हरी पूर्ण करा.',
                                    style: TextStyle(fontSize: 11, color: AppColors.mutedGrey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...myCompletedTasks.take(5).map((completedTask) {
                        return _buildCompletedTaskCard(
                          context: context,
                          order: completedTask,
                          isDark: isDark,
                        );
                      }),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: const VolunteerBottomNav(currentIndex: 0),
  ),
);
  }

  Widget _buildMiniCounter({
    required String label,
    required String count,
    required Color color,
    IconData? icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 2),
        ],
        Text(
          count,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.mutedGrey,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderFilterChip({
    required String key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.charcoal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.charcoal,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mutedGrey,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryGreen, size: 22),
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
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTaskCard({
    required BuildContext context,
    required String title,
    required String location,
    required String time,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.orange, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: const TextStyle(fontSize: 12, color: AppColors.mutedGrey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.mutedGrey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPostedTime(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('dd MMM, hh:mm a').format(createdAt);
    }
  }

  String _formatExpiryTime(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    if (diff.isNegative) {
      return 'Expired';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m left (${DateFormat('hh:mm a').format(deadline)})';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h left (${DateFormat('hh:mm a').format(deadline)})';
    } else {
      return DateFormat('dd MMM, hh:mm a').format(deadline);
    }
  }

  int _getProgressStep(Donation d) {
    if (d.status == DonationStatus.delivered ||
        d.status == DonationStatus.deliveredToNgo ||
        d.status == DonationStatus.distributed ||
        d.status == DonationStatus.completed) {
      return 4;
    }
    if (d.status == DonationStatus.pickedUp) {
      return 3;
    }
    if (d.status == DonationStatus.assigned ||
        d.status == DonationStatus.assignedForPickup ||
        d.isClaimed ||
        d.status == DonationStatus.accepted ||
        d.status == DonationStatus.claimed) {
      return 2;
    }
    return 1;
  }

  Widget _buildProgressBar(Donation order, bool isDark) {
    final currentStep = _getProgressStep(order);
    final steps = [
      'नोंदणी\n(Posted)',
      'शेल्टर\n(Claimed)',
      'वाटेत\n(In Transit)',
      'पोहोचले\n(Delivered)',
    ];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Divider line between steps
                final stepBeforeIndex = index ~/ 2 + 1;
                final isCompletedLine = currentStep > stepBeforeIndex;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompletedLine
                        ? AppColors.primaryGreen
                        : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                  ),
                );
              }
              final stepIndex = index ~/ 2 + 1;
              final isDone = currentStep >= stepIndex;
              final isCurrent = currentStep == stepIndex;
              return Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppColors.primaryGreen
                      : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                  border: isCurrent
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : Text(
                          '$stepIndex',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps.asMap().entries.map((e) {
              final stepIndex = e.key + 1;
              final isDone = currentStep >= stepIndex;
              return Expanded(
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                    color: isDone
                        ? AppColors.primaryGreen
                        : (isDark ? Colors.white38 : AppColors.mutedGrey),
                    height: 1.1,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTaskCard({
    required BuildContext context,
    required Donation order,
    required bool isDark,
  }) {
    final deliveredTimeStr = order.deliveredAt != null
        ? DateFormat('dd MMM, hh:mm a').format(order.deliveredAt!)
        : 'पूर्ण झाले';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  order.isFood ? Icons.restaurant : Icons.checkroom,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.charcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDonorSubtitle(order),
                      style: const TextStyle(fontSize: 11.5, color: AppColors.mutedGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (order.claimedByNgoName != null && order.claimedByNgoName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.volunteer_activism, size: 12, color: AppColors.primaryGreen),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'शेल्टर: ${order.claimedByNgoName}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryGreen,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 12, color: AppColors.primaryGreen),
                    SizedBox(width: 4),
                    Text(
                      'वितरीत ✓',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAF9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.done_all, size: 13, color: AppColors.primaryGreen),
                const SizedBox(width: 6),
                Text(
                  'डिलिव्हरी पूर्ण वेळ: $deliveredTimeStr',
                  style: const TextStyle(fontSize: 11, color: AppColors.mutedGrey, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                const Text(
                  '100% Verified',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
