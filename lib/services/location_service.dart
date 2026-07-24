import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Returns the current GPS position only.
  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint("Location service disabled");
        return null;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint("Location permission denied");
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint(
        "GPS: ${position.latitude}, ${position.longitude}",
      );

      return position;
    } catch (e) {
      debugPrint("LocationService Error: $e");
      return null;
    }
  }




  /// Distance in KM
  static double calculateDistance(
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      ) {
    const earthRadius = 6371;

    final dLat = _degToRad(endLat - startLat);
    final dLng = _degToRad(endLng - startLng);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
            cos(_degToRad(startLat)) *
                cos(_degToRad(endLat)) *
                sin(dLng / 2) *
                sin(dLng / 2);

    final c = 2 * atan2(
      sqrt(a),
      sqrt(1 - a),
    );

    return earthRadius * c;
  }

  static double _degToRad(double deg) {
    return deg * pi / 180;
  }
}