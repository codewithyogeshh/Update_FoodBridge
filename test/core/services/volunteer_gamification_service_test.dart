import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/core/services/volunteer_gamification_service.dart';
import 'package:foodbridge/features/donations/domain/models/donation.dart';

Donation _completed({
  required String id,
  String volunteerId = 'vol-1',
  double quantity = 10,
  String unit = 'meals',
  DonationType type = DonationType.food,
}) {
  return Donation(
    id: id,
    donorId: 'donor-1',
    donorName: 'Donor',
    title: 'Task $id',
    description: 'desc',
    quantity: quantity,
    unit: unit,
    type: type,
    pickupAddress: 'Powai Naka, Satara',
    createdAt: DateTime.now(),
    pickupDeadline: DateTime.now().add(const Duration(hours: 3)),
    assignedVolunteerId: volunteerId,
    assignedVolunteerName: 'Karan Patel',
    deliveredAt: DateTime.now(),
    status: DonationStatus.delivered,
  );
}

void main() {
  group('VolunteerGamificationService Tests', () {
    test('summaryFor computes deliveries, meals, hours and karma points', () {
      final donations = [
        _completed(id: 'a', quantity: 50),
        _completed(id: 'b', quantity: 30),
      ];

      final summary = VolunteerGamificationService.summaryFor(
        allDonations: donations,
        volunteerId: 'vol-1',
        volunteerName: 'Karan Patel',
      );

      expect(summary.totalDeliveries, equals(2));
      expect(summary.totalMeals, equals(80));
      expect(summary.totalHours, equals((2 * 2.2).round()));
      // 2*50 + 80*2 = 100 + 160 = 260
      expect(summary.karmaPoints, equals(260));
    });

    test('badges earned by delivery milestones', () {
      final low = VolunteerGamificationService.summaryFor(
        allDonations: [_completed(id: 'a')],
        volunteerId: 'vol-1',
      );
      expect(low.badgesEarned, contains('First Rescue'));
      expect(low.badgesEarned, isNot(contains('Community Hero')));

      final many = <Donation>[
        for (int i = 0; i < 15; i++)
          _completed(id: 'm$i', quantity: 10),
      ];
      final hero = VolunteerGamificationService.summaryFor(
        allDonations: many,
        volunteerId: 'vol-1',
      );
      expect(hero.badgesEarned, contains('Community Hero'));
      expect(hero.badgesEarned, contains('Speedy Deliverer'));
      expect(hero.badgesEarned, contains('Zero Waste Champion'));
      expect(hero.badgesEarned, isNot(contains('Gold Deliverer')));
    });

    test('leaderboard sorts by points and assigns ranks', () {
      final donations = [
        _completed(id: 'v1a', volunteerId: 'vol-1', quantity: 20),
        _completed(id: 'v1b', volunteerId: 'vol-1', quantity: 20),
        _completed(id: 'v2a', volunteerId: 'vol-2', quantity: 10),
      ];

      final board = VolunteerGamificationService.leaderboard(
        allDonations: donations,
        volunteerNames: {'vol-1': 'Karan', 'vol-2': 'Rohit'},
      );

      expect(board.length, equals(2));
      expect(board[0].volunteerId, equals('vol-1'));
      expect(board[0].rank, equals(1));
      expect(board[1].volunteerId, equals('vol-2'));
      expect(board[1].rank, equals(2));
      expect(board[0].karmaPoints, greaterThan(board[1].karmaPoints));
    });

    test('generateNssCertificatePdf returns bytes in test environment', () async {
      final summary = VolunteerGamificationService.summaryFor(
        allDonations: List.generate(10, (i) => _completed(id: 'c$i')),
        volunteerId: 'vol-1',
        volunteerName: 'Karan Patel',
      );

      final bytes = await VolunteerGamificationService.generateNssCertificatePdf(
        summary: summary,
        collegeName: 'Sinhgad College',
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThanOrEqualTo(4));
    });
  });
}
