import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/core/services/certificate_service.dart';
import 'package:foodbridge/features/donations/domain/models/donation.dart';

void main() {
  group('CertificateService Impact & Generation Tests', () {
    late CertificateService certificateService;

    setUp(() {
      certificateService = CertificateService.instance;
    });

    test('calculateImpact computes accurate CO2 and environmental metrics for food', () {
      final foodDonation = Donation(
        id: 'dn-cert-101',
        donorId: 'd-cert-1',
        donorName: 'Green Kitchen Pune',
        title: '50 Veg Pulao Boxes',
        description: 'Fresh surplus food packs',
        quantity: 50,
        unit: 'meals',
        type: DonationType.food,
        pickupAddress: 'Shivajinagar, Pune',
        createdAt: DateTime.now(),
        pickupDeadline: DateTime.now().add(const Duration(hours: 4)),
        isVeg: true,
      );

      final impact = certificateService.calculateImpact(foodDonation);

      expect(impact.co2SavedKg, equals(95.0));
      expect(impact.waterSavedLiters, equals(21000));
      expect(impact.peopleNourished, equals(50));
      expect(impact.landfillSavedKg, equals(22.5));
      expect(impact.certificateId, startsWith('FB-HERO-'));
    });

    test('calculateImpact computes accurate metrics for non-food items', () {
      final clothDonation = Donation(
        id: 'dn-cert-102',
        donorId: 'd-cert-2',
        donorName: 'Priya Verma',
        title: '20 Winter Blankets',
        description: 'Warm blankets for winter drive',
        quantity: 20,
        unit: 'items',
        type: DonationType.clothing,
        pickupAddress: 'Kothrud, Pune',
        createdAt: DateTime.now(),
        pickupDeadline: DateTime.now().add(const Duration(days: 2)),
      );

      final impact = certificateService.calculateImpact(clothDonation);

      expect(impact.co2SavedKg, equals(72.0));
      expect(impact.waterSavedLiters, equals(28000));
      expect(impact.peopleNourished, equals(20));
      expect(impact.landfillSavedKg, equals(9.0));
      expect(impact.certificateId, startsWith('FB-HERO-'));
    });

    test('generateCertificatePdf returns non-empty byte buffer in test environment', () async {
      final sampleDonation = Donation(
        id: 'dn-cert-103',
        donorId: 'd-cert-3',
        donorName: 'Aarti Sharma',
        title: '15 Meal Packs',
        description: 'Packaged dinners',
        quantity: 15,
        unit: 'meals',
        type: DonationType.food,
        pickupAddress: 'Viman Nagar, Pune',
        createdAt: DateTime.now(),
        pickupDeadline: DateTime.now().add(const Duration(hours: 3)),
      );

      final bytes = await certificateService.generateCertificatePdf(sampleDonation);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThanOrEqualTo(4));
    });
  });
}
