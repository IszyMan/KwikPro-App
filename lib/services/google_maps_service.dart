import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GoogleMapsService {
  static const String _apiKey =
  String.fromEnvironment("GOOGLE_MAPS_API_KEY");

  static Future<String> reverseGeocode(
      double lat,
      double lng,
      ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
            '?latlng=$lat,$lng'
            '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        return "Unknown location";
      }

      final data = jsonDecode(response.body);

      if (data["status"] != "OK") {
        debugPrint(data.toString());
        return "Unknown location";
      }

      final results = data["results"] as List;

      if (results.isEmpty) {
        return "Unknown location";
      }

      return results.first["formatted_address"];
    } catch (e) {
      debugPrint("Google Geocoding Error: $e");
      return "Unknown location";
    }
  }
}