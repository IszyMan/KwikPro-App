import 'package:flutter/material.dart';
import 'package:kwikpro/models/technician_model.dart';

class ActiveJobScreen extends StatelessWidget {
  final TechnicianModel technician;

  const ActiveJobScreen({super.key, required this.technician});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Active Job")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: technician.profilePic != null
                  ? NetworkImage(technician.profilePic!)
                  : null,
            ),
            SizedBox(height: 15),

            Text(technician.name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            Text(technician.service),

            SizedBox(height: 20),

            ListTile(
              leading: Icon(Icons.phone),
              title: Text("Call Technician"),
              onTap: () {
                // later: launch phone call
              },
            ),

            ListTile(
              leading: Icon(Icons.map),
              title: Text("View on Map"),
              onTap: () {
                // later: open map
              },
            ),
          ],
        ),
      ),
    );
  }
}