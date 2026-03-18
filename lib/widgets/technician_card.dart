import 'package:flutter/material.dart';
import 'package:kwikpro/models/technician_model.dart';


class TechnicianCard extends StatelessWidget {
  final TechnicianModel technician;

  const TechnicianCard({super.key, required this.technician});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 15),
      child: Padding(padding: EdgeInsets.all(15),
        child: Row(
          children: [
            //avatar
            CircleAvatar(
              radius: 25,
              child: Icon(Icons.person),
            ),
            SizedBox(width: 15,),
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technician.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),

                    ),
                    SizedBox(height: 5,),
                    Text(technician.service),
                    SizedBox(height: 5,),
                    Text(technician.address, style: TextStyle(color: Colors.grey),)

                  ],
                )),
            Column(
              children: [
                Icon(Icons.star, color: Colors.orange,),
                Text(technician.rating.toString()),
              ],
            )

          ],),
      ),

    );
  }
}