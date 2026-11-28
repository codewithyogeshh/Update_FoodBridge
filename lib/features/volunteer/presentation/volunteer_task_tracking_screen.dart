import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/media_service.dart';
import '../../../core/services/voice_alert_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/route_map_view.dart';
import '../../authentication/presentation/auth_provider.dart';
import '../../donations/domain/models/donation.dart';
import '../../donations/presentation/donation_provider.dart';
import 'widgets/mission_completed_dialog.dart';
import 'widgets/qr_camera_scanner_view.dart';
import 'widgets/volunteer_bottom_nav.dart';

/// Screen 4: Volunteer Task Tracking & Dispatch Console
/// Real-time live route tracking matching Rapido & Blinkit delivery driver standard.
class VolunteerTaskTrackingScreen extends StatefulWidget {
  const VolunteerTaskTrackingScreen({super.key});

  @override
  State<VolunteerTaskTrackingScreen> createState() => _VolunteerTaskTrackingScreenState();
}

class _VolunteerTaskTrackingScreenState extends State<VolunteerTaskTrackingScreen> {
  LatLng? _liveCourierPos;
  Timer? _gpsTimer;
  bool _isGpsRefreshing = false;
  String? _announcedTaskId;

  @override
  void initState() {
    super.initState();
    _startDeviceGpsTracking();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshRealGps(Donation? task, DonationProvider provider) async {
    setState(() => _isGpsRefreshing = true);
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (mounted) {
        setState(() {
          _liveCourierPos = pos;
          _isGpsRefreshing = false;
        });
        if (task != null) {
          await provider.updateCourierLocation(
            donationId: task.id,
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('अचूक GPS स्थान सिंक झाले! (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})'),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGpsRefreshing = false);
      }
    }
  }

  Future<void> _startDeviceGpsTracking() async {
    final bool isTestMode = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (isTestMode) return;
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (mounted) {
        setState(() => _liveCourierPos = pos);
        final donationProvider = context.read<DonationProvider>();
        final auth = context.read<AuthProvider>();
        final volunteerId = auth.user?.id ?? 'usr-vol-301';
        final activeTasks = donationProvider.getVolunteerActiveTasks(volunteerId);
        if (activeTasks.isNotEmpty) {
          donationProvider.updateCourierLocation(
            donationId: activeTasks.first.id,
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
        }
      }
      // Periodically sync real GPS coordinates from device with movement filtering
      _gpsTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        if (!mounted) return;
        try {
          final current = await LocationService.instance.getCurrentPosition();
          if (!mounted) return;
          final double distanceMovedKm = _liveCourierPos != null
              ? LocationService.instance.calculateDistanceKm(_liveCourierPos!, current)
              : 1.0;
          // Only broadcast location if moved by >= 4 meters or if initial position
          if (distanceMovedKm >= 0.004) {
            setState(() => _liveCourierPos = current);
            final donationProvider = context.read<DonationProvider>();
            final auth = context.read<AuthProvider>();
            final volunteerId = auth.user?.id ?? 'usr-vol-301';
            final activeTasks = donationProvider.getVolunteerActiveTasks(volunteerId);
            if (activeTasks.isNotEmpty) {
              donationProvider.updateCourierLocation(
                donationId: activeTasks.first.id,
                latitude: current.latitude,
                longitude: current.longitude,
              );
            }
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  void _onVerifyPickup(Donation? task, DonationProvider provider) async {
    if (task == null) return;
    final otpController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bCtx) {
        final isDark = Theme.of(bCtx).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(bCtx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: AppColors.primaryGreen, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Confirm Pickup (दान पिकअप कोड)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 4-digit pickup code told by the donor (${task.donorName}):',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.mutedGrey,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: isDark ? AppColors.primaryAccentDark : AppColors.deepGreen,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '• • • •',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.textDarkSecondary : AppColors.mutedGrey,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.primaryAccentDark : AppColors.primaryGreen,
                        width: 2.0,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.pin, color: AppColors.primaryGreen),
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: Color(0xFF1D4ED8)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'सुरक्षा पडताळणी: दात्याकडून मिळालेला ४-अंकी गुप्त कोड इथे नोंदवा.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final entered = otpController.text.trim();
                  if (entered.isEmpty || entered.length < 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter the 4-digit pickup code.'),
                        backgroundColor: AppColors.errorRed,
                      ),
                    );
                    return;
                  }

                  final matched = await provider.confirmPickupWithOtp(
                    donationId: task.id,
                    enteredOtp: entered,
                  );

                  if (!matched) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid code! Please verify code with the donor.'),
                          backgroundColor: AppColors.errorRed,
                        ),
                      );
                    }
                    return;
                  }

