import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TechnicianDetailsScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const TechnicianDetailsScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<TechnicianDetailsScreen> createState() => _TechnicianDetailsScreenState();
}

class _TechnicianDetailsScreenState extends State<TechnicianDetailsScreen> {
  late bool isVerified;
  late bool isSuspended;

  @override
  void initState() {
    super.initState();
    isVerified = widget.data['isVerified'] ?? false;
    isSuspended = widget.data['isSuspended'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] ?? 'No name';
    final experience = widget.data['yearsOfExperience'] ?? 0;
    final location = widget.data['location'] ?? 'No Location';
    final profilePic = widget.data['profilePic'] ?? '';
    final workToolsImage = widget.data['workToolsImage'] ?? '';
    final previousWorkImage = widget.data['previousWorkImage'] ?? '';
    final workCertificate = widget.data['workCertificate'] ?? '';
    final nin = widget.data['ninImage'] ?? '';
    final service = widget.data['service'] ?? 'No Service';

    final hasWorkTools = workToolsImage.isNotEmpty;
    final hasPreviousWorkImage = previousWorkImage.isNotEmpty;
    final hasProfilePic = profilePic.isNotEmpty;
    final hasNin = nin.isNotEmpty;
    final hasCertificate = workCertificate.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text('$name Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              backgroundImage: hasProfilePic ? NetworkImage(profilePic) : null,
              child: !hasProfilePic
                  ? Text(name[0].toUpperCase(),
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold))
                  : null,
            ),
            SizedBox(height: 16),
            Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('$service • $experience years experience',
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            SizedBox(height: 4),
            Text(location, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  label: Text(isVerified ? "Verified" : "Not Verified"),
                  backgroundColor: isVerified ? Colors.green[100] : Colors.yellow[100],
                  avatar: Icon(Icons.verified, color: isVerified ? Colors.green : Colors.yellow),
                ),
                SizedBox(width: 10),
                Chip(
                  label: Text(isSuspended ? "Suspended" : "Active"),
                  backgroundColor: isSuspended ? Colors.red[100] : Colors.green[100],
                  avatar:
                  Icon(isSuspended ? Icons.block : Icons.check_circle, color: isSuspended ? Colors.red : Colors.green),
                ),
              ],
            ),
            SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDocumentItem('Profile', hasProfilePic, profilePic),
                        _buildDocumentItem('Working Tools', hasWorkTools, workToolsImage),
                        _buildDocumentItem('Previous Work', hasPreviousWorkImage, previousWorkImage),
                        _buildDocumentItem('NiN', hasNin, nin),
                        _buildDocumentItem('Certificate', hasCertificate, workCertificate),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isVerified = !isVerified; // instant change in UI
                    });
                    FirebaseFirestore.instance
                        .collection('technicians')
                        .doc(widget.docId)
                        .update({'isVerified': isVerified});
                  },
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  child: Text(isVerified ? 'Unverify' : 'Verify'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isSuspended = !isSuspended; // instant change in UI
                    });
                    FirebaseFirestore.instance
                        .collection('technicians')
                        .doc(widget.docId)
                        .update({'isSuspended': isSuspended});
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  child: Text(isSuspended ? 'Unsuspend' : 'Suspend'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(String label, bool exists, String imageUrl) {
    return Column(
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            image: exists ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
          ),
          child: !exists
              ? Center(
              child: Text(
                'No\n$label',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ))
              : null,
        ),
        SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 14)),
      ],
    );
  }
}