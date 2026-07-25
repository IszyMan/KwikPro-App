import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:kwikpro/models/job_history_item.dart';

class CompletedJobCard extends StatelessWidget {

  final JobHistoryItem item;
  final VoidCallback onReview;
  final VoidCallback onBookAgain;

  const CompletedJobCard({
    super.key,
    required this.item,
    required this.onReview,
    required this.onBookAgain,
  });

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "";

    return DateFormat(
      "dd MMM yyyy • hh:mm a",
    ).format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.request["imageUrl"] ?? "";
    final description = item.request["description"] ?? "";
    final location =
        (item.request["jobLocation"]?["address"] as String?)?.trim() ?? "";
    final service = item.request["service"] ?? "";
    final createdAt = item.request["createdAt"];

    final technician = item.technician;
    final profilePic = technician.profilePic ?? "";

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          /// Technician
          Row(
            children: [

              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                profilePic.isNotEmpty
                    ? NetworkImage(profilePic)
                    : null,
                child: profilePic.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    Text(
                      item.technician.name,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      service,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green
                      .withOpacity(.12),
                  borderRadius:
                  BorderRadius.circular(30),
                ),
                child: const Text(
                  "Completed",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight:
                    FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [

              const Icon(
                Icons.location_on_outlined,
                color: Colors.red,
                size: 18,
              ),

              const SizedBox(width: 5),

              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                    Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [

              const Icon(
                Icons.schedule,
                size: 18,
                color: Colors.blueGrey,
              ),

              const SizedBox(width: 5),

              Text(
                formatDate(createdAt),
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),

          if (imageUrl.toString().isNotEmpty) ...[
            const SizedBox(height: 14),

            ClipRRect(
              borderRadius:
              BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],

          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),

            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade800,
              ),
            ),
          ],

          const SizedBox(height: 18),

          Row(
            children: [

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReview,
                  icon: const Icon(
                    Icons.star_outline,
                  ),
                  label: const Text(
                    "Review",
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onBookAgain,
                  icon: const Icon(
                    Icons.refresh,
                  ),
                  label: const Text(
                    "Book Again",
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}