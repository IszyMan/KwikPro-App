import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/technician_signup_controller.dart';

class Step2WorkDetails extends ConsumerWidget {
  const Step2WorkDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(technicianSignupController);

    final yearsController =
    TextEditingController(text: state.years?.toString() ?? '');
    final addressController = TextEditingController(text: state.address ?? '');

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

        // Years of experience
        TextField(
          controller: yearsController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Years of Experience",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),

        // Address
        TextField(
          controller: addressController,
          decoration: InputDecoration(
            labelText: "Area of Operation (e.g., Lekki, Ajah)",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),

        // Next button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final years = int.tryParse(yearsController.text) ?? 0;
              ref
                  .read(technicianSignupController.notifier)
                  .setWorkDetails(years, addressController.text);
              ref.read(technicianSignupController.notifier).nextStep();
            },
            child: Text("Next"),
          ),
        ),
      ],
    );
  }
}