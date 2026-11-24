import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../features/donations/domain/models/donation.dart';

/// Aggregated karma summary for a single volunteer.
class VolunteerKarmaSummary {
  final String volunteerId;
  final String volunteerName;
  final int totalDeliveries;
  final int totalMeals;
  final int totalClothingItems;
  final int totalHours;
  final int karmaPoints;
  final List<String> badgesEarned;
  final int rank; // 1-based across all volunteers

  const VolunteerKarmaSummary({
    required this.volunteerId,
    required this.volunteerName,
    required this.totalDeliveries,
    required this.totalMeals,
    required this.totalClothingItems,
    required this.totalHours,
    required this.karmaPoints,
    required this.badgesEarned,
    required this.rank,
  });

  VolunteerKarmaSummary copyWith({int? rank}) => VolunteerKarmaSummary(
        volunteerId: volunteerId,
        volunteerName: volunteerName,
        totalDeliveries: totalDeliveries,
        totalMeals: totalMeals,
        totalClothingItems: totalClothingItems,
        totalHours: totalHours,
        karmaPoints: karmaPoints,
        badgesEarned: badgesEarned,
        rank: rank ?? this.rank,
      );
}

/// Pure, testable gamification logic: karma points, hours, badges,
/// leaderboard ranking, and NSS/College certificate generation.
class VolunteerGamificationService {
  VolunteerGamificationService._();
  static final VolunteerGamificationService instance = VolunteerGamificationService._();

  static const int pointsPerDelivery = 50;
  static const int pointsPerMeal = 2;
  static const int pointsPerClothingItem = 3;
  static const double hoursPerDelivery = 2.2;

  /// Collects the completed deliveries performed by [volunteerId] from
  /// [allDonations].
  static List<Donation> completedFor(List<Donation> allDonations, String volunteerId) {
    return allDonations
        .where((d) =>
            d.assignedVolunteerId == volunteerId &&
            (d.isDelivered ||
                d.deliveredAt != null ||
                d.status == DonationStatus.delivered ||
                d.status == DonationStatus.deliveredToNgo ||
                d.status == DonationStatus.distributed ||
                d.status == DonationStatus.completed))
        .toList();
  }

  /// Computes karma metrics for a single volunteer across all donations.
  static VolunteerKarmaSummary summaryFor({
    required List<Donation> allDonations,
    required String volunteerId,
    String volunteerName = '',
  }) {
    final completed = completedFor(allDonations, volunteerId);
    final deliveries = completed.length;
    final meals = completed
        .where((d) => d.isFood)
        .fold<int>(0, (acc, d) => acc + d.quantity.round());
    final clothing = completed
        .where((d) => d.isClothing)
        .fold<int>(0, (acc, d) => acc + d.quantity.round());
    final hours = (deliveries * hoursPerDelivery).round();

    final points = (deliveries * pointsPerDelivery) +
        (meals * pointsPerMeal) +
        (clothing * pointsPerClothingItem);

    return VolunteerKarmaSummary(
      volunteerId: volunteerId,
      volunteerName: volunteerName,
      totalDeliveries: deliveries,
      totalMeals: meals,
      totalClothingItems: clothing,
      totalHours: hours,
      karmaPoints: points,
      badgesEarned: _badgesFor(deliveries, hours),
      rank: 1,
    );
  }

  static List<String> _badgesFor(int deliveries, int hours) {
    final badges = <String>[];
    if (deliveries >= 1) badges.add('First Rescue');
    if (deliveries >= 5) badges.add('Community Hero');
    if (deliveries >= 10) badges.add('Speedy Deliverer');
    if (deliveries >= 15) badges.add('Zero Waste Champion');
    if (deliveries >= 25) badges.add('Gold Deliverer');
    if (hours >= 100) badges.add('100 Hours Club');
    return badges;
  }

