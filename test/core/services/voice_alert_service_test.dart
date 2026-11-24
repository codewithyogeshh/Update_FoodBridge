import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/core/services/voice_alert_service.dart';

void main() {
  setUp(() {
    VoiceAlertService.instance.resetForTest();
  });

  group('VoiceMessageBuilder Tests', () {
    test('builds a Marathi pickup alert with devanagari distance', () {
      final message = VoiceMessageBuilder.pickupAlert(distanceKm: '2');

      expect(message, 'नवीन अन्न पिकअप उपलब्ध आहे, अंतर २ किलोमीटर.');
    });

    test('converts decimal distances to devanagari digits', () {
      final message = VoiceMessageBuilder.pickupAlert(distanceKm: '3.5');

      expect(message, contains('३.५ किलोमीटर'));
      expect(message, isNot(contains('3.5')));
    });

    test('builds a Marathi pickup-confirmed message', () {
      expect(
        VoiceMessageBuilder.pickupConfirmed(),
        'पिकअप पूर्ण झाला! आता संस्थेकडे निघू या.',
      );
    });

    test('builds a Marathi delivery-complete message with NGO name', () {
      expect(
        VoiceMessageBuilder.deliveryComplete(ngoName: 'Asha Children Foundation'),
        'Asha Children Foundation चा डिलिव्हरी OTP पडताळला गेला, मोहीम पूर्ण झाली!',
      );
    });

    test('falls back to generic shelter name when NGO name is blank', () {
      final message = VoiceMessageBuilder.deliveryComplete(ngoName: '   ');

      expect(message, startsWith('संस्था चा'));
      expect(message, endsWith('मोहीम पूर्ण झाली!'));
    });
  });

  group('VoiceAlertService Tests', () {
    test('records the spoken text in test mode without invoking TTS', () async {
      final service = VoiceAlertService.instance;

      await service.speakPickupAlert(distanceKm: '2');
      expect(service.lastSpoken, contains('नवीन अन्न पिकअप'));

      await service.speakDeliveryComplete(ngoName: 'Asha Children Foundation');
      expect(service.lastSpoken, contains('Asha Children Foundation चा'));

      await service.speakPickupConfirmed();
      expect(service.lastSpoken, 'पिकअप पूर्ण झाला! आता संस्थेकडे निघू या.');
    });

    test('initialize is a safe no-op', () async {
      await VoiceAlertService.instance.initialize();
      expect(VoiceAlertService.instance.lastSpoken, isNull);
    });
  });
}
