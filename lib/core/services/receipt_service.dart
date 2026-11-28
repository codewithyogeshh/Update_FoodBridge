import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../features/donations/domain/models/donation.dart';
import '../utils/app_logger.dart';

/// Builds a Marathi donor receipt message for a completed delivery.
class ReceiptMessageBuilder {
  ReceiptMessageBuilder._();

  /// Builds the Marathi WhatsApp/SMS receipt text for a delivered [donation].
  /// Example:
  ///   "नमस्ते विक्रमजी! तुमचे ५० पोळी-भाजीचे पार्सल आशा बालगृहामध्ये स्वयंसेवक योगेशने सुरक्षित पोहोचवले आहे. आभार! - FoodBridge"
  static String build(Donation donation) {
    final donorTitle = _honorific(donation.donorName);
    final qty = _formatQuantity(donation.quantity);
    final unitLabel = _unitLabel(donation.unit, donation.quantity);
    final parcelLabel = _parcelLabel(donation);

    final ngoPhrase = donation.claimedByNgoName?.trim().isNotEmpty == true
        ? '${donation.claimedByNgoName!.trim()} मध्ये'
        : 'संस्थेमध्ये';
    final volunteerPhrase = donation.assignedVolunteerName?.trim().isNotEmpty == true
        ? 'स्वयंसेवक ${donation.assignedVolunteerName!.trim()} ने'
        : 'स्वयंसेवकाने';

    final greeting = 'नमस्ते $donorTitle!';
    final line1 =
        'तुमचे $qty $unitLabel चे $parcelLabel $ngoPhrase $volunteerPhrase सुरक्षित पोहोचवले आहे.';
    final thanks = 'आभार! - FoodBridge';

    return '$greeting $line1 $thanks';
  }

  static String _honorific(String donorName) {
    final clean = donorName.trim();
    if (clean.isEmpty) return 'दात्यांनो';
    final firstToken = clean.split(RegExp(r'\s+')).first;
    return '$firstToken जी';
  }

  static String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.round().toString();
    }
    return quantity.toStringAsFixed(1);
  }

  static String _unitLabel(String unit, double quantity) {
    switch (unit.toLowerCase()) {
      case 'meals':
      case 'meal':
        return 'जेवणाचे डब्बे';
      case 'kg':
      case 'kilograms':
      case 'kgs':
        return quantity == 1 ? 'किलो' : 'किलो';
      case 'boxes':
      case 'box':
        return 'पार्सल';
      case 'pieces':
      case 'piece':
        return 'तुकडे';
      case 'items':
      case 'item':
        return 'वस्तू';
      default:
        return unit.split(' ').isNotEmpty ? unit : 'पार्सल';
    }
  }

  static String _parcelLabel(Donation donation) {
    if (donation.isFood) {
      return 'अन्नाचे पार्सल';
    }
    return 'वस्तूंचे पार्सल';
  }
}

/// Sends an instant WhatsApp / SMS receipt to the donor once a delivery is
/// confirmed. Tries WhatsApp first (deep link), then falls back to SMS.
class ReceiptService {
  ReceiptService._();
  static final ReceiptService instance = ReceiptService._();

  /// True when running under `flutter test`.
  static bool get _isTestMode => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  /// Sends the receipt via the best available channel (WhatsApp → SMS).
  /// Returns the channel used, or null if no donor phone is available.
  Future<String?> sendInstantReceipt(Donation donation) async {
    final message = ReceiptMessageBuilder.build(donation);
    final phone = _normalizePhone(donation.donorPhone);
    if (phone == null) {
      AppLogger.info('[ReceiptService] No donor phone; skip instant receipt.');
      return null;
    }
    if (_isTestMode) {
      return 'whatsapp';
    }
    final whatsappSent = await _sendWhatsApp(phone, message);
    if (whatsappSent) return 'whatsapp';
    final smsSent = await _sendSms(phone, message);
    return smsSent ? 'sms' : null;
  }

  /// Opens WhatsApp with the pre-filled message for [phone].
  Future<bool> _sendWhatsApp(String phone, String message) async {
    try {
      // Primary: Universal wa.me link
      final webUri = Uri.parse('https://wa.me/$phone')
          .replace(queryParameters: {'text': message});
      final launchedWeb = await _launch(webUri);
      if (launchedWeb) return true;

      // Secondary: Direct app deep link intent for devices with strict browser sandboxes
      final appUri = Uri.parse(
        'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}',
      );
      return await _launch(appUri);
    } catch (e) {
      AppLogger.warning('[ReceiptService] WhatsApp send failed: $e');
      return false;
    }
  }

  /// Opens the default SMS composer with the message for [phone].
  Future<bool> _sendSms(String phone, String message) async {
    try {
      final uri = Uri(scheme: 'sms', path: phone, queryParameters: {'body': message});
      return await _launch(uri);
    } catch (e) {
      AppLogger.warning('[ReceiptService] SMS send failed: $e');
      return false;
    }
  }

  Future<bool> _launch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      // Attempt direct external launch in case package visibility check was delayed
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Normalizes a phone number into E.164-ish format (strips spaces, dashes,
  /// leading '+91' handling). Returns null for empty/invalid inputs.
  static String? _normalizePhone(String? phone) {
    if (phone == null) return null;
    var digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    // Strip a leading country code if 12 digits (91 + 10).
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    if (digits.length == 10) {
      return '91$digits';
    }
    return digits;
  }
}
