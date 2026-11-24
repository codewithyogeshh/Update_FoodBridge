import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/core/services/ai_service.dart';
import 'package:foodbridge/features/donor/presentation/widgets/gemini_food_scanner_card.dart';

void main() {
  group('Gemini AI Food Freshness Scanner Tests', () {
    late AIService aiService;

    setUp(() {
      aiService = AIService();
    });

    test('scanFoodFreshness accurately classifies cooked rice/biryani with safe holding guidelines', () async {
      final result = await aiService.scanFoodFreshness(hintText: 'Fresh veg biryani in foil container');

      expect(result.foodTitle, contains('Biryani'));
      expect(result.isVeg, isTrue);
      expect(result.storageCondition, equals('hot'));
      expect(result.safeShelfLifeHours, equals(4));
      expect(result.isSafePackaging, isTrue);
      expect(result.detectedItems, isNotEmpty);
      expect(result.marathiSummary, contains('Gemini AI'));
    });

    test('scanFoodFreshness classifies bakery items with extended ambient shelf life', () async {
      final result = await aiService.scanFoodFreshness(hintText: 'Assorted bakery bread buns');

      expect(result.foodTitle, contains('Breads'));
      expect(result.safeShelfLifeHours, equals(24));
      expect(result.storageCondition, equals('ambient'));
      expect(result.isSafePackaging, isTrue);
      expect(result.hygieneStatus, contains('Grade A'));
    });

    test('scanFoodFreshness classifies raw produce with multi-day longevity', () async {
      final result = await aiService.scanFoodFreshness(hintText: 'Fresh vegetable produce crate');

      expect(result.foodTitle, contains('Vegetables'));
      expect(result.safeShelfLifeHours, equals(48));
      expect(result.isSafePackaging, isTrue);
    });

    test('scanFoodFreshness defaults to wholesome chapati-sabzi meal', () async {
      final result = await aiService.scanFoodFreshness();

      expect(result.foodTitle, contains('Chapati'));
      expect(result.isVeg, isTrue);
      expect(result.safeShelfLifeHours, equals(5));
      expect(result.confidenceScore, greaterThanOrEqualTo(0.90));
      expect(result.detectedItems.any((i) => i.contains('चपाती')), isTrue);
    });

    testWidgets('GeminiFoodScannerCard renders camera and gallery scan options', (tester) async {
      FoodFreshnessScanResult? callbackResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeminiFoodScannerCard(
              onScanComplete: (res, _) {
                callbackResult = res;
              },
            ),
          ),
        ),
      );

      expect(find.text('Gemini AI Food Scanner'), findsOneWidget);
      expect(find.text('कॅमेऱ्याने स्कॅन करा'), findsOneWidget);
      expect(find.text('गॅलरीतून निवडा'), findsOneWidget);

      await tester.tap(find.text('कॅमेऱ्याने स्कॅन करा'));
      await tester.pumpAndSettle();

      expect(callbackResult, isNotNull);
      expect(callbackResult!.safeShelfLifeHours, greaterThan(0));
      expect(find.text(callbackResult!.foodTitle), findsOneWidget);
      expect(find.text('पुन्हा स्कॅन करा (Rescan)'), findsOneWidget);
    });
  });
}
