import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/core/services/receipt_service.dart';
import 'package:foodbridge/features/donations/domain/models/donation.dart';

Donation _sampleDonation({
  String? donorName,
  String? donorPhone,
  double quantity = 50,
  String unit = 'meals',
  String? ngo,
  String? volunteer,
}) {
  return Donation(
    id: 'dn-receipt-101',
    donorId: 'usr-donor-101',
    donorName: donorName ?? 'Vikram Jadhav',
    donorPhone: donorPhone ?? '+91 98200 12345',
    title: 'Fresh Veg Pulao & Sabzi',
    description: '50 packaged meals',
    quantity: quantity,
    unit: unit,
    type: DonationType.food,
    pickupAddress: 'Shop 4, Powai Naka, Satara',
    createdAt: DateTime.now(),
    pickupDeadline: DateTime.now().add(const Duration(hours: 3)),
    claimedByNgoName: ngo ?? 'Asha Children Foundation',
    assignedVolunteerName: volunteer ?? 'Yogesh More',
    deliveredAt: DateTime.now(),
  );
}

void main() {
  group('ReceiptMessageBuilder Tests', () {
    test('builds Marathi receipt with quantity, NGO and volunteer name', () {
      final message = ReceiptMessageBuilder.build(_sampleDonation());

      expect(message, contains('नमस्ते Vikram जी!'));
      expect(message, contains('तुमचे 50 जेवणाचे डब्बे चे अन्नाचे पार्सल'));
      expect(message, contains('Asha Children Foundation मध्ये'));
      expect(message, contains('स्वयंसेवक Yogesh More ने'));
      expect(message, contains('आभार! - FoodBridge'));
    });

    test('falls back to defaults when NGO and volunteer names are missing', () {
      final message = ReceiptMessageBuilder.build(
        _sampleDonation(ngo: '   ', volunteer: '  '),
      );

      expect(message, contains('संस्थेमध्ये'));
      expect(message, contains('स्वयंसेवकाने'));
      expect(message, contains('आभार! - FoodBridge'));
    });

    test('uses generic honorific for blank donor name', () {
      final message = ReceiptMessageBuilder.build(
        _sampleDonation(donorName: '   '),
      );

      expect(message, contains('नमस्ते दात्यांनो!'));
    });
  });

  group('ReceiptService Tests', () {
    test('sendInstantReceipt returns whatsapp channel below test mode', () async {
      final channel = await ReceiptService.instance
          .sendInstantReceipt(_sampleDonation());

      expect(channel, equals('whatsapp'));
    });

    test('sendInstantReceipt returns null when donor has no phone', () async {
      final channel = await ReceiptService.instance
          .sendInstantReceipt(_sampleDonation(donorPhone: '   '));

      expect(channel, isNull);
    });
  });
}
