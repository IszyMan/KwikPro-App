class DistanceHelper {

  static String formatDistance(double km) {
    return "${km.toStringAsFixed(1)} km";
  }

  static String formatEta(int minutes) {

    if (minutes < 60) {
      return "$minutes min away";
    }

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

    if (remaining == 0) {
      return "$hours hr away";
    }

    return "$hours hr ${remaining} min away";
  }
}