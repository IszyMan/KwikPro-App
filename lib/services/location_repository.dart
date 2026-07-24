import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_model.dart';
import 'google_maps_service.dart';
import 'location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationRepository {
  const LocationRepository();

  Future<LocationModel?> getCurrentLocation() async {
    try {
      final Position? position =
      await LocationService.getCurrentPosition();

      if (position == null) {
        return null;
      }

      final address =
      await GoogleMapsService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      return LocationModel(
        lat: position.latitude,
        lng: position.longitude,
        address: address,
      );
    } catch (e) {
      debugPrint(
        "LocationRepository Error: $e",
      );
      return null;
    }
  }


  //Private helper function for technician and user collection
  Future<void> _updateLocation({
    required String collection,
    required LocationModel location,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection(collection)
        .doc(uid)
        .update({
      'lat': location.lat,
      'lng': location.lng,
      'location': location.address,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserLocation(
      LocationModel location,
      ) async {
    await _updateLocation(
      collection: 'users',
      location: location,
    );
  }

  Future<void> updateTechnicianLocation(
      LocationModel location,
      ) async {
    await _updateLocation(
      collection: 'technicians',
      location: location,
    );
  }


  Future<Map<String, dynamic>?> getDistanceAndEta({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) {
    return GoogleMapsService.getDistanceAndEta(
      originLat: originLat,
      originLng: originLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
    );
  }



}