import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:foodbridge/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodbridge/core/theme/theme_provider.dart';
import 'package:foodbridge/core/localization/locale_provider.dart';
import 'package:foodbridge/features/authentication/presentation/auth_provider.dart';
import 'package:foodbridge/features/donations/presentation/donation_provider.dart';
import 'package:foodbridge/features/notifications/presentation/notification_provider.dart';
import 'package:foodbridge/features/admin/presentation/admin_provider.dart';

void main() {
  testWidgets('FoodBridgeApp smoke test - splash screen and onboarding load', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({}); // simulate a clean first install
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => DonationProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
        ],
        child: const FoodBridgeApp(),
      ),
    );

    // Initial frame renders splash screen
    expect(find.text('FoodBridge'), findsOneWidget);
    expect(find.text('Share More. Waste Less. Bridge the Need.'), findsOneWidget);

    // Fast-forward past the splash screen timer (1200ms).
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // First launch lands on the permission request screen before onboarding.
    expect(find.text('Permissions Needed'), findsOneWidget);

    // Grant permissions: scroll the Allow All button into view and tap it.
    final allowAllButton = find.text('Allow All Permissions');
    await tester.scrollUntilVisible(
      allowAllButton,
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(allowAllButton);
    // The button shows an infinite spinner while requesting; use bounded pumps.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Onboarding / Role selection screen is rendered afterwards.
    expect(find.text('Select Your Role'), findsOneWidget);
    expect(find.text('Restaurant\nDonor'), findsOneWidget);
    expect(find.text('Normal\nDonor'), findsOneWidget);
    expect(find.text('Volunteer'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
