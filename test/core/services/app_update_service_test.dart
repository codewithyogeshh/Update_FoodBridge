import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/core/services/app_update_service.dart';
import 'package:foodbridge/core/widgets/app_update_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUpdateService Tests', () {
    test('checkForUpdate returns valid update metadata under test mode', () async {
      final info = await AppUpdateService.instance.checkForUpdate();

      expect(info, isNotNull);
      expect(info!.hasUpdate, isTrue);
      expect(info.latestVersion, equals('1.0.1'));
      expect(info.currentVersion, equals('1.0.0'));
      expect(info.apkDownloadUrl, isNotEmpty);
      expect(info.releaseNotes, isNotEmpty);
    });

    test('downloadApk streams progress and returns valid file reference', () async {
      double lastProgress = 0.0;
      int received = 0;
      int total = 0;

      final file = await AppUpdateService.instance.downloadApk(
        apkUrl: AppUpdateService.fallbackApkUrl,
        onProgress: (prog, r, t) {
          lastProgress = prog;
          received = r;
          total = t;
        },
      );

      expect(file, isNotNull);
      expect(lastProgress, equals(1.0));
      expect(received, greaterThan(0));
      expect(total, greaterThan(0));
    });

    test('installApk succeeds under test environment', () async {
      final file = await AppUpdateService.instance.downloadApk(
        apkUrl: AppUpdateService.fallbackApkUrl,
        onProgress: (_, _, _) {},
      );

      expect(file, isNotNull);
      final installed = await AppUpdateService.instance.installApk(file!);
      expect(installed, isTrue);
    });
  });

  group('AppUpdateDialog Widget Tests', () {
    testWidgets('AppUpdateDialog renders update info and action buttons', (tester) async {
      const updateInfo = AppUpdateInfo(
        latestVersion: '1.0.2',
        latestBuildNumber: 3,
        currentVersion: '1.0.0',
        currentBuildNumber: 1,
        hasUpdate: true,
        releaseNotes: 'नवीन सुधारणा आणि बग फिक्सेस.',
        apkDownloadUrl: 'https://github.com/codewithyogeshh/Update_FoodBridge/releases/latest/download/app-release.apk',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppUpdateDialog(updateInfo: updateInfo),
          ),
        ),
      );

      expect(find.text('नवीन अपडेट उपलब्ध आहे! 🚀'), findsOneWidget);
      expect(find.text('v1.0.2 उपलब्ध (चालू: v1.0.0)'), findsOneWidget);
      expect(find.text('नवीन सुधारणा आणि बग फिक्सेस.'), findsOneWidget);
      expect(find.text('थेट ॲपमध्ये अपडेट करा (1-Tap Update)'), findsOneWidget);
      expect(find.text('ब्राउझरमधून डाऊनलोड करा'), findsOneWidget);
      expect(find.text('नंतर करा (Later)'), findsOneWidget);

      // Tap 1-Tap Update button
      await tester.tap(find.text('थेट ॲपमध्ये अपडेट करा (1-Tap Update)'));
      await tester.pumpAndSettle();

      expect(find.text('आत्ता इन्स्टॉल करा (Install Now)'), findsOneWidget);
    });
  });
}
