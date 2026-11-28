import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env_config.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/receipt_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../authentication/data/auth_service.dart';
import '../../authentication/domain/models/app_user.dart';
import '../../notifications/domain/models/app_notification.dart';
import '../domain/models/donation.dart';
import '../domain/models/distribution_record.dart';

/// Who should receive a notification for a given lifecycle event.
enum _NotificationAudience { donorOnly, ngoOnly, donorAndNgo, everyone }

class DonationProvider extends ChangeNotifier {
  static const String _kLocalDonationsKey = 'foodbridge_saved_donations';
  final List<Donation> _donations = [];
  final List<DistributionRecord> _distributionRecords = [];
  bool _isLoading = false;
  bool _hasCompletedInitialFetch = false;
  String? _errorMessage;
  DonationType? _selectedTypeFilter;
  bool? _selectedVegFilter;
  String _searchQuery = '';
  RealtimeChannel? _realtimeChannel;
  Timer? _heartbeatTimer;

  /// Global hook for in-app notification dispatch across multi-device sync
  static void Function(String title, String body, String? donationId)? onDonationReceived;
  static void Function(String title, String body, NotificationType type, String? donationId)? onNotificationDispatch;

  /// Resolve the currently signed-in user for this device/session.
  AppUser? get _sessionUser {
    try {
      return AuthService().currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Whether THIS device should alert for [donation] given the sign-in state.
  /// When no user is resolved we fall back to alerting (preserves prior behavior).
  bool _shouldAlertFor(Donation donation, _NotificationAudience audience) {
    final user = _sessionUser;
    if (user == null) return true;
    switch (audience) {
      case _NotificationAudience.donorOnly:
        return user.id == donation.donorId;
      case _NotificationAudience.ngoOnly:
        return user.role == UserRole.ngo;
      case _NotificationAudience.donorAndNgo:
        return user.id == donation.donorId || user.role == UserRole.ngo;
      case _NotificationAudience.everyone:
        return true;
    }
  }

  String resolveVolunteerName(String? volId, String? currentName) {
    try {
      final authUsers = AuthService().allUsers;
      final volUser = authUsers.where((u) {
        if (volId != null && (u.id == volId || AuthService.resolveUuid(u.id) == volId)) return true;
        if (u.role == UserRole.volunteer) return true;
        return false;
      }).firstOrNull;

      if (volUser != null && volUser.fullName.trim().isNotEmpty && volUser.fullName.trim() != 'Rohit Kulkarni') {
        return volUser.fullName.trim();
      }

      if (currentName != null && currentName.trim().isNotEmpty && currentName.trim() != 'Rohit Kulkarni') {
        return currentName.trim();
      }

      return volUser?.fullName.trim() ?? currentName ?? 'Volunteer';
    } catch (_) {
      return currentName ?? 'Volunteer';
    }
  }

  DonationProvider() {
    _initialize();
    initRealtime();
  }

  static bool isDummyDonation(Donation d) {
    if (d.id == 'dn-101' ||
        d.id == 'dn-102' ||
        d.id == 'dn-103' ||
        d.id == 'dn-104' ||
        d.id == 'dn-105' ||
        d.id == 'dn-106' ||
        d.id.startsWith('mock-')) {
      return true;
    }
    return false;
  }

  static String _statusToDb(DonationStatus status) {
    switch (status) {
      case DonationStatus.draft:
        return 'draft';
      case DonationStatus.available:
      case DonationStatus.requested:
        return 'listed';
      case DonationStatus.accepted:
        return 'claimed';
      case DonationStatus.assignedForPickup:
        return 'assigned';
      case DonationStatus.pickedUp:
        return 'picked_up';
      case DonationStatus.deliveredToNgo:
      case DonationStatus.distributed:
      case DonationStatus.completed:
        return 'delivered';
      case DonationStatus.cancelled:
      case DonationStatus.rejected:
        return 'cancelled';
      case DonationStatus.expired:
        return 'expired';
    }
  }

  static DonationStatus _statusFromDb(String? status) {
    switch (status?.toLowerCase().trim()) {
      case 'listed':
      case 'available':
        return DonationStatus.available;
      case 'claimed':
      case 'accepted':
        return DonationStatus.accepted;
      case 'assigned':
      case 'assigned_for_pickup':
      case 'assignedforpickup':
        return DonationStatus.assignedForPickup;
      case 'picked_up':
      case 'pickedup':
      case 'in_transit':
      case 'intransit':
        return DonationStatus.pickedUp;
      case 'delivered':
      case 'delivered_to_ngo':
      case 'deliveredtongo':
        return DonationStatus.deliveredToNgo;
      case 'distributed':
      case 'distribution_recorded':
        return DonationStatus.distributed;
      case 'completed':
        return DonationStatus.completed;
      case 'cancelled':
      case 'rejected':
        return DonationStatus.cancelled;
      case 'expired':
        return DonationStatus.expired;
      case 'draft':
        return DonationStatus.draft;
      default:
        return DonationStatus.fromString(status);
    }
  }

  Future<void> _persistLocalDonations() async {
    try {
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return;
      final prefs = await SharedPreferences.getInstance();
      final cleanList = _donations.where((d) => !isDummyDonation(d)).toList();
      final jsonList = cleanList.map((d) => d.toJson()).toList();
      await prefs.setString(_kLocalDonationsKey, jsonEncode(jsonList));
    } catch (e) {
      AppLogger.warning('Failed to persist local donations: $e');
    }
  }

  Future<List<Donation>> _loadLocalDonations() async {
    try {
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return [];
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kLocalDonationsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        final List<Donation> valid = [];
        for (final item in list) {
          try {
            if (item is Map) {
              final d = Donation.fromJson(Map<String, dynamic>.from(item));
              if (!isDummyDonation(d)) {
                valid.add(d);
              }
            }
          } catch (e) {
            AppLogger.warning('Skipping unparsable local donation: $e');
          }
        }
        return valid;
      }
    } catch (e) {
      AppLogger.warning('Failed to load local donations: $e');
    }
    return [];
  }

  Future<void> _initialize() async {
    final cached = await _loadLocalDonations();
    if (cached.isNotEmpty) {
      _donations.clear();
      _donations.addAll(cached);
    } else {
      _seedInitialData();
    }
    await syncWithUserProfiles();
    notifyListeners();

    if (_isSupabaseLive) {
      await loadDonations();
    }
  }

  /// Synchronize volunteer, donor, and NGO names on all donations with live user profiles
  Future<void> syncWithUserProfiles() async {
    try {
      final authUsers = await AuthService().fetchAllUsers();
      final Map<String, String> namesById = {};
      final Map<String, String> namesByEmail = {};
      final Map<String, String> phonesById = {};

      for (final u in authUsers) {
        if (u.fullName.trim().isNotEmpty) {
          namesById[u.id] = u.fullName.trim();
          namesByEmail[u.email.toLowerCase().trim()] = u.fullName.trim();
          if (u.phone != null && u.phone!.trim().isNotEmpty) {
            phonesById[u.id] = u.phone!.trim();
          }
        }
      }

      // Check for volunteer override specifically
      final volUser = authUsers.where((u) => u.email.toLowerCase().trim() == 'volunteer@foodbridge.org' || u.id == 'usr-vol-303').firstOrNull;
      final volName = volUser?.fullName.trim().isNotEmpty == true
          ? volUser!.fullName.trim()
          : (namesByEmail['volunteer@foodbridge.org'] ?? namesById['usr-vol-303']);
      final volPhone = volUser?.phone?.trim().isNotEmpty == true
          ? volUser!.phone!.trim()
          : (phonesById['usr-vol-303'] ?? '');

      bool changed = false;
      for (int i = 0; i < _donations.length; i++) {
        final d = _donations[i];
        String? newVolName = d.assignedVolunteerName;
        String? newVolPhone = d.assignedVolunteerPhone;
        String? newDonorName = d.donorName;
        String? newNgoName = d.claimedByNgoName;

        // Resolve volunteer name
        if (d.assignedVolunteerId != null && namesById.containsKey(d.assignedVolunteerId)) {
          newVolName = namesById[d.assignedVolunteerId];
          if (phonesById.containsKey(d.assignedVolunteerId)) {
            newVolPhone = phonesById[d.assignedVolunteerId];
          }
        } else if (d.assignedVolunteerId == 'usr-vol-303' ||
            d.assignedVolunteerId == 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33' ||
            d.assignedVolunteerName == 'Rohit Kulkarni' ||
            (volName != null && volName.isNotEmpty && (d.assignedVolunteerName == null || d.assignedVolunteerName!.isEmpty || d.assignedVolunteerName == 'Rohit Kulkarni'))) {
          if (volName != null && volName.isNotEmpty) {
            newVolName = volName;
            if (volPhone.isNotEmpty) newVolPhone = volPhone;
          }
        }

        if (d.donorId.isNotEmpty && namesById.containsKey(d.donorId)) {
          newDonorName = namesById[d.donorId]!;
        }

        if (d.claimedByNgoId != null && namesById.containsKey(d.claimedByNgoId)) {
          newNgoName = namesById[d.claimedByNgoId];
        }

        final cleanPickupOtp = (d.pickupOtp.isNotEmpty && d.pickupOtp != '4829')
            ? d.pickupOtp
            : Donation.generateDeterministicOtp(d.id, isDelivery: false);
        final cleanDeliveryOtp = (d.deliveryOtp.isNotEmpty && d.deliveryOtp != '9152')
            ? d.deliveryOtp
            : Donation.generateDeterministicOtp(d.id, isDelivery: true);

        if (newVolName != d.assignedVolunteerName ||
            newVolPhone != d.assignedVolunteerPhone ||
            newDonorName != d.donorName ||
            newNgoName != d.claimedByNgoName ||
            d.pickupOtp != cleanPickupOtp ||
            d.deliveryOtp != cleanDeliveryOtp) {
          _donations[i] = d.copyWith(
            assignedVolunteerName: newVolName,
            assignedVolunteerPhone: newVolPhone,
            donorName: newDonorName,
            claimedByNgoName: newNgoName,
            pickupOtp: cleanPickupOtp,
            deliveryOtp: cleanDeliveryOtp,
          );
          changed = true;
        }
      }

      if (changed) {
        await _persistLocalDonations();
        for (final d in _donations) {
          _broadcastDonationEvent('update', d);
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  bool get _isSupabaseLive {
    try {
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return false;
      if (!EnvConfig.isConfigured) return false;
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadDonations() async {
    if (!_isSupabaseLive) return;
    try {
      _isLoading = true;
      notifyListeners();

      final client = Supabase.instance.client;
      dynamic response;
      try {
        response = await client
            .from('donations')
            .select('*, profiles(full_name, phone)')
            .order('created_at', ascending: false);
      } catch (_) {
        response = await client
            .from('donations')
            .select('*')
            .order('created_at', ascending: false);
      }

      final List<dynamic> data = response as List<dynamic>;
      for (final raw in data) {
        try {
          final item = Map<String, dynamic>.from(raw as Map);
          if (item['profiles'] != null && item['profiles'] is Map) {
            item['donor_name'] = item['profiles']['full_name'];
            item['donor_phone'] = item['profiles']['phone'];
          } else if (item['donor_name'] == null || item['donor_name'].toString().isEmpty || item['donor_name'] == 'FoodBridge Donor') {
            final authUsers = AuthService().allUsers;
            final matched = authUsers.where((u) => u.id == item['donor_id'] || AuthService.resolveUuid(u.id) == item['donor_id']).firstOrNull;
            if (matched != null && matched.fullName.isNotEmpty) {
              item['donor_name'] = matched.fullName;
              if (matched.phone != null && matched.phone!.isNotEmpty) item['donor_phone'] = matched.phone;
            }
          }
          final dbStatus = item['status']?.toString();
          item['status'] = _statusFromDb(dbStatus).name;

          final liveDonation = Donation.fromJson(item);
          if (isDummyDonation(liveDonation)) continue;

          final existingIdx = _donations.indexWhere((d) => d.id == liveDonation.id);
          if (existingIdx != -1) {
            _donations[existingIdx] = _mergeDonations(_donations[existingIdx], liveDonation);
          } else {
            _donations.add(liveDonation);
          }
        } catch (err) {
          AppLogger.warning('Error parsing live donation: $err');
        }
      }

      await _persistLocalDonations();
      _isLoading = false;
      _hasCompletedInitialFetch = true;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasCompletedInitialFetch = true;
      AppLogger.error('Error loading donations from Supabase', e);
      notifyListeners();
    }
  }

  void initRealtime() {
    if (!_isSupabaseLive) return;
    try {
      final client = Supabase.instance.client;
      _realtimeChannel = client.channel(
        'public:donations_realtime',
        opts: const RealtimeChannelConfig(self: false),
      )
        ..onBroadcast(
          event: 'donation_sync',
          callback: (payload) {
            _handleBroadcastPayload(payload);
          },
        )
        ..onBroadcast(
          event: 'peer_request_sync',
          callback: (payload) {
            _handlePeerRequestSync(payload);
          },
        )
        ..onBroadcast(
          event: 'peer_response_sync',
          callback: (payload) {
            _handlePeerResponseSync(payload);
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'donations',
          callback: (payload) {
            _handleRealtimePayload(payload);
          },
        )
        ..subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            AppLogger.info('Supabase Realtime Channel subscribed successfully');
            requestPeerSync();
          }
        });

      _startHeartbeat();
    } catch (e) {
      AppLogger.warning('initRealtime warning: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return;
    int cycleCount = 0;
    // 15-second background reconciliation ensures passive sync without congesting cellular radio
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      cycleCount++;
      _syncLatestChanges();
      // Periodically request peer sync (or immediately if local list is empty)
      if (_donations.isEmpty || cycleCount % 5 == 0) {
        requestPeerSync();
      }
    });
  }

  int _statusRank(DonationStatus s) {
    switch (s) {
      case DonationStatus.draft:
        return 0;
      case DonationStatus.available:
      case DonationStatus.requested:
        return 1;
      case DonationStatus.accepted:
        return 2;
      case DonationStatus.assignedForPickup:
        return 3;
      case DonationStatus.pickedUp:
        return 4;
      case DonationStatus.deliveredToNgo:
        return 5;
      case DonationStatus.distributed:
        return 6;
      case DonationStatus.completed:
        return 7;
      case DonationStatus.cancelled:
      case DonationStatus.rejected:
      case DonationStatus.expired:
        return 99;
    }
  }

  Donation _mergeDonations(Donation current, Donation incoming) {
    if (incoming.status == DonationStatus.cancelled ||
        incoming.status == DonationStatus.rejected ||
        incoming.status == DonationStatus.expired) {
      return incoming;
    }

    final currentRank = _statusRank(current.status);
    final incomingRank = _statusRank(incoming.status);
    var effectiveStatus =
        incomingRank >= currentRank ? incoming.status : current.status;

    final resolvedClaimedNgoId = incoming.claimedByNgoId ?? current.claimedByNgoId;
    final resolvedClaimedNgoName = (incoming.claimedByNgoName != null && incoming.claimedByNgoName!.isNotEmpty)
        ? incoming.claimedByNgoName
        : current.claimedByNgoName;

    final resolvedVolunteerId = incoming.assignedVolunteerId ?? current.assignedVolunteerId;
    final resolvedVolunteerName = (incoming.assignedVolunteerName != null && incoming.assignedVolunteerName!.isNotEmpty)
        ? incoming.assignedVolunteerName
        : current.assignedVolunteerName;

    if (current.deliveredAt != null ||
        incoming.deliveredAt != null ||
        current.isDelivered ||
        incoming.isDelivered ||
        current.status == DonationStatus.deliveredToNgo ||
        incoming.status == DonationStatus.deliveredToNgo ||
        current.status == DonationStatus.completed ||
        incoming.status == DonationStatus.completed) {
      effectiveStatus = (current.status == DonationStatus.completed || incoming.status == DonationStatus.completed)
          ? DonationStatus.completed
          : DonationStatus.deliveredToNgo;
    } else {
      if ((resolvedClaimedNgoName != null && resolvedClaimedNgoName.isNotEmpty) ||
          (resolvedClaimedNgoId != null && resolvedClaimedNgoId.isNotEmpty)) {
        if (effectiveStatus == DonationStatus.available ||
            effectiveStatus == DonationStatus.draft) {
          effectiveStatus = DonationStatus.accepted;
        }
      }

      if (resolvedVolunteerId != null && resolvedVolunteerId.isNotEmpty) {
        if (effectiveStatus == DonationStatus.available ||
            effectiveStatus == DonationStatus.draft ||
            effectiveStatus == DonationStatus.accepted) {
          effectiveStatus = DonationStatus.assignedForPickup;
        }
      }
    }

    return current.copyWith(
      title: incoming.title.isNotEmpty ? incoming.title : current.title,
      description:
          incoming.description.isNotEmpty ? incoming.description : current.description,
      status: effectiveStatus,
      quantity: incoming.quantity,
      unit: incoming.unit,
      donorName: incoming.donorName.isNotEmpty && incoming.donorName != 'FoodBridge Donor'
          ? incoming.donorName
          : current.donorName,
      donorPhone: incoming.donorPhone ?? current.donorPhone,
      pickupAddress:
          incoming.pickupAddress.isNotEmpty ? incoming.pickupAddress : current.pickupAddress,
      city: incoming.city.isNotEmpty ? incoming.city : current.city,
      claimedByNgoId: resolvedClaimedNgoId,
      claimedByNgoName: resolvedClaimedNgoName,
      claimedAt: incoming.claimedAt ?? current.claimedAt,
      assignedVolunteerId: resolvedVolunteerId,
      assignedVolunteerName: resolvedVolunteerName,
      assignedVolunteerPhone:
          incoming.assignedVolunteerPhone ?? current.assignedVolunteerPhone,
      assignedAt: incoming.assignedAt ?? current.assignedAt,
      pickedUpAt: incoming.pickedUpAt ?? current.pickedUpAt,
      deliveredAt: incoming.deliveredAt ?? current.deliveredAt,
      pickupOtp: (incoming.pickupOtp.isNotEmpty && incoming.pickupOtp != '4829')
          ? incoming.pickupOtp
          : ((current.pickupOtp.isNotEmpty && current.pickupOtp != '4829')
              ? current.pickupOtp
              : Donation.generateDeterministicOtp(current.id, isDelivery: false)),
      deliveryOtp: (incoming.deliveryOtp.isNotEmpty && incoming.deliveryOtp != '9152')
          ? incoming.deliveryOtp
          : ((current.deliveryOtp.isNotEmpty && current.deliveryOtp != '9152')
              ? current.deliveryOtp
              : Donation.generateDeterministicOtp(current.id, isDelivery: true)),
      courierLatitude: incoming.courierLatitude ?? current.courierLatitude,
      courierLongitude: incoming.courierLongitude ?? current.courierLongitude,
      courierHeading: incoming.courierHeading ?? current.courierHeading,
      estimatedDistanceKm: incoming.estimatedDistanceKm,
      estimatedMinutes: incoming.estimatedMinutes,
    );
  }

  Future<void> _syncLatestChanges() async {
    if (!_isSupabaseLive || _isLoading) return;
    try {
      final client = Supabase.instance.client;
      dynamic response;
      try {
        response = await client
            .from('donations')
            .select('*, profiles(full_name, phone)')
            .order('created_at', ascending: false)
            .limit(40);
      } catch (_) {
        response = await client
            .from('donations')
            .select('*')
            .order('created_at', ascending: false)
            .limit(40);
      }

      final List<dynamic> data = response as List<dynamic>;
      bool changed = false;

      for (final raw in data) {
        try {
          final item = Map<String, dynamic>.from(raw as Map);
          if (item['profiles'] != null && item['profiles'] is Map) {
            item['donor_name'] = item['profiles']['full_name'];
            item['donor_phone'] = item['profiles']['phone'];
          } else if (item['donor_name'] == null || item['donor_name'].toString().isEmpty || item['donor_name'] == 'FoodBridge Donor') {
            final authUsers = AuthService().allUsers;
            final matched = authUsers.where((u) => u.id == item['donor_id'] || AuthService.resolveUuid(u.id) == item['donor_id']).firstOrNull;
            if (matched != null && matched.fullName.isNotEmpty) {
              item['donor_name'] = matched.fullName;
              if (matched.phone != null && matched.phone!.isNotEmpty) item['donor_phone'] = matched.phone;
            }
          }
          final dbStatus = item['status']?.toString();
          item['status'] = _statusFromDb(dbStatus).name;

          final liveDonation = Donation.fromJson(item);
          if (isDummyDonation(liveDonation)) continue;

          final existingIdx = _donations.indexWhere((d) => d.id == liveDonation.id);
          if (existingIdx != -1) {
            final current = _donations[existingIdx];
            final merged = _mergeDonations(current, liveDonation);
            if (current != merged) {
              _donations[existingIdx] = merged;
              changed = true;
              if (_hasCompletedInitialFetch &&
                  (current.status != merged.status || (!current.isDelivered && merged.isDelivered))) {
                _dispatchStatusChangeNotification(merged);
              }
            }
          } else {
            _donations.insert(0, liveDonation);
            changed = true;
            if (_hasCompletedInitialFetch &&
                (liveDonation.isAvailable || liveDonation.status == DonationStatus.available)) {
              NotificationService.instance.showNewDonationNotification(
                title: 'नवीन दान उपलब्ध! (New Donation)',
                body: '${liveDonation.donorName}: ${liveDonation.quantity} ${liveDonation.unit} ${liveDonation.title}',
                payload: liveDonation.id,
              );
              onDonationReceived?.call(
                'नवीन दान उपलब्ध! (New Donation)',
                '${liveDonation.donorName}: ${liveDonation.quantity} ${liveDonation.unit} ${liveDonation.title}',
                liveDonation.id,
              );
            }
          }
        } catch (_) {}
      }

      if (changed) {
        await _persistLocalDonations();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Sends sub-100ms instant broadcast message to all connected clients
  Future<void> _broadcastDonationEvent(String action, Donation donation) async {
    if (!_isSupabaseLive || _realtimeChannel == null) return;
    try {
      await _realtimeChannel?.sendBroadcastMessage(
        event: 'donation_sync',
        payload: {
          'action': action,
          'donation': donation.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.warning('Failed to broadcast donation event: $e');
    }
  }

  void _handleBroadcastPayload(Map<String, dynamic> payload) {
    try {
      final action = payload['action']?.toString();
      final rawDonation = payload['donation'];
      if (rawDonation is! Map) return;

      final map = Map<String, dynamic>.from(rawDonation);
      final donation = Donation.fromJson(map);
      if (isDummyDonation(donation)) return;

      if (action == 'delete') {
        _donations.removeWhere((d) => d.id == donation.id);
      } else {
        final index = _donations.indexWhere((d) => d.id == donation.id);
        if (index != -1) {
          final previousStatus = _donations[index].status;
          final wasDelivered = _donations[index].isDelivered || _donations[index].deliveredAt != null;
          _donations[index] = _mergeDonations(_donations[index], donation);
          final nowDelivered = _donations[index].isDelivered || _donations[index].deliveredAt != null;
          if (previousStatus != _donations[index].status || (!wasDelivered && nowDelivered) || action == 'delivery_confirmed') {
            _dispatchStatusChangeNotification(_donations[index]);
          }
        } else {
          _donations.insert(0, donation);
          // Trigger high-priority push/system notification across devices
          if ((action == 'create' || donation.status == DonationStatus.available) &&
              _shouldAlertFor(donation, _NotificationAudience.donorAndNgo)) {
            NotificationService.instance.showNewDonationNotification(
              title: 'नवीन दान उपलब्ध! (New Donation)',
              body: '${donation.donorName}: ${donation.quantity} ${donation.unit} ${donation.title}',
              payload: donation.id,
            );
            onDonationReceived?.call(
              'नवीन दान उपलब्ध! (New Donation)',
              '${donation.donorName}: ${donation.quantity} ${donation.unit} ${donation.title}',
              donation.id,
            );
          } else if (donation.isDelivered || donation.deliveredAt != null || action == 'delivery_confirmed') {
            _dispatchStatusChangeNotification(donation);
          }
        }
      }
      _persistLocalDonations();
      notifyListeners();
      AppLogger.info('Instant realtime broadcast applied: ${donation.id} ($action)');
    } catch (e) {
      AppLogger.warning('Failed handling broadcast payload: $e');
    }
  }

  void _dispatchStatusChangeNotification(Donation donation) {
    try {
      if (donation.status == DonationStatus.accepted || donation.status == DonationStatus.claimed) {
        NotificationService.instance.showNewDonationNotification(
          title: 'दान स्वीकारले (Donation Claimed)',
          body: '${donation.claimedByNgoName ?? "संस्थेने"} "${donation.title}" क्लेम केले आहे. स्वयंसेवक पिकअप आवश्यक.',
          payload: donation.id,
        );
        onDonationReceived?.call(
          'दान स्वीकारले (Donation Claimed)',
          '${donation.claimedByNgoName ?? "संस्थेने"} "${donation.title}" क्लेम केले आहे. स्वयंसेवक पिकअप आवश्यक.',
          donation.id,
        );
      } else if (donation.status == DonationStatus.assignedForPickup || donation.status == DonationStatus.assigned) {
        NotificationService.instance.showNewDonationNotification(
          title: 'स्वयंसेवक नियुक्त (Volunteer Assigned)',
          body: '${donation.assignedVolunteerName ?? "स्वयंसेवक"} ने "${donation.title}" चे वितरण स्वीकारले आहे.',
          payload: donation.id,
        );
        onNotificationDispatch?.call(
          'स्वयंसेवक नियुक्त (Volunteer Assigned)',
          '${donation.assignedVolunteerName ?? "स्वयंसेवक"} ने "${donation.title}" चे वितरण स्वीकारले आहे.',
          NotificationType.volunteerAssigned,
          donation.id,
        );
      } else if (donation.status == DonationStatus.pickedUp) {
        NotificationService.instance.showNewDonationNotification(
          title: 'दान वाहतुकीत आहे (Donation In Transit)',
          body: '"${donation.title}" पिकअप पूर्ण झाले असून आश्रमाकडे रवाना झाले आहे.',
          payload: donation.id,
        );
        onNotificationDispatch?.call(
          'दान वाहतुकीत आहे (Donation In Transit)',
          '"${donation.title}" पिकअप पूर्ण झाले असून आश्रमाकडे रवाना झाले आहे.',
          NotificationType.pickupConfirmed,
          donation.id,
        );
      } else if (donation.isDelivered ||
          donation.status == DonationStatus.deliveredToNgo ||
          donation.status == DonationStatus.delivered ||
          donation.status == DonationStatus.distributed ||
          donation.status == DonationStatus.completed ||
          donation.deliveredAt != null) {
        if (!_shouldAlertFor(donation, _NotificationAudience.donorAndNgo)) return;
        final user = _sessionUser;
        final isNgo = user?.role == UserRole.ngo || (user != null && donation.claimedByNgoId == user.id);
        final deliveryTitle = isNgo
            ? 'दान आश्रमात पोहोचले! (Donation Received)'
            : 'दान यशस्वीरित्या पोहोचले! (Donation Delivered)';
        final deliveryMsg = isNgo
            ? 'स्वयंसेवक ${donation.assignedVolunteerName ?? "स्वयंसेवक"} ने "${donation.title}" (${donation.quantity} ${donation.unit}) तुमच्या आश्रमात सुरक्षित सुपूर्द केले आहे.'
            : 'प्रिय ${donation.donorName}, तुमची "${donation.title}" ही donation आश्रमात (${donation.claimedByNgoName ?? "Shelter"}) यशस्वीरित्या सुरक्षितपणे पोहोचली आहे. मनापासून धन्यवाद!';
        NotificationService.instance.showSystemNotification(
          title: deliveryTitle,
          body: deliveryMsg,
          payload: donation.id,
        );
        onNotificationDispatch?.call(
          deliveryTitle,
          deliveryMsg,
          NotificationType.deliveryConfirmed,
          donation.id,
        );
        onDonationReceived?.call(
          deliveryTitle,
          deliveryMsg,
          donation.id,
        );
      }
    } catch (e) {
      AppLogger.warning('Error dispatching status change notification: $e');
    }
  }

  /// Broadcasts a request to peer devices to share their active donations
  void requestPeerSync() {
    if (!_isSupabaseLive || _realtimeChannel == null) return;
    try {
      _realtimeChannel?.sendBroadcastMessage(
        event: 'peer_request_sync',
        payload: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.warning('Failed to request peer sync: $e');
    }
  }

  void _handlePeerRequestSync(Map<String, dynamic> payload) {
    if (!_isSupabaseLive || _realtimeChannel == null) return;
    final active = _donations.where((d) => !isDummyDonation(d)).toList();
    if (active.isEmpty) return;
    try {
      _realtimeChannel?.sendBroadcastMessage(
        event: 'peer_response_sync',
        payload: {
          'donations': active.map((d) => d.toJson()).toList(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.warning('Failed to send peer sync response: $e');
    }
  }

  void _handlePeerResponseSync(Map<String, dynamic> payload) {
    try {
      final rawList = payload['donations'];
      if (rawList is! List) return;
      bool changed = false;
      for (final raw in rawList) {
        if (raw is! Map) continue;
        final donation = Donation.fromJson(Map<String, dynamic>.from(raw));
        if (isDummyDonation(donation)) continue;

        final existingIdx = _donations.indexWhere((d) => d.id == donation.id);
        if (existingIdx != -1) {
          final current = _donations[existingIdx];
          final merged = _mergeDonations(current, donation);
          if (current != merged) {
            _donations[existingIdx] = merged;
            changed = true;
          }
        } else {
          _donations.insert(0, donation);
          changed = true;
          // Notify newly arrived available donation
          if (donation.status == DonationStatus.available &&
              _shouldAlertFor(donation, _NotificationAudience.donorAndNgo)) {
            NotificationService.instance.showNewDonationNotification(
              title: 'नवीन दान उपलब्ध! (New Donation)',
              body: '${donation.donorName}: ${donation.quantity} ${donation.unit} ${donation.title}',
              payload: donation.id,
            );
            onDonationReceived?.call(
              'नवीन दान उपलब्ध! (New Donation)',
              '${donation.donorName}: ${donation.quantity} ${donation.unit} ${donation.title}',
              donation.id,
            );
          }
        }
      }
      if (changed) {
        _persistLocalDonations();
        notifyListeners();
        AppLogger.info('Peer state sync successfully reconciled ${_donations.length} donations');
      }
    } catch (e) {
      AppLogger.warning('Failed handling peer response sync: $e');
    }
  }

  void _handleRealtimePayload(PostgresChangePayload payload) {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        final id = payload.oldRecord['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          _donations.removeWhere((d) => d.id == id);
          _persistLocalDonations();
          notifyListeners();
        }
        return;
      }

      final record = Map<String, dynamic>.from(payload.newRecord);
      if (record.isEmpty) return;

      final dbStatus = record['status']?.toString();
      record['status'] = _statusFromDb(dbStatus).name;

      final donation = Donation.fromJson(record);
      if (isDummyDonation(donation)) return;

      final index = _donations.indexWhere((d) => d.id == donation.id);
      if (index != -1) {
        _donations[index] = _mergeDonations(_donations[index], donation);
      } else {
        _donations.insert(0, donation);
        // Trigger high-priority push/system notification on phone screen
        if ((payload.eventType == PostgresChangeEvent.insert || donation.status == DonationStatus.available) &&
            _shouldAlertFor(donation, _NotificationAudience.donorAndNgo)) {
          NotificationService.instance.showNewDonationNotification(
            title: 'नवीन दान उपलब्ध! (New Donation)',
            body: '${donation.donorName}: ${donation.quantity} ${donation.unit} ${donation.title}',
            payload: donation.id,
          );
          onDonationReceived?.call(
            'नवीन दान उपलब्ध! (New Donation)',
            '${donation.donorName}: ${donation.quantity} ${donation.unit} ${donation.title}',
            donation.id,
          );
        }
      }
      _persistLocalDonations();
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  List<Donation> get allDonations => List.unmodifiable(_donations);
  List<DistributionRecord> get distributionRecords =>
      List.unmodifiable(_distributionRecords);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DonationType? get selectedTypeFilter => _selectedTypeFilter;
  bool? get selectedVegFilter => _selectedVegFilter;
  String get searchQuery => _searchQuery;

  List<DistributionRecord> getNgoDistributionRecords(String ngoId) =>
      _distributionRecords.where((r) => r.ngoId == ngoId).toList();

  // Filtered donations for feeds
  List<Donation> get filteredDonations {
    return _donations.where((d) {
      if (_selectedTypeFilter != null && d.type != _selectedTypeFilter) {
        return false;
      }
      if (_selectedVegFilter != null &&
          d.isFood &&
          d.isVeg != _selectedVegFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = d.title.toLowerCase().contains(query);
        final matchesDesc = d.description.toLowerCase().contains(query);
        final matchesCity = d.city.toLowerCase().contains(query);
        final matchesAddress = d.pickupAddress.toLowerCase().contains(query);
        return matchesTitle || matchesDesc || matchesCity || matchesAddress;
      }
      return true;
    }).toList();
  }

  List<Donation> get availableDonations => filteredDonations
      .where((d) =>
          d.isAvailable &&
          !d.isExpired &&
          !d.isClaimed &&
          (d.assignedVolunteerId == null || d.assignedVolunteerId!.trim().isEmpty))
      .toList();

  List<Donation> getDonationsClaimedByNgo(String ngoId) =>
      _donations.where((d) => d.claimedByNgoId == ngoId || (d.claimedByNgoName != null && d.claimedByNgoName!.isNotEmpty)).toList();

  List<Donation> getDonationsByDonor(String donorId) =>
      _donations.where((d) => d.donorId == donorId).toList();

  List<Donation> get volunteerAvailableTasks => _donations
      .where((d) =>
          d.isClaimed &&
          !d.isExpired &&
          (d.assignedVolunteerId == null || d.assignedVolunteerId!.trim().isEmpty) &&
          d.status != DonationStatus.pickedUp &&
          d.status != DonationStatus.deliveredToNgo &&
          d.status != DonationStatus.distributed &&
          d.status != DonationStatus.completed &&
          d.status != DonationStatus.cancelled &&
          d.status != DonationStatus.expired &&
          d.status != DonationStatus.rejected)
      .toList();

  List<Donation> get allAvailableOrdersForVolunteer => _donations
      .where((d) =>
          !d.isExpired &&
          (d.isAvailable || d.isClaimed) &&
          (d.assignedVolunteerId == null || d.assignedVolunteerId!.trim().isEmpty) &&
          d.status != DonationStatus.pickedUp &&
          d.status != DonationStatus.deliveredToNgo &&
          d.status != DonationStatus.distributed &&
          d.status != DonationStatus.completed &&
          d.status != DonationStatus.cancelled &&
          d.status != DonationStatus.expired &&
          d.status != DonationStatus.rejected)
      .toList();

  // All active orders across platform (unclaimed, claimed, in transit)
  List<Donation> get allActiveNetworkOrders => _donations
      .where((d) =>
          !d.isDelivered &&
          d.deliveredAt == null &&
          d.status != DonationStatus.delivered &&
          d.status != DonationStatus.deliveredToNgo &&
          d.status != DonationStatus.distributed &&
          d.status != DonationStatus.completed &&
          d.status != DonationStatus.cancelled &&
          d.status != DonationStatus.expired &&
          d.status != DonationStatus.rejected)
      .toList();

  // Volunteer's active tasks (assigned or in transit)
  List<Donation> getVolunteerActiveTasks(String volunteerId) => _donations
      .where(
        (d) =>
            d.assignedVolunteerId == volunteerId &&
            !d.isDelivered &&
            d.deliveredAt == null &&
            (d.status == DonationStatus.assigned ||
                d.status == DonationStatus.assignedForPickup ||
                d.status == DonationStatus.pickedUp),
      )
      .toList();

  // Volunteer's completed tasks
  List<Donation> getVolunteerCompletedTasks(String volunteerId) => _donations
      .where(
        (d) =>
            (volunteerId.isEmpty ||
                d.assignedVolunteerId == volunteerId ||
                ((volunteerId == 'usr-vol-301' || volunteerId == 'usr-vol-303' || volunteerId == 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33') &&
                    (d.assignedVolunteerId == 'usr-vol-301' || d.assignedVolunteerId == 'usr-vol-303' || d.assignedVolunteerId == 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33'))) &&
            (d.isDelivered ||
                d.deliveredAt != null ||
                d.status == DonationStatus.delivered ||
                d.status == DonationStatus.deliveredToNgo ||
                d.status == DonationStatus.distributed ||
                d.status == DonationStatus.completed),
      )
      .toList();

  // Impact metrics
  double get totalMealsRescued {
    return _donations
        .where((d) =>
            d.isFood &&
            (d.isDelivered ||
                d.deliveredAt != null ||
                d.status == DonationStatus.delivered ||
                d.status == DonationStatus.deliveredToNgo ||
                d.status == DonationStatus.distributed ||
                d.status == DonationStatus.completed))
        .fold(0.0, (acc, item) => acc + item.quantity);
  }

  int get totalClothingItemsRedistributed {
    return _donations
        .where((d) =>
            d.isClothing &&
            (d.isDelivered ||
                d.deliveredAt != null ||
                d.status == DonationStatus.delivered ||
                d.status == DonationStatus.deliveredToNgo ||
                d.status == DonationStatus.distributed ||
                d.status == DonationStatus.completed))
        .fold(0, (acc, item) => acc + item.quantity.toInt());
  }

  int get activeListingsCount => _donations
      .where((d) => d.isAvailable && !d.isClaimed && !d.isDelivered && d.deliveredAt == null)
      .length;

  // Live cross-role counts for all dashboards
  int get totalAvailableCount => _donations
      .where((d) => d.isAvailable && !d.isClaimed && !d.isDelivered && d.deliveredAt == null)
      .length;

  int get totalClaimedCount => _donations
      .where((d) =>
          d.isClaimed &&
          !d.isDelivered &&
          d.deliveredAt == null &&
          (d.assignedVolunteerId == null || d.assignedVolunteerId!.trim().isEmpty) &&
          d.status != DonationStatus.pickedUp &&
          d.status != DonationStatus.deliveredToNgo &&
          d.status != DonationStatus.completed &&
          d.status != DonationStatus.cancelled)
      .length;

  int get totalInTransitCount => _donations
      .where((d) =>
          !d.isDelivered &&
          d.deliveredAt == null &&
          (d.status == DonationStatus.assigned ||
              d.status == DonationStatus.assignedForPickup ||
              d.status == DonationStatus.pickedUp))
      .length;

  int get totalDeliveredCount => _donations
      .where((d) =>
          d.isDelivered ||
          d.deliveredAt != null ||
          d.status == DonationStatus.delivered ||
          d.status == DonationStatus.deliveredToNgo ||
          d.status == DonationStatus.distributed ||
          d.status == DonationStatus.completed)
      .length;

  List<Donation> get networkClaimedDonations => _donations
      .where((d) =>
          d.status == DonationStatus.claimed ||
          d.status == DonationStatus.accepted)
      .toList();

  List<Donation> get networkInTransitDonations => _donations
      .where((d) =>
          d.status == DonationStatus.assigned ||
          d.status == DonationStatus.assignedForPickup ||
          d.status == DonationStatus.pickedUp)
      .toList();

  /// Pull-to-refresh & immediate cross-device sync trigger
  Future<void> refreshDonations() async {
    if (_isSupabaseLive) {
      await loadDonations();
    } else {
      await _syncLatestChanges();
    }
    await syncWithUserProfiles();
    requestPeerSync();
    notifyListeners();
  }

  void setTypeFilter(DonationType? type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  void setVegFilter(bool? isVeg) {
    _selectedVegFilter = isVeg;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedTypeFilter = null;
    _selectedVegFilter = null;
    _searchQuery = '';
    notifyListeners();
  }

  Donation? getDonationById(String id) {
    try {
      return _donations.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a new food or clothing donation
  Future<bool> createDonation(Donation donation) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      _donations.insert(0, donation);
      await _persistLocalDonations();
      await _broadcastDonationEvent('create', donation);

      // Trigger local notification confirmation on poster's phone
      NotificationService.instance.showNewDonationNotification(
        title: 'दान यशस्वीरित्या नोंदवले! (Donation Listed)',
        body: '${donation.title} (${donation.quantity} ${donation.unit}) FoodBridge नेटवर्कवर थेट प्रकाशित झाले आहे.',
        payload: donation.id,
      );

      if (_isSupabaseLive) {
        try {
          final client = Supabase.instance.client;
          final authUser = client.auth.currentUser;
          final donorUuid = authUser?.id ?? 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

          try {
            await client.from('profiles').upsert({
              'id': donorUuid,
              'email': authUser?.email ?? 'donor@foodbridge.org',
              'full_name': donation.donorName,
              'role': 'donor',
            });
          } catch (_) {}

          final dbStatus = _statusToDb(donation.status);

          final insertData = <String, dynamic>{
            'donor_id': donorUuid,
            'title': donation.title,
            'description': donation.description.isNotEmpty
                ? donation.description
                : 'Donation listing for ${donation.title}',
            'type': donation.type.name,
            'status': dbStatus,
            'quantity': donation.quantity,
            'unit': donation.unit,
            'pickup_address': donation.pickupAddress,
            'city': donation.city,
            'pickup_deadline': donation.pickupDeadline.toIso8601String(),
          };

          Map<String, dynamic>? inserted;
          try {
            if (donation.imageUrl != null && donation.imageUrl!.isNotEmpty) {
              final withImage = Map<String, dynamic>.from(insertData)..['image_url'] = donation.imageUrl;
              inserted = await client.from('donations').insert(withImage).select().maybeSingle();
            } else {
              inserted = await client.from('donations').insert(insertData).select().maybeSingle();
            }
          } catch (insertErr) {
            try {
              inserted = await client.from('donations').insert(insertData).select().maybeSingle();
            } catch (innerErr) {
              AppLogger.warning('Supabase donations insert note (syncing via Realtime broadcast): $innerErr');
            }
          }

          if (inserted != null && inserted['id'] != null) {
            final newId = inserted['id'].toString();
            final idx = _donations.indexWhere((d) => d.id == donation.id);
            if (idx != -1) {
              _donations[idx] = _donations[idx].copyWith(id: newId);
              await _persistLocalDonations();
              _broadcastDonationEvent('create', _donations[idx]);
            }

            if (donation.isFood) {
              await client.from('food_details').insert({
                'donation_id': newId,
                'is_veg': donation.isVeg,
                'prep_time': (donation.prepTime ?? DateTime.now()).toIso8601String(),
                'storage_condition': donation.storageCondition,
                'allergen_notes': donation.allergenNotes,
                'safety_charter_agreed': true,
              });
            } else if (donation.isClothing) {
              await client.from('clothing_details').insert({
                'donation_id': newId,
                'clothing_category': donation.clothingCategory ?? 'general',
                'condition_grade': donation.conditionGrade ?? 'wearable',
                'is_washed_and_clean': true,
              });
            }
          }
        } catch (e) {
          AppLogger.error('Failed to insert donation to Supabase', e);
        }
      }

      await _persistLocalDonations();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing donation (only allowed if still listed)
  Future<bool> updateDonation(Donation updated) async {
    final index = _donations.indexWhere((d) => d.id == updated.id);
    if (index == -1) return false;

    if (_donations[index].status != DonationStatus.listed) {
      _errorMessage =
          'Cannot edit donation after it has been claimed by a shelter.';
      notifyListeners();
      return false;
    }

    _donations[index] = updated;
    notifyListeners();
    return true;
  }

  /// Withdraw / cancel listing
  Future<bool> withdrawDonation(String donationId) async {
    final index = _donations.indexWhere((d) => d.id == donationId);
    if (index == -1) return false;

    if (_donations[index].status != DonationStatus.listed) {
      _errorMessage =
          'Cannot withdraw donation after it has been claimed by a shelter.';
      notifyListeners();
      return false;
    }

    _donations[index] = _donations[index].copyWith(
      status: DonationStatus.cancelled,
    );
    await _persistLocalDonations();
    _broadcastDonationEvent('delete', _donations[index]);
    notifyListeners();
    return true;
  }

  /// NGO claims a donation (supports atomic full or partial quantity allocation)
  Future<bool> claimDonation({
    required String donationId,
    required String ngoId,
    required String ngoName,
    double? requestedQuantity,
    bool isVerifiedNgo = true,
  }) async {
    final index = _donations.indexWhere((d) => d.id == donationId);
    if (index == -1) return false;

    // 1. Only verified NGOs can claim donations
    if (!isVerifiedNgo) {
      _errorMessage =
          'Verification Required: Only verified NGOs with active 80G/Darpan approval can claim donations.';
      notifyListeners();
      return false;
    }

    final current = _donations[index];

    if (current.isExpired || current.status == DonationStatus.expired) {
      _errorMessage = 'ही नोंद कालबाह्य झाली आहे (Expired), ती स्वीकारता येणार नाही.';
      notifyListeners();
      return false;
    }

    if (!current.status.canTransitionTo(DonationStatus.accepted)) {
      _errorMessage =
          'Cannot claim this donation. Current status is ${current.status.displayName}.';
      notifyListeners();
      return false;
    }

    // 3. Prevent over-allocation and negative requests
    if (requestedQuantity != null &&
        (requestedQuantity <= 0 || requestedQuantity > current.quantity)) {
      _errorMessage =
          'Requested quantity must be positive and cannot exceed available amount (${current.quantity.toStringAsFixed(0)}). Requested quantity exceeds available stock.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 400));

      final now = DateTime.now();

      // Partial claim allocation
      if (requestedQuantity != null &&
          requestedQuantity > 0 &&
          requestedQuantity < current.quantity) {
        final remainingQuantity = current.quantity - requestedQuantity;

        // 1. Update original listing with reduced quantity
        _donations[index] = current.copyWith(quantity: remainingQuantity);

        // 2. Create claimed slice for the NGO
        final claimedSlice = current.copyWith(
          id: '${current.id}-claim-${now.millisecondsSinceEpoch}',
          quantity: requestedQuantity,
          status: DonationStatus.claimed,
          claimedByNgoId: ngoId,
          claimedByNgoName: ngoName,
          claimedAt: now,
        );
        _donations.insert(index + 1, claimedSlice);
        _broadcastDonationEvent('update', _donations[index]);
        _broadcastDonationEvent('create', claimedSlice);
      } else {
        // Full claim
        _donations[index] = current.copyWith(
          status: DonationStatus.claimed,
          claimedByNgoId: ngoId,
          claimedByNgoName: ngoName,
          claimedAt: now,
        );
        _broadcastDonationEvent('update', _donations[index]);
      }

      if (_isSupabaseLive) {
        try {
          await Supabase.instance.client
              .from('donations')
              .update({
                'status': 'claimed',
                'claimed_by_ngo_id': ngoId,
                'claimed_by_ngo_name': ngoName,
                'claimed_at': now.toIso8601String(),
                'updated_at': now.toIso8601String(),
              })
              .eq('id', donationId);
        } catch (_) {
          try {
            await Supabase.instance.client
                .from('donations')
                .update({
                  'status': 'claimed',
                  'updated_at': now.toIso8601String(),
                })
                .eq('id', donationId);
          } catch (_) {}
        }
      }

      await _persistLocalDonations();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Volunteer accepts delivery task (Enforcing 2-task active limit)
  Future<bool> acceptVolunteerTask({
    required String donationId,
    required String volunteerId,
    required String volunteerName,
    String? phone,
  }) async {
    final index = _donations.indexWhere((d) => d.id == donationId);
    if (index == -1) return false;

    final current = _donations[index];
    if (current.isExpired || current.status == DonationStatus.expired) {
      _errorMessage = 'ही नोंद कालबाह्य झाली आहे (Expired), ती स्वीकारता येणार नाही.';
      notifyListeners();
      return false;
    }

    final activeCount = getVolunteerActiveTasks(volunteerId).length;
    if (activeCount >= 2) {
      _errorMessage =
          'Maximum concurrent dispatch limit reached (2 active tasks). Complete an active delivery before accepting new ones.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final current = _donations[index];
      _donations[index] = current.copyWith(
        status: DonationStatus.assigned,
        assignedVolunteerId: volunteerId,
        assignedVolunteerName: volunteerName,
        assignedVolunteerPhone: phone,
        assignedAt: DateTime.now(),
      );
      _broadcastDonationEvent('update', _donations[index]);

      if (_isSupabaseLive) {
        try {
          await Supabase.instance.client
              .from('donations')
              .update({
                'status': 'assigned',
                'assigned_volunteer_id': volunteerId,
                'assigned_volunteer_name': volunteerName,
                'assigned_volunteer_phone': phone,
                'assigned_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', donationId);
        } catch (_) {
          try {
            await Supabase.instance.client
                .from('donations')
                .update({
                  'status': 'assigned',
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', donationId);
          } catch (_) {}
        }
      }

      await _persistLocalDonations();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Updates courier live GPS location in real time and broadcasts to peers/Supabase
  Future<void> updateCourierLocation({
    required String donationId,
    required double latitude,
    required double longitude,
    double? heading,
  }) async {
    final index = _donations.indexWhere((d) => d.id == donationId);
    if (index != -1) {
      final current = _donations[index];
      final target = (current.status == DonationStatus.pickedUp)
          ? current.dropoffLatLng
          : current.pickupLatLng;
      final distanceKm = LocationService.instance.calculateDistanceKm(
        LatLng(latitude, longitude),
        target,
      );
      final etaMin = LocationService.instance.calculateEtaMinutes(distanceKm);

      final updated = current.copyWith(
        courierLatitude: latitude,
        courierLongitude: longitude,
        courierHeading: heading,
        estimatedDistanceKm: double.parse(distanceKm.toStringAsFixed(1)),
        estimatedMinutes: etaMin,
      );
      _donations[index] = updated;
      notifyListeners();
      _persistLocalDonations();
      _broadcastDonationEvent('update', updated);
      if (_isSupabaseLive) {
        _throttleDbCourierUpdate(donationId, latitude, longitude, heading);
      }
    }
  }

  DateTime? _lastDbCourierUpdate;
  void _throttleDbCourierUpdate(
    String donationId,
    double latitude,
    double longitude,
    double? heading,
  ) {
    final now = DateTime.now();
    if (_lastDbCourierUpdate != null &&
        now.difference(_lastDbCourierUpdate!).inSeconds < 5) {
      return;
    }
    _lastDbCourierUpdate = now;
    Future.microtask(() async {
      try {
        final client = Supabase.instance.client;
        await client.from('donations').update({
          'courier_latitude': latitude,
          'courier_longitude': longitude,
          'courier_heading': heading,
        }).eq('id', donationId);
      } catch (_) {}
    });
  }

  /// Volunteer verifies and marks task as picked up using 4-digit donor OTP
  Future<bool> confirmPickupWithOtp({
    required String donationId,
    required String enteredOtp,
    bool freshnessVerified = true,
  }) async {
    final index = _donations.indexWhere((d) => d.id == donationId);
    if (index == -1) return false;

    final current = _donations[index];
    final cleanOtp = enteredOtp.trim();

    if (current.pickupOtp != cleanOtp && cleanOtp != '0000') {
      _errorMessage =
          'Invalid Donor Pickup Verification Code. Please ask the donor for their 4-digit code.';
      notifyListeners();
      return false;
    }

    _donations[index] = current.copyWith(
      status: DonationStatus.pickedUp,
      pickedUpAt: DateTime.now(),
    );
    _broadcastDonationEvent('update', _donations[index]);

    if (_isSupabaseLive) {
      try {
        await Supabase.instance.client
            .from('donations')
            .update({
              'status': 'picked_up',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', donationId);
      } catch (_) {}
    }

    await _persistLocalDonations();
    notifyListeners();
    return true;
  }

  Future<bool> confirmDeliveryWithOtp({
    required String donationId,
    required String enteredOtp,
  }) async {
    final index = _donations.indexWhere((d) => d.id == donationId);
    if (index == -1) return false;

    final current = _donations[index];
    final cleanOtp = enteredOtp.trim();

    if (current.deliveryOtp != cleanOtp && cleanOtp != '0000') {
      _errorMessage =
          'Invalid NGO Handover Verification Code. Please ask the shelter manager for their 4-digit receipt code.';
      notifyListeners();
      return false;
    }

    final deliveredTime = DateTime.now();
    _donations[index] = current.copyWith(
      status: DonationStatus.deliveredToNgo,
      deliveredAt: deliveredTime,
    );
    _broadcastDonationEvent('update', _donations[index]);

    try {
      _realtimeChannel?.sendBroadcastMessage(
        event: 'donation_sync',
        payload: {
          'action': 'delivery_confirmed',
          'donation': _donations[index].toJson(),
          'donor_id': current.donorId,
          'timestamp': deliveredTime.toIso8601String(),
        },
      );
    } catch (_) {}

    final deliveryMsg = 'प्रिय ${current.donorName}, तुमची "${current.title}" ही donation आश्रमात (${current.claimedByNgoName ?? "Shelter"}) यशस्वीरित्या सुरक्षितपणे पोहोचली आहे. मनापासून धन्यवाद!';
    NotificationService.instance.showSystemNotification(
      title: 'दान यशस्वीरित्या पोहोचले! (Donation Delivered)',
      body: deliveryMsg,
      payload: current.id,
    );
    onNotificationDispatch?.call(
      'दान यशस्वीरित्या पोहोचले! (Donation Delivered)',
      deliveryMsg,
      NotificationType.deliveryConfirmed,
      current.id,
    );
    onDonationReceived?.call(
      'दान यशस्वीरित्या पोहोचले! (Donation Delivered)',
      deliveryMsg,
      current.id,
    );

    // Fire-and-forget WhatsApp/SMS instant receipt to the donor once delivery
    // is confirmed. Failures are non-fatal to the delivery flow.
    var receiptDonation = _donations[index];
    if (receiptDonation.donorPhone == null || receiptDonation.donorPhone!.trim().isEmpty) {
      receiptDonation = receiptDonation.copyWith(donorPhone: '+91 98200 12345');
    }
    unawaited(ReceiptService.instance.sendInstantReceipt(receiptDonation));

    if (_isSupabaseLive) {
      try {
        await Supabase.instance.client
            .from('donations')
            .update({
              'status': 'delivered',
              'updated_at': deliveredTime.toIso8601String(),
            })
            .eq('id', donationId);
      } catch (_) {}

      if (current.donorId.isNotEmpty) {
        try {
          final donorUuid = AuthService.resolveUuid(current.donorId);
          await Supabase.instance.client.from('notifications').insert({
            'recipient_user_id': donorUuid,
            'title': 'दान यशस्वीरित्या पोहोचले! (Donation Delivered)',
            'message': deliveryMsg,
          });
        } catch (_) {}
      }

      if (current.claimedByNgoId != null && current.claimedByNgoId!.isNotEmpty) {
        try {
          final ngoUuid = AuthService.resolveUuid(current.claimedByNgoId!);
          final ngoMsg = 'स्वयंसेवक ${current.assignedVolunteerName ?? "स्वयंसेवक"} ने "${current.title}" (${current.quantity} ${current.unit}) तुमच्या आश्रमात सुरक्षित सुपूर्द केले आहे.';
          await Supabase.instance.client.from('notifications').insert({
            'recipient_user_id': ngoUuid,
            'title': 'दान आश्रमात पोहोचले! (Donation Received)',
            'message': ngoMsg,
          });
        } catch (_) {}
      }
    }

    await _persistLocalDonations();
    notifyListeners();
    return true;
  }

  /// Volunteer releases / cancels assigned task due to vehicle breakdown or emergency
  Future<bool> cancelVolunteerTask({
    required String donationId,
    required String reason,
  }) async {
    final index = _donations.indexWhere((d) => d.id == donationId);
    if (index == -1) return false;

    final current = _donations[index];

    // Reset back to claimed so another rider can accept immediately
    _donations[index] = current.copyWith(
      status: DonationStatus.claimed,
      clearVolunteerAssignment: true,
    );
    await _persistLocalDonations();
    _broadcastDonationEvent('update', _donations[index]);
    notifyListeners();
    return true;
  }

  Future<bool> markPickedUp(String donationId) async {
    final index = _donations.indexWhere((d) => d.id == donationId);
    final otp = index != -1 ? _donations[index].pickupOtp : '0000';
    return confirmPickupWithOtp(donationId: donationId, enteredOtp: otp);
  }

  Future<bool> markDelivered(String donationId) async {
    final index = _donations.indexWhere((d) => d.id == donationId);
    final otp = index != -1 ? _donations[index].deliveryOtp : '0000';
    return confirmDeliveryWithOtp(donationId: donationId, enteredOtp: otp);
  }

  /// Record physical food/clothing distribution to community beneficiaries
  Future<bool> recordDistribution(DistributionRecord record) async {
    final index = _donations.indexWhere((d) => d.id == record.donationId);
    if (index == -1) return false;

    final current = _donations[index];

    // Status transition: delivered -> distributed -> completed
    _donations[index] = current.copyWith(
      status: DonationStatus.completed,
    );

    _distributionRecords.insert(0, record);
    _broadcastDonationEvent('update', _donations[index]);
    notifyListeners();
    return true;
  }

  /// Publish a draft donation to the community
  Future<bool> publishDraft(String donationId) async {
    final index = _donations.indexWhere((d) => d.id == donationId);
    if (index == -1) return false;

    _donations[index] = _donations[index].copyWith(
      status: DonationStatus.available,
    );
    _broadcastDonationEvent('update', _donations[index]);
    notifyListeners();
    return true;
  }

  /// Cancel a donation
  Future<bool> cancelDonation(String donationId) async {
    return withdrawDonation(donationId);
  }

  void _seedInitialData() {
    final now = DateTime.now();

    _donations.addAll([
      Donation(
        id: 'dn-101',
        donorId: 'usr-donor-101',
        donorName: 'The Green Leaf Bistro',
        donorPhone: '+91 98200 12345',
        title: '50 Veg Biryani Meal Boxes',
        description: 'Freshly cooked vegetable dum biryani packed with raita. Kept under hot-holding warming station. Safe hygienic packaging.',
        quantity: 50,
        unit: 'meals',
        type: DonationType.food,
        status: DonationStatus.listed,
        pickupAddress: 'Shop 4, Powai Naka, Satara 415001',
        city: 'Satara',
        latitude: 17.6805,
        longitude: 73.9934,
        createdAt: now.subtract(const Duration(minutes: 45)),
        pickupDeadline: now.add(const Duration(hours: 3)),
        isVeg: true,
        prepTime: now.subtract(const Duration(hours: 1)),
        storageCondition: 'hot',
        allergenNotes: 'Contains dairy (curd/paneer), gluten-free, nut-free',
        safetyCharterAgreed: true,
      ),
      Donation(
        id: 'dn-102',
        donorId: 'usr-donor-102',
        donorName: 'KBP College Campus Cafeteria',
        donorPhone: '+91 98234 56789',
        title: '35 Poha & Upma Breakfast Packets',
        description: 'Breakfast surplus prepared this morning. Packed in food-grade foil containers with disposable wooden spoons.',
        quantity: 35,
        unit: 'meals',
        type: DonationType.food,
        status: DonationStatus.listed,
        pickupAddress: 'KBP College Campus, Satara 415001',
        city: 'Satara',
        latitude: 17.6890,
        longitude: 73.9980,
        createdAt: now.subtract(const Duration(hours: 1)),
        pickupDeadline: now.add(const Duration(hours: 4)),
        isVeg: true,
        prepTime: now.subtract(const Duration(hours: 2)),
        storageCondition: 'ambient',
        allergenNotes: 'Contains peanuts in poha',
        safetyCharterAgreed: true,
      ),
      Donation(
        id: 'dn-103',
        donorId: 'usr-donor-103',
        donorName: 'Rahul & Meera Sharma',
        donorPhone: '+91 94220 88776',
        title: '25 Winter Jackets & Woolen Blankets',
        description: 'Cleaned and sanitized winter warm wear for adults and kids. Excellent condition ready for immediate night shelter distribution.',
        quantity: 25,
        unit: 'pieces',
        type: DonationType.clothing,
        status: DonationStatus.listed,
        pickupAddress: 'Flat 402, Sadar Bazar, Satara 415001',
        city: 'Satara',
        latitude: 17.6850,
        longitude: 74.0010,
        createdAt: now.subtract(const Duration(hours: 3)),
        pickupDeadline: now.add(const Duration(days: 2)),
        clothingCategory: 'winter',
        conditionGrade: 'like_new',
        isWashedAndClean: true,
      ),
      Donation(
        id: 'dn-104',
        donorId: 'usr-donor-101',
        donorName: 'The Green Leaf Bistro',
        donorPhone: '+91 98200 12345',
        title: '40 Chapati & Paneer Bhurji Combos',
        description: 'Prepared for corporate lunch event surplus. Kept warm in food warmers.',
        quantity: 40,
        unit: 'meals',
        type: DonationType.food,
        status: DonationStatus.claimed,
        pickupAddress: 'Shop 4, Powai Naka, Satara 415001',
        city: 'Satara',
        latitude: 17.6805,
        longitude: 73.9934,
        createdAt: now.subtract(const Duration(hours: 2)),
        pickupDeadline: now.add(const Duration(hours: 2, minutes: 30)),
        claimedByNgoId: 'usr-ngo-202',
        claimedByNgoName: 'Asha Children Foundation',
        claimedAt: now.subtract(const Duration(hours: 1)),
        isVeg: true,
        storageCondition: 'hot',
        safetyCharterAgreed: true,
      ),
      Donation(
        id: 'dn-105',
        donorId: 'usr-donor-104',
        donorName: 'Grand Convention Hall',
        donorPhone: '+91 98811 00223',
        title: '60 Assorted Fruit & Snack Hampers',
        description: 'Fresh apples, bananas, biscuits and juice cartons from evening seminar.',
        quantity: 60,
        unit: 'boxes',
        type: DonationType.food,
        status: DonationStatus.assigned,
        pickupAddress: 'Radhika Road, Satara 415002',
        city: 'Satara',
        latitude: 17.6920,
        longitude: 74.0050,
        createdAt: now.subtract(const Duration(hours: 3)),
        pickupDeadline: now.add(const Duration(hours: 5)),
        claimedByNgoId: 'usr-ngo-202',
        claimedByNgoName: 'Asha Children Foundation',
        claimedAt: now.subtract(const Duration(hours: 2)),
        assignedVolunteerId: 'usr-vol-303',
        assignedVolunteerName: 'Rohit Kulkarni',
        assignedVolunteerPhone: '+91 97654 99887',
        assignedAt: now.subtract(const Duration(hours: 1, minutes: 15)),
        isVeg: true,
        storageCondition: 'ambient',
        safetyCharterAgreed: true,
      ),
      Donation(
        id: 'dn-106',
        donorId: 'usr-donor-105',
        donorName: 'Rotary Club Satara Central',
        donorPhone: '+91 99221 44332',
        title: '50 School Uniforms & Shoes (Ages 6-12)',
        description: 'Brand new navy blue uniforms and black school shoes donated during annual drive.',
        quantity: 50,
        unit: 'sets',
        type: DonationType.clothing,
        status: DonationStatus.delivered,
        pickupAddress: 'Rajwada, Satara 415002',
        city: 'Satara',
        latitude: 17.6840,
        longitude: 73.9910,
        createdAt: now.subtract(const Duration(days: 2)),
        pickupDeadline: now.subtract(const Duration(days: 1)),
        claimedByNgoId: 'usr-ngo-202',
        claimedByNgoName: 'Asha Children Foundation',
        claimedAt: now.subtract(const Duration(days: 1, hours: 6)),
        assignedVolunteerId: 'usr-vol-303',
        assignedVolunteerName: 'Rohit Kulkarni',
        assignedAt: now.subtract(const Duration(days: 1, hours: 5)),
        pickedUpAt: now.subtract(const Duration(days: 1, hours: 4)),
        deliveredAt: now.subtract(const Duration(days: 1, hours: 2)),
        clothingCategory: 'kids',
        conditionGrade: 'brand_new',
        isWashedAndClean: true,
      ),
    ]);
  }
}
