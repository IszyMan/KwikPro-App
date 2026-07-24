import 'package:kwikpro/models/technician_model.dart';

class TechnicianSearchResult {
  final List<TechnicianModel> technicians;
  final double radiusUsed;

  const TechnicianSearchResult({
    required this.technicians,
    required this.radiusUsed,
  });
}