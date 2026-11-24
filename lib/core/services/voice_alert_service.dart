import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, visibleForTesting;
import 'package:flutter_tts/flutter_tts.dart';

/// Builds Marathi (मराठी) voice-announcement strings for volunteer courier
/// flows. These are spoken aloud via TTS so a volunteer can keep their eyes
/// on the road (e.g. while riding a bike).
///
/// Example:
///   "नवीन अन्न पिकअप उपलब्ध आहे, अंतर २ किलोमीटर."
///   "आशा आश्रमाचा डिलिव्हरी OTP पडताळला गेला, मोहीम पूर्ण झाली!"
class VoiceMessageBuilder {
  VoiceMessageBuilder._();

  /// Annunciation a new food pickup that is available to the volunteer,
  /// including the current distance in kilometres.
  static String pickupAlert({required String distanceKm}) {
    // Show a clean whole number when the distance has no fractional part
    // (e.g. "2.0" → "२ किलोमीटर" rather than "२.० किलोमीटर").
    final cleaned = distanceKm.replaceAll(RegExp(r'\.0+$'), '');
    return 'नवीन अन्न पिकअप उपलब्ध आहे, अंतर ${_toDevanagari(cleaned)} किलोमीटर.';
  }

  /// Announced that the pickup OTP was verified and the volunteer is now
  /// riding toward the NGO shelter.
  static String pickupConfirmed() {
    return 'पिकअप पूर्ण झाला! आता संस्थेकडे निघू या.';
  }

  /// Announces a completed delivery: the shelter's verification OTP was
  /// matched and the mission is complete.
  static String deliveryComplete({required String ngoName}) {
    final ngo = ngoName.trim().isNotEmpty ? ngoName.trim() : 'संस्था';
    return '$ngo चा डिलिव्हरी OTP पडताळला गेला, मोहीम पूर्ण झाली!';
  }

  /// Converts Arabic (Western) digits in [input] to Devanagari (मराठी)
  /// digits: 0-9 → ०-९. Non-digit characters are left untouched.
  static String _toDevanagari(String input) {
    const devanagari = '०१२३४५६७८९';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final i = ch.codeUnitAt(0) - 0x30;
      if (i >= 0 && i <= 9) {
        buffer.write(devanagari[i]);
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }
}

/// Marathi Text-to-Speech (TTS) service that reads out courier updates so a
/// volunteer can keep their eyes on the road. Uses `flutter_tts`.
///
/// This is a process-wide singleton mirroring [NotificationService] /
/// [ReceiptService]. It is safe to call in test mode: the platform TTS engine
/// is never invoked there, but the last spoken text is still recorded so
/// tests can assert on it.
class VoiceAlertService {
  VoiceAlertService._();
  static final VoiceAlertService instance = VoiceAlertService._();

  FlutterTts? _tts;
  bool _initialized = false;
  String? _lastSpoken;

  /// True when running under `flutter test`.
  static bool get _isTestMode =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  /// The most recent string passed to [speak]. Mainly for tests.
  String? get lastSpoken => _lastSpoken;

  /// Resets in-memory recording state. Used by tests to isolate cases; the
  /// platform TTS engine is untouched.
  @visibleForTesting
  void resetForTest() {
    _lastSpoken = null;
  }

  /// Configures the Marathi voice. No-op in test mode.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (_isTestMode) return;
    final tts = _tts ??= FlutterTts();
    try {
      await tts.setLanguage('mr-IN');
      await tts.setSpeechRate(0.5);
      await tts.setPitch(1.0);
      await tts.setVolume(1.0);
    } catch (e) {
      debugPrint('[VoiceAlertService] initialize error: $e');
    }
  }

  /// Speaks [text] aloud in Marathi. Falls back to logging on any platform
  /// error so the app is never broken by a TTS failure.
  Future<void> speak(String text) async {
    _lastSpoken = text;
    if (_isTestMode) return;
    try {
      if (!_initialized) {
        await initialize();
      }
      await _tts?.speak(text);
    } catch (e) {
      debugPrint('[VoiceAlertService] speak error: $e');
    }
  }

  /// Announces that a new pickup is available at [distanceKm] km away.
  Future<void> speakPickupAlert({required String distanceKm}) {
    return speak(VoiceMessageBuilder.pickupAlert(distanceKm: distanceKm));
  }

  /// Announces that the pickup OTP was verified.
  Future<void> speakPickupConfirmed() {
    return speak(VoiceMessageBuilder.pickupConfirmed());
  }

  /// Announces that a delivery to [ngoName] is complete.
  Future<void> speakDeliveryComplete({required String ngoName}) {
    return speak(VoiceMessageBuilder.deliveryComplete(ngoName: ngoName));
  }
}
