import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:kwikpro/widgets/technician_card.dart';

class SearchTechnicianScreen extends StatefulWidget {
  const SearchTechnicianScreen({super.key});

  @override
  _SearchTechnicianScreenState createState() => _SearchTechnicianScreenState();
}

class _SearchTechnicianScreenState extends State<SearchTechnicianScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedService;
  String _issueDescription = '';
  bool _loading = false;

  List<TechnicianModel> nearbyTechnicians = [];

  final List<String> services = [
    'Electrician',
    'AC Technician',
    'Fridge Technician',
    'Plumber',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Find Nearby Technician')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Service type dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Service',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedService,
                    items: services
                        .map((service) => DropdownMenuItem(
                      value: service,
                      child: Text(service),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedService = val;
                      });
                    },
                    validator: (val) =>
                    val == null ? 'Please select a service' : null,
                  ),
                  SizedBox(height: 15),

                  // Issue description text field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Describe your issue',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (val) {
                      _issueDescription = val;
                    },
                    validator: (val) => val == null || val.isEmpty
                        ? 'Please describe your issue'
                        : null,
                  ),

                  SizedBox(height: 20),

                  // Search button
                  ElevatedButton(
                    onPressed: _loading ? null : _searchTechnicians,
                    child: _loading
                        ? CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : Text('Search'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Show results
            Expanded(
              child: nearbyTechnicians.isEmpty
                  ? Center(child: Text('No technicians found'))
                  : ListView.builder(
                itemCount: nearbyTechnicians.length,
                itemBuilder: (context, index) {
                  return TechnicianCard(
                      technician: nearbyTechnicians[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Function to search nearby technicians
  Future<void> _searchTechnicians() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      nearbyTechnicians.clear();
    });

    try {
      // Get user's current location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      double userLat = position.latitude;
      double userLng = position.longitude;

      //  Query Firestore for online technicians with selected service
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('technicians')
          .where('isOnline', isEqualTo: true)
          .where('service', isEqualTo: _selectedService)
          .get();

      List<TechnicianModel> allTechnicians = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TechnicianModel.fromMap(data);
      }).toList();

      //  Filter by distance (optional: 10 km radius)
      List<TechnicianModel> filtered = allTechnicians.where((tech) {
        if (tech.lat == null || tech.long == null) return false;

        double distanceInMeters = Geolocator.distanceBetween(
            userLat, userLng, tech.lat!, tech.long!);

        double distanceInKm = distanceInMeters / 1000;
        return distanceInKm <= 10; // within 10 km radius
      }).toList();

      setState(() {
        nearbyTechnicians = filtered;
      });
    } catch (e) {
      print('Error searching technicians: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching nearby technicians')));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}