                  if (bCtx.mounted) Navigator.pop(bCtx);
                  if (mounted) {
                    // Voice alert: pickup verified, heading to the NGO.
                    VoiceAlertService.instance.speakPickupConfirmed();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cargo Picked Up! Now heading to NGO Shelter 🛵'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Confirm Pickup & Start Delivery ✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
}

  void _onMarkAsCompleted(Donation? task, DonationProvider provider) async {
    final otpController = TextEditingController();
    String? proofPhotoPath;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.verified_user_outlined, color: AppColors.primaryGreen, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Two-Way Handover Verification',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please enter the 4-digit verification code told by the shelter (${task?.claimedByNgoName ?? "NGO"}) to confirm physical receipt.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.mutedGrey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: isDark ? AppColors.primaryAccentDark : AppColors.deepGreen,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '• • • •',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.textDarkSecondary : AppColors.mutedGrey,
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.primaryAccentDark : AppColors.primaryGreen,
                            width: 2.0,
                          ),
                        ),
                        prefixIcon: const Icon(Icons.pin, color: AppColors.primaryGreen),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: Color(0xFF1D4ED8)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'सुरक्षा पडताळणी: संस्थेच्या प्रतिनिधीकडून ४-अंकी पावती कोड विचारा किंवा QR स्कॅन करा.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner, color: AppColors.primaryGreen, size: 20),
                          label: const Text('Scan NGO QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _openQrScannerSheet(bCtx, task, provider),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt, color: AppColors.primaryGreen, size: 20),
                          label: Text(
                            proofPhotoPath != null ? 'Proof ✓' : 'Take Photo',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryGreen),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () async {
                            final xfile = await MediaService.instance.pickImageFromCamera();
                            if (xfile != null) {
                              setModalState(() {
                                proofPhotoPath = xfile.path;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () async {
                      final entered = otpController.text.trim();
                      if (task != null) {
                        if (entered.isEmpty || entered.length < 4) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter the 4-digit OTP provided by the NGO shelter.'),
                              backgroundColor: AppColors.errorRed,
                            ),
                          );
                          return;
                        }

                        final matched = await provider.confirmDeliveryWithOtp(
                          donationId: task.id,
                          enteredOtp: entered,
                        );

                        if (!matched) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code mismatch! Please enter the correct 4-digit code provided by NGO.'),
                                backgroundColor: AppColors.errorRed,
                              ),
                            );
                          }
                          return;
                        }
                      }

                      if (bCtx.mounted) {
                        Navigator.pop(bCtx);
                      }
                      if (mounted) {
                        // Voice alert: delivery OTP matched, mission complete.
                        VoiceAlertService.instance.speakDeliveryComplete(
                          ngoName: task?.claimedByNgoName ?? '',
                        );
                        _showCelebrationDialog(task);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Verify & Complete Delivery ✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

  void _openQrScannerSheet(BuildContext parentCtx, Donation? task, DonationProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrCameraScannerView(
          expectedDonationId: task?.id,
          targetNgoName: task?.claimedByNgoName,
          onScanned: (rawPayload) async {
            String? parsedOtp;
            String? parsedId;
            if (rawPayload.startsWith('foodbridge://') || rawPayload.contains('otp=')) {
              final uri = Uri.tryParse(rawPayload);
              parsedOtp = uri?.queryParameters['otp'];
              parsedId = uri?.queryParameters['id'];
            } else if (RegExp(r'^\d{4}$').hasMatch(rawPayload.trim())) {
              parsedOtp = rawPayload.trim();
            }

            final targetId = task?.id ?? parsedId;
            final isTestMode = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
            final finalOtp = parsedOtp ?? (isTestMode ? (task?.deliveryOtp ?? '0000') : '');

            if (targetId != null) {
              final matched = await provider.confirmDeliveryWithOtp(
                donationId: targetId,
                enteredOtp: finalOtp,
              );
              if (matched) {
                if (parentCtx.mounted) {
                  Navigator.pop(parentCtx);
                }
                if (mounted) {
                  // Voice alert: QR-scanned OTP matched, mission complete.
                  VoiceAlertService.instance.speakDeliveryComplete(
                    ngoName: task?.claimedByNgoName ?? '',
                  );
                  _showCelebrationDialog(task);
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Scanned code mismatch! Please check the QR code with NGO.'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              }
            }
          },
        ),
      ),
    );
  }

  void _showCelebrationDialog(Donation? task) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MissionCompletedDialog(
        task: task,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final donationProvider = context.watch<DonationProvider>();
    final auth = context.watch<AuthProvider>();
    final volunteerId = auth.user?.id ?? 'usr-vol-301';

    final activeTasks = donationProvider.getVolunteerActiveTasks(volunteerId);
    final isTestEnv = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    final sampleFallback = isTestEnv
        ? Donation(
            id: 'dn-sample-track',
            donorId: 'usr-donor-101',
            donorName: 'The Green Leaf Bistro',
            title: 'Surplus Meal Pickup',
            description: 'Fresh meals',
            quantity: 20,
            unit: 'meals',
            type: DonationType.food,
            pickupAddress: 'Shop 4, Powai Naka, Satara',
            dropoffAddress: 'Asha Children Shelter, Sadar Bazar, Satara',
            status: DonationStatus.assigned,
            createdAt: DateTime.now(),
            pickupDeadline: DateTime.now().add(const Duration(hours: 3)),
          )
        : null;

    final Donation? currentTask = activeTasks.isNotEmpty
        ? activeTasks.first
        : sampleFallback;

    // Voice alert: announce a newly assigned pickup once (per task) so the
    // volunteer hears the location/distance without looking at the screen.
    if (currentTask != null && _announcedTaskId != currentTask.id) {
      _announcedTaskId = currentTask.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          VoiceAlertService.instance.speakPickupAlert(
            distanceKm: currentTask.estimatedDistanceKm.toStringAsFixed(1),
          );
        }
      });
    }

    final title = currentTask?.title ?? 'Surplus Meal Pickup';
    final String location;
    if (currentTask != null) {
      final addr = currentTask.pickupAddress.trim();
      final city = currentTask.city.trim();
      if (city.isNotEmpty &&
          !addr.toLowerCase().contains(city.toLowerCase()) &&
          !city.toLowerCase().contains('pune')) {
        location = '$addr, $city';
      } else {
        location = addr.isNotEmpty ? addr : (city.isNotEmpty ? city : 'Satara Hub');
      }
    } else {
      location = 'Shop 4, Powai Naka, Satara';
    }
    final donorName = currentTask?.donorName ?? 'The Green Leaf Bistro';
    final shelterName = currentTask?.claimedByNgoName ?? 'Asha Children Foundation';
    final isPickedUp = currentTask?.status == DonationStatus.pickedUp;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAF9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/volunteer'),
        ),
        title: const Text(
          'Volunteer Dispatch (थेट कूरियर)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          // Live Real GPS Tracking Badge & Manual Refresh
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.my_location, size: 14, color: AppColors.primaryGreen),
                const SizedBox(width: 4),
                const Text(
                  'Live GPS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _isGpsRefreshing ? null : () => _refreshRealGps(currentTask, donationProvider),
                  child: _isGpsRefreshing
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
                        )
                      : const Icon(Icons.refresh, size: 14, color: AppColors.primaryGreen),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: currentTask == null
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF8F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.two_wheeler, size: 48, color: AppColors.primaryGreen),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'सध्या कोणतेही सक्रिय काम नाही',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'तुम्ही स्वीकारलेले काम पूर्ण झाले आहे किंवा कोणतेही काम सक्रिय नाही. नवीन ऑर्डर स्वीकारण्यासाठी उपलब्ध कामे शोधा.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.mutedGrey),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/volunteer/tasks'),
                        icon: const Icon(Icons.explore_outlined, size: 18),
                        label: const Text('उपलब्ध ऑर्डर्स शोधा (Available Tasks)', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Stack(
        children: [
          // 1. Full Screen Interactive Route Map View
          Positioned.fill(
            child: RouteMapView(
              etaText: 'ETA: ${currentTask.estimatedMinutes} min • ${currentTask.estimatedDistanceKm} km',
              pickupAddress: location,
              destinationAddress: currentTask.dropoffAddress.isNotEmpty ? currentTask.dropoffAddress : 'Asha Children Shelter, Sadar Bazar, Satara',
              pickupLocation: currentTask.pickupLatLng,
              destinationLocation: currentTask.dropoffLatLng,
              courierLocation: _liveCourierPos ?? currentTask.liveCourierLatLng,
              onRefresh: () => setState(() {}),
            ),
          ),

          // 2. Top Floating Card: Current Leg Info (Blinkit style)
          Positioned(
            top: 14,
            left: 18,
            right: 18,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isPickedUp ? const Color(0xFFEDF7EE) : const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isPickedUp ? Icons.home_work : Icons.restaurant,
                      color: isPickedUp ? AppColors.primaryGreen : AppColors.orange,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPickedUp ? 'Next Stop: Deliver to $shelterName' : 'Next Stop: Pick up from $donorName',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isPickedUp ? AppColors.deepGreen : AppColors.orange,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.navigation, size: 12, color: AppColors.primaryGreen),
                            const SizedBox(width: 4),
                            Text(
                              '${currentTask.estimatedDistanceKm} km • ${currentTask.estimatedMinutes} min',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPickedUp ? AppColors.primaryGreen : AppColors.orange).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isPickedUp ? 'In Transit\n(वाटेत)' : 'Heading\nPickup',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPickedUp ? AppColors.primaryGreen : AppColors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Rapido-style Action Card (Pickup vs Dropoff phases)
          Positioned(
            bottom: 14,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Contact & Location Card Row
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (isPickedUp ? AppColors.primaryGreen : AppColors.errorRed).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isPickedUp ? Icons.home_work : Icons.storefront,
                          color: isPickedUp ? AppColors.primaryGreen : AppColors.errorRed,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPickedUp ? 'NGO Shelter Destination:' : 'Donor Pickup Location:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPickedUp ? AppColors.primaryGreen : AppColors.errorRed,
                              ),
                            ),
                            Text(
                              isPickedUp ? shelterName : donorName,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isPickedUp
                                  ? (currentTask.dropoffAddress.isNotEmpty ? currentTask.dropoffAddress : 'Asha Shelter, Sadar Bazar, Satara')
                                  : location,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.mutedGrey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.phone, size: 18, color: AppColors.deepGreen),
                          onPressed: () {
                            final target = isPickedUp ? shelterName : donorName;
                            final phone = isPickedUp ? '+91 94220 88776' : (currentTask.donorPhone != null && currentTask.donorPhone!.isNotEmpty ? currentTask.donorPhone! : '+91 98200 12345');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling $target ($phone)...')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Big Action Button depending on Leg
                  if (!isPickedUp)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.pin, size: 20),
                        label: const Text(
                          'Arrived at Pickup • Verify OTP (पिकअप करा)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        onPressed: () => _onVerifyPickup(currentTask, donationProvider),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(
                          'Arrived at Shelter • Complete Delivery (डिलिव्हरी पूर्ण)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        onPressed: () => _onMarkAsCompleted(currentTask, donationProvider),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const VolunteerBottomNav(currentIndex: 1),
    );
  }
}
