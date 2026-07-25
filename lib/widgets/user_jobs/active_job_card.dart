import 'package:flutter/material.dart';
import 'package:kwikpro/models/job_history_item.dart';

import '../../core/utils/distance_helper.dart';

class ActiveJobCard extends StatelessWidget {
  final JobHistoryItem item;
  final VoidCallback onMessage;
  final VoidCallback onCall;

  const ActiveJobCard({
    super.key,
    required this.item,
    required this.onMessage,
    required this.onCall,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "accepted":
      case "appointmentaccepted":
        return Colors.blue;
      case "ontheway":
        return Colors.deepOrange;
      case "arrived":
        return Colors.purple;
      case "inprogress":
        return Colors.green;
      case "completionrequested":
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case "appointmentAccepted":
        return "Appointment Accepted";
      case "onTheWay":
        return "On The Way";
      case "inProgress":
        return "In Progress";
      case "completionRequested":
        return "Completion Requested";
      default:
        if (status.isEmpty) return "Unknown";
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final technician = item.technician;
    final request = item.request;

    final photo = technician.profilePic ?? "";
    final status = request["status"] ?? "";


    final eta = item.etaMinutes != null
        ? DistanceHelper.formatEta(item.etaMinutes!)
        : "Calculating...";

    final distance = item.distanceKm != null
        ? DistanceHelper.formatDistance(item.distanceKm!)
        : "";


    // Support both old and new request structures.
    final location = (request["jobLocation"]?["address"] as String?)?.trim() ??
            "Unknown Location";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Technician
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  technician.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (technician.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: Colors.green,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      technician.service,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Service Location",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),


          const SizedBox(height: 14),

          if (distance.isNotEmpty) ...[
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.directions_car,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 6),
                Text(
                  distance,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],


          const SizedBox(height: 14),

          /// ETA + Status
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "ETA",
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eta,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Status",
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatStatus(status),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onMessage,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Message"),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call),
                  label: const Text("Call"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}