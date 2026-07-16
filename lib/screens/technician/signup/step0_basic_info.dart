import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/technician_signup_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_primary_button.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/onboarding_header.dart';

class Step0BasicInfo extends ConsumerStatefulWidget {
  const Step0BasicInfo({super.key});

  @override
  ConsumerState<Step0BasicInfo> createState() =>
      _Step0BasicInfoState();
}

class _Step0BasicInfoState
    extends ConsumerState<Step0BasicInfo> {
  late TextEditingController nameController;

  final services = const [
    "Car Mechanic",
    "AC Repairer",
    "Plumber",
    "Generator Repairer",
    "Electrician",
    "Painter",
    "Fridge Repairer",
  ];

  static final Map<String, List<String>> serviceSkills = {
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
      "Freezer Repair",
      "Gas Filling",
      "Refrigerator Repair",
    ],
    "Painter": [
      "Interior Painting",
      "Exterior Painting",
      "Wall Screeding",
      "Wallpaper Installation",
    ],
  };

  @override
  void initState() {
    super.initState();

    final state = ref.read(technicianSignupController);
    nameController =
        TextEditingController(text: state.name ?? '');
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const OnboardingHeader(
            title: Text("Tell Us About Yourself"),
            subtitle:
            "Choose your profession and the skills you specialize in.",
          ),

          const SizedBox(height: 30),

          AppTextField(
            controller: nameController,
            label: "Full Name",
            hint: "John Doe",
            icon: Icons.person_outline,
            onChanged: (value) {
              ref
                  .read(technicianSignupController.notifier)
                  .setName(value);
            },
          ),

          const SizedBox(height: 22),

          const Text(
            "Service Category",
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedService,
                isExpanded: true,
                hint: const Text("Select your service"),
                items: services
                    .map(
                      (service) => DropdownMenuItem(
                    value: service,
                    child: Text(service),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(
                      technicianSignupController
                          .notifier,
                    )
                        .setService(value);
                  }
                },
              ),
            ),
          ),

          if ((state.service ?? '').isNotEmpty &&
              serviceSkills.containsKey(state.service)) ...[
            const SizedBox(height: 28),

            const Text(
              "Skills",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
              serviceSkills[state.service]!.map((skill) {
                final selected =
                state.skills.contains(skill);

                return FilterChip(
                  label: Text(skill),
                  selected: selected,
                  selectedColor:
                  AppColors.primary.withOpacity(.15),
                  checkmarkColor:
                  AppColors.primary,
                  onSelected: (value) {
                    final updated =
                    [...state.skills];

                    if (value) {
                      updated.add(skill);
                    } else {
                      updated.remove(skill);
                    }

                    ref
                        .read(
                      technicianSignupController
                          .notifier,
                    )
                        .setSkills(updated);
                  },
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 40),

          AppPrimaryButton(
            text: "Continue",
            onPressed: () {
              final notifier = ref.read(
                technicianSignupController.notifier,
              );

              notifier.setName(
                nameController.text.trim(),
              );

              notifier.setService(selectedService);

              notifier.nextStep();
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}