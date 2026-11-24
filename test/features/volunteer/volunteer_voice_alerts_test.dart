import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:foodbridge/core/localization/locale_provider.dart';
import 'package:foodbridge/core/services/voice_alert_service.dart';
import 'package:foodbridge/core/theme/app_theme.dart';
import 'package:foodbridge/core/theme/theme_provider.dart';
import 'package:foodbridge/features/admin/presentation/admin_provider.dart';
import 'package:foodbridge/features/authentication/domain/models/app_user.dart';
import 'package:foodbridge/features/authentication/presentation/auth_provider.dart';
import 'package:foodbridge/features/donations/domain/models/donation.dart';
import 'package:foodbridge/features/donations/presentation/donation_provider.dart';
import 'package:foodbridge/features/notifications/presentation/notification_provider.dart';
import 'package:foodbridge/features/volunteer/presentation/volunteer_task_tracking_screen.dart';

Donation _activeTask({
  required String id,
  required String volunteerId,
  double distanceKm = 2.0,
}) {
  return Donation(
    id: id,
    donorId: 'donor-1',
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
    assignedVolunteerId: volunteerId,
    claimedByNgoName: 'Asha Children Foundation',
    estimatedDistanceKm: distanceKm,
  );
}

class _TestDonationProvider extends DonationProvider {
  _TestDonationProvider(List<Donation> donations) {
    _donations = donations;
  }

  List<Donation> _donations = [];

  @override
  List<Donation> get allDonations => _donations;

  /// The tracking screen resolves the current task through
  /// [getVolunteerActiveTasks], which reads the base class's private
  /// `_donations`. Mirror the override here so the seeded tasks are seen.
  @override
  List<Donation> getVolunteerActiveTasks(String volunteerId) => _donations
      .where(
        (d) =>
            d.assignedVolunteerId == volunteerId &&
            !d.isDelivered &&
            d.deliveredAt == null &&
            (d.status == DonationStatus.assigned ||
                d.status == DonationStatus.assignedForPickup ||
                d.status == DonationStatus.pickedUp),
      )
      .toList();
}

/// The mock volunteer account that signs in as the courier.
const String _kVolunteerId = 'usr-vol-303';

Widget _createTrackingScreen(List<Donation> donations, AuthProvider authProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<DonationProvider>.value(
        value: _TestDonationProvider(donations),
      ),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ChangeNotifierProvider(create: (_) => AdminProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const VolunteerTaskTrackingScreen(),
    ),
  );
}

/// Creates an AuthProvider signed in as the mock volunteer courier.
Future<AuthProvider> _authVolunteer() async {
  final auth = AuthProvider();
  await auth.login(
    email: 'volunteer@foodbridge.org',
    password: 'Password123!',
    requestedRole: UserRole.volunteer,
  );
  return auth;
}

void main() {
  setUp(() {
    VoiceAlertService.instance.resetForTest();
  });

  group('Volunteer Task Tracking Voice Alerts', () {
    testWidgets('announces pickup with marathi distance when an active task loads', (tester) async {
      final auth = await _authVolunteer();
      final donations = [
        _activeTask(id: 'dn-active-1', volunteerId: _kVolunteerId, distanceKm: 2.0),
      ];

      await tester.pumpWidget(_createTrackingScreen(donations, auth));
      await tester.pump();

      expect(VoiceAlertService.instance.lastSpoken, contains('नवीन अन्न पिकअप'));
      expect(VoiceAlertService.instance.lastSpoken, contains('२ किलोमीटर'));
    });

    testWidgets('announces pickup only once for the same task', (tester) async {
      final auth = await _authVolunteer();
      final donations = [
        _activeTask(id: 'dn-active-2', volunteerId: _kVolunteerId, distanceKm: 3.0),
      ];

      await tester.pumpWidget(_createTrackingScreen(donations, auth));
      await tester.pump();
      await tester.pump();

      expect(VoiceAlertService.instance.lastSpoken, contains('नवीन अन्न पिकअप'));
    });
  });
}
