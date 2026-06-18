import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final address = await reverseGeocode(
        position.latitude,
        position.longitude,
      );

      return {
        "lat": position.latitude,
        "lng": position.longitude,
        "address": address,
      };
    } catch (e) {
      debugPrint("LocationService Error: $e");
      return null;
    }
  }

  static Future<String> reverseGeocode(
      double lat,
      double lng,
      ) async {
    try {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse"
            "?format=json"
            "&lat=$lat"
            "&lon=$lng"
            "&zoom=18"
            "&addressdetails=1",
      );

      final response = await http.get(
        url,
        headers: {
          "User-Agent":
          "KwikProApp/1.0",
        },
      );

      if (response.statusCode != 200) {
        return "Unknown location";
      }

      final data =
      json.decode(response.body);

      final address =
      data["address"];

      String pick(
          List<String?> values,
          ) {
        for (final v in values) {
          if (v != null &&
              v.trim().isNotEmpty) {
            return v;
          }
        }
        return "";
      }

      final area = pick([
        address?["neighbourhood"],
        address?["suburb"],
        address?["quarter"],
        address?["residential"],
        address?["hamlet"],
      ]);

      final district = pick([
        address?["city_district"],
        address?["state_district"],
        address?["county"],
      ]);

      final city = pick([
        address?["city"],
        address?["town"],
        address?["village"],
      ]);

      final state =
      address?["state"];

      final parts = [
        area,
        district,
        city,
        state,
      ]
          .where(
            (e) =>
        e != null &&
            e.toString().trim().isNotEmpty,
      )
          .toList();

      return parts.isNotEmpty
          ? parts.join(", ")
          : "Unknown location";
    } catch (e) {
      debugPrint(
        "Reverse Geocode Error: $e",
      );
      return "Unknown location";
    }
  }
}