import 'package:kwikpro/models/technician_model.dart';

class JobHistoryItem {
  final TechnicianModel technician;
  final Map<String, dynamic> request;

  final double? distanceKm;
  final int? etaMinutes;

  JobHistoryItem({
    required this.technician,
    required this.request,
    this.distanceKm,
    this.etaMinutes,
  });
}