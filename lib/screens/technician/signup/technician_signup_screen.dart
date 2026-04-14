import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwikpro/screens/technician/signup/step0_basic_info.dart';
import 'package:kwikpro/screens/technician/signup/step1_profile_image.dart';
import 'package:kwikpro/screens/technician/signup/step2_work_details.dart';
import 'package:kwikpro/screens/technician/signup/step3_uploads.dart';
import 'package:kwikpro/screens/technician/signup/step4_verification.dart';
import '../../../providers/technician_signup_controller.dart';

class TechnicianSignupScreen extends ConsumerWidget {
  const TechnicianSignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(technicianSignupController);

    // Determine which step widget to show
    Widget currentStep;
    switch (state.step) {
      case 0:
        currentStep = const Step0BasicInfo();
        break;

      case 1:
        currentStep = const Step1ProfileImage();
        break;
      case 2:
        currentStep = const Step2WorkDetails();
        break;
      case 3:
        currentStep = const Step3Uploads();
        break;
      case 4:
        currentStep = const Step4Verification();
        break;
      default:
        currentStep = const Step0BasicInfo();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Step ${state.step + 1} of 5"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (state.step + 1) / 5,
            backgroundColor: Colors.grey[300],
            color: Colors.blue,
            minHeight: 4,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: currentStep,
      ),
    );
  }
}