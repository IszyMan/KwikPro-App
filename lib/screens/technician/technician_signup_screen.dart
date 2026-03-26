import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:kwikpro/providers/auth_provider.dart';
import 'package:kwikpro/screens/technician/technician_home_screen.dart';
import 'package:kwikpro/services/location_service.dart';



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
    "Generator Repairer",
    "Electrician",
    "Painter",
    "Fridge Repairer",
  ];

  String selectedService = "AC Repairer";

  final addressController = TextEditingController();

  final profileUrlController = TextEditingController();
  final certUrlController     = TextEditingController();
  final ninUrlController      = TextEditingController();


  bool isLoading = false;
  final picker = ImagePicker();



// Get location
Future<Map<String, dynamic>?> getLocation() async {
  final locationService = LocationService();
  return await locationService.getCurrentLocation();
}

//Save Technicians
Future<void> _saveTechnician() async {
  setState(() => isLoading = true);

  final auth = ref.read(authProvider);
  final firestore = ref.read(firestoreServiceProvider);
  //final storage = StorageService();

  Map<String, dynamic>? location;

  try {
    location = await getLocation();
  } catch (e){
     print("Location failed $e");
  }


  //Upload image if selected
    String? profileUrl = profileUrlController.text.trim().isNotEmpty ? profileUrlController.text.trim() : null;
    String? certUrl    = certUrlController.text.trim().isNotEmpty ? certUrlController.text.trim() : null;
    String? ninUrl     = ninUrlController.text.trim();

    if (ninUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("NIN / ID URL is required!")),
      );
      setState(() => isLoading = false);
      return;
    }

  final tech = TechnicianModel(
      uid: auth.user!.uid,
      name: nameController.text.trim(),
      service: selectedService,
      address: addressController.text.trim(),
      lat: location?['lat'],
      long: location?['lng'],
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
          SizedBox(height: 20,),
       TextField(
         controller: addressController,
         decoration: InputDecoration(labelText: "Your area (e.g Ajah, Lekki)"),
       ),

       SizedBox(height: 20),
        // Profile (optional)
       TextField(
            controller: profileUrlController,
            decoration: const InputDecoration(
              labelText: "Profile Picture URL (optional)",
              hintText: "https://example.com/profile.jpg",
            ),
          ),
       SizedBox(height: 20),

          // Certificate (optional)
       TextField(
            controller: certUrlController,
            decoration: const InputDecoration(
              labelText: "Work Certificate URL (optional)",
              hintText: "https://example.com/cert.jpg",
            ),
          ),
       SizedBox(height: 20),

          // NIN (required)
       TextField(
            controller: ninUrlController,
            decoration: const InputDecoration(
              labelText: "NIN / ID URL (required)",
              hintText: "Paste public image link here",
            ),
          ),
      SizedBox(height: 20),

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