import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kwikpro/models/technician_model.dart';
import '../models/technician_search_result.dart';
import '../models/user_model.dart';
import 'package:kwikpro/services/location_service.dart';

import 'google_maps_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;


   // recommendation algorithm
  static const double _serviceWeight = 40;
  static const double _defaultServiceWeight = 10;
  static const double _distance2Km = 20;
  static const double _distance5Km = 15;
  static const double _distance10Km = 10;
  static const double _distance20Km = 5;
  static const double _ratingWeight = 3;
  static const double _completedJobsWeight = 0.1;
  static const double _experienceWeight = 0.5;
  static const double _verifiedBonus = 5;

  // Save user
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // Get user
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    } else {
      return null;
    }
  }
  Future<List<TechnicianModel>> getTechnicians() async {
    final snapshot = await _db.collection('technicians').get();

    return snapshot.docs.map((doc) => TechnicianModel.fromMap(doc.data())).toList();
  }

  Future<void> saveTechnician(TechnicianModel technician) async {
    await _db.collection('technicians').doc(technician.uid).set(technician.toMap());
  }

  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    await _db.collection('technicians').doc(uid).update({'isOnline': isOnline});
  }

  Future<void> updatePreferredService({
    required String userId,
    required String service,
  }) async {
    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) return;

      final data = snapshot.data() ?? {};

      final preferredServices =
      Map<String, dynamic>.from(
        data['preferredServices'] ?? {},
      );

      preferredServices[service] =
          ((preferredServices[service] ?? 0) as num).toInt() + 1;

      transaction.update(userRef, {
        'preferredServices': preferredServices,
      });
    });
  }


  Future<List<TechnicianModel>> getNearbyTechnicians({
    required double userLat,
    required double userLng,
    int limit = 10,
  }) async {

    final snapshot = await _db
        .collection('technicians')
        .where('isVerified', isEqualTo: true)
        .where('isOnline', isEqualTo: true)
        .where('isSuspended', isEqualTo: false)
        .get();

    final technicians = <TechnicianModel>[];

    for (final doc in snapshot.docs) {
      final tech = TechnicianModel.fromMap(doc.data());

      if (tech.lat == null || tech.lng == null) {
        continue;
      }

      final distance = LocationService.calculateDistance(
        userLat,
        userLng,
        tech.lat!,
        tech.lng!,
      );

      technicians.add(
        tech.copyWith(
          distanceKm: distance,
        ),
      );
    }

    technicians.sort(
          (a, b) => (a.distanceKm ?? 999999)
          .compareTo(b.distanceKm ?? 999999),
    );

    final limited = technicians.length > limit
        ? technicians.take(limit).toList()
        : technicians;

    return await attachRouteInfo(
      technicians: limited,
      userLat: userLat,
      userLng: userLng,
    );
  }

  Future<List<TechnicianModel>> getRecentlyBookedTechnicians({
    required double userLat,
    required double userLng,
    int limit = 5,
  }) async {
    final bookingsSnapshot = await _db
        .collection('recent_bookings')
        .orderBy('completedAt', descending: true)
        .limit(20)
        .get();

    if (bookingsSnapshot.docs.isEmpty) {
      return [];
    }

    final technicians = <TechnicianModel>[];
    final technicianIds = <String>{};

    // Get unique technician IDs
    for (final booking in bookingsSnapshot.docs) {
      technicianIds.add(booking['technicianId']);
    }

    // Load technicians
    final technicianDocs = await Future.wait(
      technicianIds.map(
            (id) => _db.collection('technicians').doc(id).get(),
      ),
    );

    for (final techDoc in technicianDocs) {
      if (!techDoc.exists) continue;

      final tech = TechnicianModel.fromMap(techDoc.data()!);

      if (tech.lat == null || tech.lng == null) continue;

      final distance = LocationService.calculateDistance(
        userLat,
        userLng,
        tech.lat!,
        tech.lng!,
      );

      technicians.add(
        tech.copyWith(
          distanceKm: distance,
        ),
      );
    }

    // Keep your sort
    technicians.sort(
          (a, b) => (b.completedJobs ?? 0).compareTo(a.completedJobs ?? 0),
    );

    final limited = technicians.length > limit
        ? technicians.take(limit).toList()
        : technicians;

    return await attachRouteInfo(
      technicians: limited,
      userLat: userLat,
      userLng: userLng,
    );
  }


  Future<List<TechnicianModel>> getRecommendedTechnicians({
    required String userId,
    required double userLat,
    required double userLng,
    int limit = 10,
  }) async {
    final userDoc = await _db.collection('users').doc(userId).get();

    if (!userDoc.exists) return [];

    final userData = userDoc.data()!;

    final preferredServices = Map<String, dynamic>.from(
      userData['preferredServices'] ?? {},
    );

    // Reuse nearby technician logic
    final nearby = await getNearbyTechnicians(
      userLat: userLat,
      userLng: userLng,
      limit: 100,
    );

    final recommendations = <TechnicianModel>[];

    for (final tech in nearby) {
      double score = 0;

    // 1. Preferred Service
          final bookings = (preferredServices[tech.service] ?? 0) as num;

          if (bookings > 0) {
            score += bookings * _serviceWeight;
          } else {
            score += _defaultServiceWeight;
          }

    // 2. Distance
          final distance = tech.distanceKm ?? 999;

          if (distance <= 2) {
            score += _distance2Km;
          } else if (distance <= 5) {
            score += _distance5Km;
          } else if (distance <= 10) {
            score += _distance10Km;
          } else if (distance <= 20) {
            score += _distance20Km;
          }

    // 3. Average Rating
          final rating =
              ((tech.avgPriceRating ?? 0) +
                  (tech.avgServiceRating ?? 0)) /
                  2;

          score += rating * _ratingWeight;

    // 4. Completed Jobs
          score += (tech.completedJobs ?? 0) * _completedJobsWeight;

    // 5. Verification
          if (tech.isVerified) {
            score += _verifiedBonus;
          }

    // 6. Experience
          score += tech.yearsOfExperience * _experienceWeight;

      recommendations.add(
        tech.copyWith(
          recommendationScore: score,
        ),
      );
    }

    // Highest score first
    recommendations.sort(
          (a, b) => b.recommendationScore.compareTo(
        a.recommendationScore,
      ),
    );

    final result = recommendations.length > limit
        ? recommendations.take(limit).toList()
        : recommendations;

    return await attachRouteInfo(
      technicians: result,
      userLat: userLat,
      userLng: userLng,
    );
  }


  Future<List<TechnicianModel>> attachRouteInfo({
    required List<TechnicianModel> technicians,
    required double userLat,
    required double userLng,
  }) async {
    final List<TechnicianModel> result = [];

    for (final tech in technicians) {
      if (tech.lat == null || tech.lng == null) {
        result.add(tech);
        continue;
      }

      final route =
      await GoogleMapsService.getDistanceAndEta(
        originLat: userLat,
        originLng: userLng,
        destinationLat: tech.lat!,
        destinationLng: tech.lng!,
      );

      if (route == null) {
        result.add(tech);
        continue;
      }

      result.add(
        tech.copyWith(
          distanceKm: route["distanceKm"],
          durationMinutes: route["durationMinutes"],
        ),
      );
    }

    return result;
  }

  Future<TechnicianSearchResult> searchTechnicians({
    required String service,
    required double userLat,
    required double userLng,
    List<String> selectedSkills = const [],
  }) async {

    Query query = _db
        .collection('technicians')
        .where('isOnline', isEqualTo: true)
        .where('isVerified', isEqualTo: true)
        .where('isSuspended', isEqualTo: false)
        .where('service', isEqualTo: service);

    if (selectedSkills.isNotEmpty) {
      query = query.where(
        'skills',
        arrayContainsAny: selectedSkills,
      );
    }

    final snapshot = await query.get();

    final technicians = <TechnicianModel>[];

    for (final doc in snapshot.docs) {
      final tech = TechnicianModel.fromMap(
        doc.data() as Map<String, dynamic>,
      );

      if (tech.lat == null || tech.lng == null) {
        continue;
      }

      final distance = LocationService.calculateDistance(
        userLat,
        userLng,
        tech.lat!,
        tech.lng!,
      );

      technicians.add(
        tech.copyWith(
          distanceKm: distance,
        ),
      );
    }

    technicians.sort(
          (a, b) => (a.distanceKm ?? 999999)
          .compareTo(b.distanceKm ?? 999999),
    );

    double radius = 20;
    List<TechnicianModel> nearby = [];

    while (nearby.isEmpty && radius <= 100) {
      nearby = technicians.where((tech) {
        return (tech.distanceKm ?? 999999) <= radius;
      }).toList();

      if (nearby.isEmpty) {
        if (radius == 20) {
          radius = 40;
        } else if (radius == 40) {
          radius = 75;
        } else if (radius == 75) {
          radius = 100;
        } else {
          break;
        }
      }
    }

    final withRoute = await attachRouteInfo(
      technicians: nearby,
      userLat: userLat,
      userLng: userLng,
    );

    return TechnicianSearchResult(
      technicians: withRoute,
      radiusUsed: radius,
    );
  }

}