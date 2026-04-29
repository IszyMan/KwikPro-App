import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/technician_signup_controller.dart';

class Step0BasicInfo extends ConsumerStatefulWidget {
  const Step0BasicInfo({super.key});

  @override
  ConsumerState<Step0BasicInfo> createState() => _Step0BasicInfoState();
}

class _Step0BasicInfoState extends ConsumerState<Step0BasicInfo> {
  late TextEditingController nameController;

  final services = const [
    "Car Mechanic"
    "AC Repairer",
    "Plumber",
    "Generator Repairer",
    "Electrician",
    "Painter",
    "Fridge Repairer",
  ];

  static Map<String, List<String>> serviceSkills = {
    "Car Mechanic": [
      "Battery Services",
      "Car Rewire",
      "AC Repair",
      "Brake Service",
      "German Car",
      "American Car",
      "Japanese Car",

    ],

    "Electrician": [
      "Wiring",
      "Socket Fixing",
      "Lighting Installation",
    ],
    "AC Repairer": [
      "AC Gas Filling",
      "AC Repair",
      "AC Installation",
      "Compressor Repair",
    ],
    "Plumber": [
      "Leak Fixing",
      "Drain Cleaning",
      "Toilet Repair",
      "Water Treatment",
      "Pumping Machine",
    ],
    "Generator Repairer": [
      "Generator Servicing",
      "Engine Repair",
      "Oil Change",
      "Carburetor",
    ],
    "Fridge Repairer": [
      "Freezer Repair"
      "Gas Filling",
      "Refrigerator Repair",

    ],
    "Painter": [
      "Interior Painting",
      "Exterior Painting",
      "Wall Screeding",
      "Wallpaper installation",
    ]
  };

  @override
  void initState() {
    super.initState();

    final state = ref.read(technicianSignupController);
    nameController = TextEditingController(text: state.name);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(technicianSignupController);

    final selectedService =
    services.contains(state.service) ? state.service : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hi! Enter your name & Service type"),
      ),
      body: Padding(padding: EdgeInsetsGeometry.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Name
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref
                    .read(technicianSignupController.notifier)
                    .setName(value);
              },
            ),

            const SizedBox(height: 20),

            // Service dropdown
            DropdownButtonFormField<String>(
              value: selectedService,
              items: services
                  .map((s) => DropdownMenuItem(
                value: s,
                child: Text(s),
              ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  ref
                      .read(technicianSignupController.notifier)
                      .setService(val);
                }
              },
              decoration: const InputDecoration(
                labelText: "Select Service",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Skills
            if ((state.service ?? '').isNotEmpty &&
                serviceSkills.containsKey(state.service))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select your skills",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ...serviceSkills[state.service!]!.map((skill) {
                    final selectedSkills = state.skills;

                    return CheckboxListTile(
                      title: Text(skill),
                      value: selectedSkills.contains(skill),
                      onChanged: (value) {
                        final updatedSkills = [...selectedSkills];

                        if (value == true) {
                          if (!updatedSkills.contains(skill)) {
                            updatedSkills.add(skill);
                          }
                        } else {
                          updatedSkills.remove(skill);
                        }

                        ref
                            .read(technicianSignupController.notifier)
                            .setSkills(updatedSkills);
                      },
                    );
                  }).toList(),
                ],
              ),

            const SizedBox(height: 20),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final notifier =
                  ref.read(technicianSignupController.notifier);

                  notifier.setName(nameController.text);
                  notifier.setService(selectedService);

                  notifier.nextStep();
                },
                child: const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );

  }
}