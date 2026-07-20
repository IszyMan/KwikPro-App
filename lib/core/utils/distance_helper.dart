class DistanceHelper {
  static String formatEta(double distanceKm) {
    final minutes = ((distanceKm / 40) * 60).ceil();

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