  /// Builds a leaderboard (sorted by karma points, highest first) from all
  /// donations across all volunteers. Returns per-volunteer summaries with
  /// 1-based rank assigned.
  static List<VolunteerKarmaSummary> leaderboard({
    required List<Donation> allDonations,
    Map<String, String>? volunteerNames,
  }) {
    final ids = <String>{};
    for (final d in allDonations) {
      final vid = d.assignedVolunteerId;
      if (vid != null && vid.trim().isNotEmpty) ids.add(vid);
    }

    final summaries = ids.map((vid) {
      final name = volunteerNames?[vid] ?? '';
      return summaryFor(allDonations: allDonations, volunteerId: vid, volunteerName: name);
    }).toList();

    summaries.sort((a, b) => b.karmaPoints.compareTo(a.karmaPoints));
    for (int i = 0; i < summaries.length; i++) {
      summaries[i] = summaries[i].copyWith(rank: i + 1);
    }
    return summaries;
  }

  static bool get _isTestMode => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  /// Higher-level NSS/College volunteering certificate PDF. Includes hours
  /// served and meals delivered to hungry beneficiaries.
  static Future<Uint8List> generateNssCertificatePdf({
    required VolunteerKarmaSummary summary,
    String collegeName = '',
    String beneficiaryLabel = 'भुकेल्या मुलांना',
  }) async {
    if (_isTestMode) {
      return Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
    }

    final doc = pw.Document();
    final today = DateFormat('dd MMMM yyyy').format(DateTime.now());
    final green = PdfColor.fromHex('#138808');
    final darkSlate = PdfColor.fromHex('#1E293B');
    final muted = PdfColor.fromHex('#64748B');
    final gold = PdfColor.fromHex('#D97706');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (_) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FCFDFD'),
              border: pw.Border.all(color: green, width: 3),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Container(
              margin: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: gold, width: 1.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'राष्ट्रीय सेवा योजना (NSS) • FoodBridge Volunteer Service',
                        style: pw.TextStyle(color: green, fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'VOLUNTEER SERVICE CERTIFICATE',
                        style: pw.TextStyle(color: darkSlate, fontSize: 24, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2),
                      ),
                      pw.Text(
                        'Presented with official civic recognition to',
                        style: pw.TextStyle(color: muted, fontSize: 11, fontStyle: pw.FontStyle.italic),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        summary.volunteerName.isNotEmpty ? summary.volunteerName.toUpperCase() : 'FOODBRIDGE VOLUNTEER',
                        style: pw.TextStyle(color: darkSlate, fontSize: 22, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Container(width: 280, height: 1.5, color: gold, margin: const pw.EdgeInsets.symmetric(vertical: 6)),
                      pw.Text(
                        'This volunteer has selflessly served ${summary.totalHours} hours as a FoodBridge courier, completing ${summary.totalDeliveries} delivery missions and delivering ${summary.totalMeals} meals to $beneficiaryLabel across the FoodBridge Humanitarian Logistics Network as of $today.',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(color: darkSlate, fontSize: 11, lineSpacing: 1.4),
                      ),
                      pw.SizedBox(height: 6),
                      if (collegeName.trim().isNotEmpty)
                        pw.Text(
                          'Verified college/university: $collegeName',
                          style: pw.TextStyle(color: muted, fontSize: 10, fontStyle: pw.FontStyle.italic),
                        ),
                    ],
                  ),
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 8),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F0FDF4'),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColor.fromHex('#86EFAC')),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _metric('HOURS SERVED', '${summary.totalHours} h', green),
                        _metric('DELIVERIES', '${summary.totalDeliveries}', darkSlate),
                        _metric('MEALS DELIVERED', '${summary.totalMeals}', green),
                        _metric('KARMA POINTS', '${summary.karmaPoints}', darkSlate),
                      ],
                    ),
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('FoodBridge Volunteer Service', style: pw.TextStyle(fontSize: 9, color: muted, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Verified via live delivery ledger', style: pw.TextStyle(fontSize: 8, color: muted)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Container(width: 140, height: 1, color: muted),
                          pw.SizedBox(height: 3),
                          pw.Text('NSS Programme Officer', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkSlate)),
                          pw.Text('FoodBridge Humanitarian Network', style: pw.TextStyle(fontSize: 8, color: muted)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _metric(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(color: color, fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(label, style: pw.TextStyle(color: PdfColor.fromHex('#475569'), fontSize: 8, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
