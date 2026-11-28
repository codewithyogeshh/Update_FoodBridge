import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:foodbridge/core/theme/app_theme.dart';
import 'package:foodbridge/core/theme/theme_provider.dart';
import 'package:foodbridge/core/localization/locale_provider.dart';
import 'package:foodbridge/features/authentication/presentation/auth_provider.dart';
import 'package:foodbridge/features/onboarding/presentation/permission_request_screen.dart';
import 'package:foodbridge/features/donations/presentation/donation_provider.dart';
import 'package:foodbridge/features/notifications/presentation/notification_provider.dart';
import 'package:foodbridge/features/admin/presentation/admin_provider.dart';

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => DonationProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ChangeNotifierProvider(create: (_) => AdminProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

void main() {
  group('PermissionRequestScreen (first-launch flow)', () {
    testWidgets('renders all four permission tiles', (tester) async {
      await tester.pumpWidget(_wrap(const PermissionRequestScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Permissions Needed'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('SMS'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('shows the Allow All Permissions button', (tester) async {
      await tester.pumpWidget(_wrap(const PermissionRequestScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Allow All Permissions'), findsOneWidget);
    });

    testWidgets('tapping Allow All does not crash when platform plugins are unavailable',
        (tester) async {
      await tester.pumpWidget(_wrap(const PermissionRequestScreen()));
      await tester.pumpAndSettle();

      final allowAllButton = find.text('Allow All Permissions');
      // The button sits below the fold in the default test viewport, so scroll
      // it into view so the tap actually lands on it.
      await tester.scrollUntilVisible(
        allowAllButton,
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      await tester.tap(allowAllButton);

      // The button switches to an infinite spinner while permissions are being
      // requested, so pumpAndSettle would never settle. Use bounded pumps.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Should not throw; the screen hands off gracefully even with no plugin.
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows a fallback note that user can proceed without granting',
        (tester) async {
      await tester.pumpWidget(_wrap(const PermissionRequestScreen()));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('कोणतीही परवानगी नाकारली तरी'),
        findsOneWidget,
      );
    });
  });
}
