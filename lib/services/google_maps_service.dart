import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GoogleMapsService {
  static const String _apiKey =
      "";

  static Future<String> reverseGeocode(
      double lat,
      double lng,
      ) async {
    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json"
            "?latlng=$lat,$lng"
            "&key=$_apiKey",
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        debugPrint("Google Geocoding HTTP Error: ${response.statusCode}");
        return "Unknown location";
      }

      final data = jsonDecode(response.body);

      //  Print the complete Google response
      //debugPrint(jsonEncode(data));

      if (data["status"] != "OK") {
        debugPrint("Google Geocoding Error: ${data["status"]}");
        debugPrint(data.toString());
        return "Unknown location";
      }

      final results = data["results"] as List;

      if (results.isEmpty) {
        return "Unknown location";
      }

      // Skip Plus Codes
      for (final result in results) {
        final address =
            result["formatted_address"] as String? ?? "";

        if (address.isNotEmpty && !address.contains("+")) {
          return address.replaceAll(", Nigeria", "");
        }
      }

      return "Unknown location";
    } catch (e, stackTrace) {
      debugPrint("Google Geocoding Exception: $e");
      debugPrint(stackTrace.toString());
      return "Unknown location";
    }
  }

  static Future<Map<String, dynamic>?> getDistanceAndEta({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    try {
      final url = Uri.parse(
        "https://routes.googleapis.com/directions/v2:computeRoutes",
      );

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": _apiKey,
          "X-Goog-FieldMask":
          "routes.distanceMeters,routes.duration",
        },
        body: jsonEncode({
          "origin": {
            "location": {
              "latLng": {
                "latitude": originLat,
                "longitude": originLng,
              }
            }
          },
          "destination": {
            "location": {
              "latLng": {
                "latitude": destinationLat,
                "longitude": destinationLng,
              }
            }
          },
          "travelMode": "DRIVE",
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(response.body);
        return null;
      }

      final data = jsonDecode(response.body);

      if (data["routes"] == null ||
          (data["routes"] as List).isEmpty) {
        return null;
      }

      final route = data["routes"][0];

      final distanceMeters = route["distanceMeters"] as int;

      final durationString = route["duration"] as String;

      final seconds =
      int.parse(durationString.replaceAll("s", ""));

      return {
        "distanceKm": distanceMeters / 1000,
        "durationMinutes": (seconds / 60).ceil(),
      };
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}