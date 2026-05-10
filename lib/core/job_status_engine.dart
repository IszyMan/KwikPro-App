class JobStatus {
  static const String pending = "pending";
  static const String accepted = "accepted";
  static const String onTheWay = "on_the_way";
  static const String arrived = "arrived";
  static const String inProgress = "in_progress";
  static const String completionRequested = "completion_requested";
  static const String completed = "completed";
  static const String rejected = "rejected";

  /// next valid transitions ONLY
  static String nextStatus(String current, String action) {
    switch (current) {
      case pending:
        return action == "accept" ? accepted : rejected;

      case accepted:
        return action == "on_way" ? onTheWay : accepted;

      case onTheWay:
        return action == "arrived" ? arrived : onTheWay;

      case arrived:
        return action == "start" ? inProgress : arrived;

      case inProgress:
        return action == "request_complete" ? completionRequested : inProgress;

      case completionRequested:
        return action == "confirm" ? completed : completionRequested;

      default:
        return current;
    }
  }
}