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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final notifier =
            ref.read(technicianSignupController.notifier);

            if (state.step > 0) {
              notifier.back();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text("Enter work Details"),
      ),
      body: Padding(padding: EdgeInsetsGeometry.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      )
      ),
    );

  }
}