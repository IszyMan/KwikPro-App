import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';


class LocationService {

  Future<Map<String, dynamic>> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);

    final place = placemarks.first;

    String address = "${place.locality}, ${place.administrativeArea}";

    return {
      'lat': position.latitude,
      'long': position.longitude,
      'address': address,

    };
  }
}