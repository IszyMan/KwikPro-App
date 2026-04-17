import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      // Only request location on mobile (not web)
      if (!kIsWeb) {
        // Check permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          // User denied permission — return null safely
          return null;
        }

        // Get current position
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
        // Get address info
        List<Placemark> placemarks = [];
        try {
          placemarks = await placemarkFromCoordinates(
              position.latitude, position.longitude);
        } catch (e) {
          print("Placemark lookup failed: $e");
        }

        String address = "Unknown";
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = place.subLocality ?? place.locality ?? "Unknown";
          //address = "${place.locality ?? ''}, ${place.administrativeArea ?? ''}";

        }

        return {
          'lat': position.latitude,
          'lng': position.longitude,
          'address': address,
        };
      } else {
        // Web: Cannot get GPS, return null safely
        return null;
      }
    } catch (e) {
      print("LocationService error: $e");
      return null;
    }
  }
}