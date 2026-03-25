import 'package:flutter/material.dart';
import 'package:kwikpro/models/technician_model.dart';


class TechnicianCard extends StatelessWidget {
  final TechnicianModel technician;

  const TechnicianCard({super.key, required this.technician});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundImage: (technician.profilePic != null &&
                  technician.profilePic!.isNotEmpty)
                  ? NetworkImage(technician.profilePic!)
                  : null,
              child: (technician.profilePic == null ||
                  technician.profilePic!.isEmpty)
                  ? Icon(Icons.person)
                  : null,
            ),

            SizedBox(width: 15),

            // Technician Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    technician.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(technician.service),
                  SizedBox(height: 4),
                  Text(
                    technician.address,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Stats Section
            Row(
              children: [
                Column(
                  children: [
                    Text(
                      "0",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Jobs",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),

                SizedBox(width: 15), // ✅ spacing between stats

                Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.orange, size: 16),
                        SizedBox(width: 3),
                        Text(
                          "4.5",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Rating",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),

    );
  }
}