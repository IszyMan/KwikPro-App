import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/technician_signup_controller.dart';

class Step0BasicInfo extends ConsumerWidget {
  const Step0BasicInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(technicianSignupController);
    final nameController = TextEditingController(text: state.name);
    final services = [
      "AC Repairer",
      "Plumber",
      "Generator Repairer",
      "Electrician",
      "Painter",
      "Fridge Repairer",
    ];

    String selectedService = "AC Repairer";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Bar
        LinearProgressIndicator(
          value: state.step / 5,
          minHeight: 6,
          color: Colors.green,
          backgroundColor: Colors.grey.shade300,
        ),
        SizedBox(height: 20),

        // Name
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: "Full Name",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),

        // Service dropdown
        DropdownButtonFormField<String>(
          value: selectedService,
          items: services
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) {
            if (val != null) selectedService = val;
          },
          decoration: InputDecoration(
            labelText: "Select Service",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),

        // Continue button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ref
                  .read(technicianSignupController.notifier)
                  .setBasicInfo(nameController.text, selectedService);
              ref.read(technicianSignupController.notifier).nextStep();
            },
            child: Text("Continue"),
          ),
        ),
      ],
    );
  }
}