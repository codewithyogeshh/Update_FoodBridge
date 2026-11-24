import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:foodbridge/core/localization/locale_provider.dart';
import 'package:foodbridge/core/theme/app_theme.dart';
import 'package:foodbridge/core/theme/theme_provider.dart';
import 'package:foodbridge/features/admin/presentation/admin_provider.dart';
import 'package:foodbridge/features/authentication/presentation/auth_provider.dart';
import 'package:foodbridge/features/donations/domain/models/donation.dart';
import 'package:foodbridge/features/donations/presentation/donation_provider.dart';
import 'package:foodbridge/features/notifications/presentation/notification_provider.dart';
import 'package:foodbridge/features/volunteer/presentation/volunteer_rewards_screen.dart';
import 'package:foodbridge/features/volunteer/presentation/widgets/nss_certificate_modal.dart';

Donation _completed({
  required String id,
  required String volunteerId,
  String volunteerName = 'Volunteer',
  double quantity = 10,
}) {
  return Donation(
    id: id,
    donorId: 'donor-1',
    donorName: 'Donor',
    title: 'Task $id',
    description: 'desc',
    quantity: quantity,
    unit: 'meals',
    type: DonationType.food,
    pickupAddress: 'Powai Naka, Satara',
    createdAt: DateTime.now(),
    pickupDeadline: DateTime.now().add(const Duration(hours: 3)),
    assignedVolunteerId: volunteerId,
    assignedVolunteerName: volunteerName,
    deliveredAt: DateTime.now(),
    status: DonationStatus.delivered,
  );
}

class _TestDonationProvider extends DonationProvider {
  _TestDonationProvider(List<Donation> donations) {
    _donations = donations;
  }

  List<Donation> _donations = [];

  @override
  List<Donation> get allDonations => _donations;
}

Widget _createTestableWidget(List<Donation> donations) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider<DonationProvider>.value(value: _TestDonationProvider(donations)),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ChangeNotifierProvider(create: (_) => AdminProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const VolunteerRewardsScreen(),
    ),
  );
}

void main() {
  group('VolunteerRewardsScreen Gamification Tests', () {
    testWidgets('shows empty leaderboard message when no deliveries exist', (tester) async {
      await tester.pumpWidget(_createTestableWidget([]));
      await tester.pump();

      expect(find.text('Leaderboard 🏆'), findsOneWidget);
      expect(find.textContaining('No deliveries yet'), findsOneWidget);
      expect(find.text('Generate NSS Certificate (PDF)'), findsOneWidget);
    });

    testWidgets('renders leaderboard rows with rank and karma points when data exists', (tester) async {
      final donations = [
        _completed(id: 'v1a', volunteerId: 'vol-1', volunteerName: 'Karan', quantity: 20),
        _completed(id: 'v1b', volunteerId: 'vol-1', volunteerName: 'Karan', quantity: 20),
        _completed(id: 'v2a', volunteerId: 'vol-2', volunteerName: 'Rohit', quantity: 10),
      ];

      await tester.pumpWidget(_createTestableWidget(donations));
      await tester.pump();

      expect(find.text('Leaderboard 🏆'), findsOneWidget);
      expect(find.text('Karan'), findsWidgets);
      expect(find.text('Rohit'), findsOneWidget);
      // 2 deliveries for Karan => 2*50 + 40*2 = 180; rank 1.
      // 1 delivery for Rohit => 50 + 10*2 = 70; rank 2.
      expect(find.text('180'), findsWidgets);
      expect(find.text('70'), findsOneWidget);
      expect(find.text('2 deliveries'), findsWidgets);
      expect(find.text('1 deliveries'), findsOneWidget);
    });

    testWidgets('live karma points and rank appear in the hero banner', (tester) async {
      final donations = [
        _completed(id: 'a', volunteerId: 'vol-1', quantity: 25),
      ];

      await tester.pumpWidget(_createTestableWidget(donations));
      await tester.pump();

      // Karma: 1 delivery = 50 + 25*2 = 100.
      expect(find.text('Karma Points'), findsOneWidget);
      expect(find.text('100'), findsWidgets);
      expect(find.text('Your Rank'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
    });

    testWidgets('collects college name then opens NSS certificate modal', (tester) async {
      await tester.pumpWidget(_createTestableWidget([]));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Generate NSS Certificate (PDF)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Generate NSS Certificate (PDF)'));
      await tester.pumpAndSettle();

      expect(find.text('NSS / College Certificate'), findsWidgets);

      await tester.enterText(find.byType(TextField), 'Sinhgad College');
      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();

      expect(find.text('NSS / College Volunteer Certificate'), findsOneWidget);
      expect(find.text('Download / Print Official PDF'), findsOneWidget);
      expect(find.textContaining('Sinhgad College'), findsOneWidget);
    });
  });
}
