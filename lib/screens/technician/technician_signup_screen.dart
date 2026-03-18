import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:kwikpro/providers/auth_provider.dart';
import 'package:kwikpro/screens/technician/technician_home_screen.dart';
import 'package:kwikpro/services/location_service.dart';
import 'package:kwikpro/services/storage_service.dart';



class TechnicianSignupScreen extends ConsumerStatefulWidget{
  const TechnicianSignupScreen({super.key});

  @override
  ConsumerState<TechnicianSignupScreen> createState() => _TechnicianSignupScreenState();
}

class _TechnicianSignupScreenState extends ConsumerState<TechnicianSignupScreen>{

  final nameController = TextEditingController();

  final services = [
    "AC Repairer",
    "Plumber",
    "Fridge Repairer",
    "Electrician",
  ];

  String selectedService = "AC Repairer";

  File? profilePic;
  File? workCertificate;
  File? ninImage;

  bool isLoading = false;

  final picker = ImagePicker();

  //pick image
Future<File?> pickImage() async{
  final picked = await picker.pickImage(source: ImageSource.gallery);
  if (picked != null) return File(picked.path);
  return null;
}

// Get location
Future<Map<String, dynamic>> getLocation() async {
  final locationService = LocationService();
  return await locationService.getCurrentLocation();
}

//Save Technicians
Future<void> _saveTechnician() async {
  setState(() => isLoading = true);

  final auth = ref.read(authProvider);
  final firestore = ref.read(firestoreServiceProvider);
  final storage = StorageService();
  final location = await getLocation();

  String? profileUrl;
  String? certUrl;
  String? ninUrl;

  //Upload image if selected
  if (profilePic != null) {
    profileUrl = await storage.uploadFile(
        file: profilePic!,
        path: "technicians/${auth.user!.uid}/profile.jpg",);
  }

  if (workCertificate != null) {
    certUrl = await storage.uploadFile(
        file: workCertificate!,
        path: "technicians/${auth.user!.uid}/certificate.jpg");
  }

  if (ninImage != null) {
    ninUrl = await storage.uploadFile(
        file: ninImage!,
        path: "technicians/${auth.user!.uid}/nin.jpg",);
  }

  final tech = TechnicianModel(
      uid: auth.user!.uid,
      name: nameController.text.trim(),
      service: selectedService,
      address: location['address'],
      lat: location['lat'],
      long: location['long'],
      profilePic: profileUrl,
      workCertificate: certUrl,
      ninImage: ninUrl,
  );

  await firestore.saveTechnician(tech);
  ref.read(authProvider.notifier).setUser(tech);

  setState(() => isLoading = false);
  Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => TechnicianHomeScreen(),),
      (route) => false
  );

}
@override
 Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title:  Text("Technician Signup"),),
    body: SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller:  nameController,
            decoration: InputDecoration(labelText: "Full Name"),
          ),
          SizedBox(height: 10,),

          DropdownButtonFormField(
              value: selectedService,
              items: services.map((s) {
                return DropdownMenuItem(
                  value: s,
                    child: Text(s));
              }).toList(),
              onChanged: (val) {
                if (val != null) selectedService = val;
              },
            decoration: const InputDecoration(labelText: "Service"),
          ),
          SizedBox(height: 10,),

      // Profile Image
      ElevatedButton(
        onPressed: () async {
          profilePic = await pickImage();
          setState(() {});
        },
        child: const Text("Upload Profile Picture (Optional)"),
      ),

      // Certificate
      ElevatedButton(
        onPressed: () async {
          workCertificate = await pickImage();
          setState(() {});
        },
        child: const Text("Upload Work Certificate (Optional)"),
      ),

      // NIN Image
      ElevatedButton(
        onPressed: () async {
          ninImage = await pickImage();
          setState(() {});
        },
        child: const Text("Upload NIN / ID (Required)"),
      ),

      const SizedBox(height: 20),

      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isLoading ? null : _saveTechnician,
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Submit"),
        ),),
        ],
      ),

    ),
  );
}

}