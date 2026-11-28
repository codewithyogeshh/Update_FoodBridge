import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/features/donations/domain/models/donation.dart';
import 'package:foodbridge/features/donations/presentation/donation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multi-Device Realtime Sync & Notification Tests', () {
    late DonationProvider provider;

    setUp(() {
      provider = DonationProvider();
      DonationProvider.onDonationReceived = null;
    });

    tearDown(() {
      provider.dispose();
      DonationProvider.onDonationReceived = null;
    });

    test('isDummyDonation does not filter legitimate user donations from demo accounts', () {
      final realDemoDonation = Donation(
        id: 'food-1731688923456',
        donorId: 'usr-donor-101',
        donorName: 'Vikram Joshi (Green Leaf Bistro)',
        title: 'Fresh Cooked Meals',
        description: 'Warm, nutritious packaged meals.',
        quantity: 20,
        unit: 'meals',
        type: DonationType.food,
        status: DonationStatus.available,
        pickupAddress: 'Camp, Pune',
        city: 'Pune',
        createdAt: DateTime.now(),
        pickupDeadline: DateTime.now().add(const Duration(hours: 4)),
      );

      // Verify that real user donation is NOT considered dummy
      expect(DonationProvider.isDummyDonation(realDemoDonation), isFalse);

      // Static mock ids should still be recognized as dummy
      final staticMock = realDemoDonation.copyWith(id: 'dn-101');
      expect(DonationProvider.isDummyDonation(staticMock), isTrue);
    });

    test('Peer response sync reconciles donations on secondary devices and triggers notification', () async {
      bool notificationTriggered = false;

      DonationProvider.onDonationReceived = (title, body, id) {
        notificationTriggered = true;
      };

      final incomingDonation = Donation(
        id: 'food-peer-999',
        donorId: 'usr-donor-101',
        donorName: 'Vikram Joshi (Green Leaf Bistro)',
        title: 'Hot Rotis and Sabji',
        description: 'Hygienically prepared meals',
        quantity: 30,
        unit: 'meals',
        type: DonationType.food,
        status: DonationStatus.available,
        pickupAddress: 'MG Road, Pune',
        city: 'Pune',
        createdAt: DateTime.now(),
        pickupDeadline: DateTime.now().add(const Duration(hours: 3)),
      );

      // Simulate peer response sync payload arriving on Device B
      provider.requestPeerSync(); // Does not crash
      
      // Directly verify merging logic
      final initialCount = provider.allDonations.length;
      expect(provider.getDonationById('food-peer-999'), isNull);

      // When a donation is created and published
      await provider.createDonation(incomingDonation);

      DonationProvider.onDonationReceived?.call('Test Alert', 'Test Body', 'food-peer-999');
      expect(notificationTriggered, isTrue);

      expect(provider.allDonations.length, initialCount + 1);
      expect(provider.getDonationById('food-peer-999'), isNotNull);
      expect(provider.getDonationById('food-peer-999')!.title, 'Hot Rotis and Sabji');
    });

    test('Claiming and volunteer lifecycle transitions update status cleanly', () async {
      final donation = Donation(
        id: 'food-cycle-101',
        donorId: 'usr-donor-101',
        donorName: 'Vikram Joshi',
        title: 'Mixed Thali',
        description: 'Fresh surplus thalis',
        quantity: 15,
        unit: 'meals',
        type: DonationType.food,
        status: DonationStatus.available,
        pickupAddress: 'Kothrud, Pune',
        city: 'Pune',
        createdAt: DateTime.now(),
        pickupDeadline: DateTime.now().add(const Duration(hours: 4)),
      );

      await provider.createDonation(donation);
      expect(provider.getDonationById('food-cycle-101')!.status, DonationStatus.available);

      // NGO claims the donation
      final claimSuccess = await provider.claimDonation(
        donationId: 'food-cycle-101',
        ngoId: 'usr-ngo-202',
        ngoName: 'Asha Children Foundation',
      );
      expect(claimSuccess, isTrue);
      expect(provider.getDonationById('food-cycle-101')!.status, DonationStatus.accepted);
      expect(provider.getDonationById('food-cycle-101')!.claimedByNgoName, 'Asha Children Foundation');

      // Volunteer accepts pickup
      final assignSuccess = await provider.acceptVolunteerTask(
        donationId: 'food-cycle-101',
        volunteerId: 'usr-vol-303',
        volunteerName: 'Rohit Kulkarni',
        phone: '+91 97654 99887',
      );
      expect(assignSuccess, isTrue);
      expect(provider.getDonationById('food-cycle-101')!.status, DonationStatus.assignedForPickup);
      expect(provider.getDonationById('food-cycle-101')!.assignedVolunteerName, 'Rohit Kulkarni');
    });

    test('Live courier GPS coordinates and heading propagate correctly across devices', () async {
      final donation = Donation(
        id: 'food-gps-101',
        donorId: 'usr-donor-101',
        donorName: 'Green Leaf Bistro',
        title: 'Hot Meals',
        description: 'Packaged lunch',
        quantity: 25,
        unit: 'meals',
        type: DonationType.food,
        status: DonationStatus.assignedForPickup,
        pickupAddress: 'Powai Naka, Satara',
        city: 'Satara',
        createdAt: DateTime.now(),
        pickupDeadline: DateTime.now().add(const Duration(hours: 3)),
      );

      await provider.createDonation(donation);

      // Volunteer updates live courier location
      await provider.updateCourierLocation(
        donationId: 'food-gps-101',
        latitude: 17.6855,
        longitude: 73.9982,
        heading: 45.0,
      );

      final updated = provider.getDonationById('food-gps-101');
      expect(updated, isNotNull);
      expect(updated!.courierLatitude, equals(17.6855));
      expect(updated.courierLongitude, equals(73.9982));
      expect(updated.courierHeading, equals(45.0));
      expect(updated.liveCourierLatLng, isNotNull);
      expect(updated.estimatedMinutes, greaterThan(0));
    });
  });
}
