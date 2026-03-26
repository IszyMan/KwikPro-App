import 'package:firebase_auth/firebase_auth.dart';
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
  String _imageUrl = '';
  bool _loading = false;
  bool _isSearching = false;
  bool _hasSearched = false;

  double? userLat;
  double? userLng;

  Map<String, dynamic>? currentRequest;

  final List<String> services = [
    "AC Repairer",
    "Plumber",
    "Generator Repairer",
    "Electrician",
    "Painter",
    "Fridge Repairer",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Find Nearby Technician')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Form for search input
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Service',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedService,
                    items: services
                        .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedService = val),
                    validator: (val) =>
                    val == null ? 'Please select a service' : null,
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Describe your issue',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (val) => _issueDescription = val,
                    validator: (val) => val == null || val.isEmpty
                        ? 'Describe your issue'
                        : null,
                  ),
                  SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Image URL (optional)',
                            hintText: 'https://example.com/image.jpg',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _imageUrl = val.trim();
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 4),
                      if (_imageUrl.isNotEmpty)
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _searchTechnicians,
                    child: _loading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Search'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Show results or searching state
            Expanded(
              child: !_hasSearched
                  ? SizedBox() // Nothing shows before search
                  : _isSearching
                  ? Center(
                child: Text(
                  'Searching for available ${_selectedService ?? "technicians"}...',
                ),
              )
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('technicians')
                    .where('isOnline', isEqualTo: true)
                    .where('service', isEqualTo: _selectedService)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  final nearby = docs
                      .map((d) => TechnicianModel.fromMap(
                      d.data() as Map<String, dynamic>))
                      .where((tech) {
                    if (tech.lat == null || tech.long == null) return false;
                    if (userLat == null || userLng == null) return false;
                    final dist = Geolocator.distanceBetween(
                        userLat!, userLng!, tech.lat!, tech.long!);
                    return dist / 1000 <= 10;
                  }).toList();

                  if (nearby.isEmpty) {
                    return Center(
                        child: Text(
                            "No nearby technicians found for this service"));
                  }

                  return ListView.builder(
                    itemCount: nearby.length,
                    itemBuilder: (context, index) {
                      return TechnicianCard(
                        technician: nearby[index],
                        userLat: userLat,
                        userLng: userLng,
                        issueDescription: _issueDescription,
                        imageUrl: _imageUrl,
                      );
                    },
                  );
                },
              ),
            ),

            // User request status
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox(); // No request yet
                }

                final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

                // Save current request to state
                currentRequest = data;

                // Only show if status is pending, accepted, rejected, or cancelled
                String status = data['status'] ?? '';
                Color bg = Colors.blue;
                String msg = '';

                switch (status) {
                  case 'pending':
                    bg = Colors.blue;
                    msg = "Waiting for technician...";
                    break;
                  case 'accepted':
                    bg = Colors.green;
                    msg = "Technician accepted your request";
                    break;
                  case 'rejected':
                    bg = Colors.red;
                    msg = "Technician rejected your request";
                    break;
                  case 'cancelled':
                    bg = Colors.orange;
                    msg = "Request timed out. Choose another technician.";
                    break;
                  default:
                    return const SizedBox(); // Don't show unknown statuses
                }

                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(10),
                  color: bg,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          msg,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      if (status == 'accepted')
                        Icon(Icons.check_circle, color: Colors.white)
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Search technicians and get user location
  Future<void> _searchTechnicians() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.high));

      setState(() {
        userLat = pos.latitude;
        userLng = pos.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to get location")));
    } finally {
      setState(() {
        _loading = false;
        _isSearching = false;
      });
    }
  }
}