import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/technician_signup_controller.dart';
import '../../../widgets/app_primary_button.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/onboarding_header.dart';


class Step2WorkDetails extends ConsumerStatefulWidget {
  const Step2WorkDetails({super.key});

  @override
  ConsumerState<Step2WorkDetails> createState() =>
      _Step2WorkDetailsState();
}



class _Step2WorkDetailsState
    extends ConsumerState<Step2WorkDetails> {

  late TextEditingController yearsController;
  late TextEditingController addressController;



  @override
  void initState() {
    super.initState();

    final state =
    ref.read(technicianSignupController);


    yearsController =
        TextEditingController(
          text: state.years?.toString() ?? '',
        );


    addressController =
        TextEditingController(
          text: state.address ?? '',
        );
  }



  @override
  void dispose() {

    yearsController.dispose();

    addressController.dispose();

    super.dispose();

  }



  @override
  Widget build(BuildContext context) {


    final notifier =
    ref.read(
      technicianSignupController.notifier,
    );



    return Column(

      crossAxisAlignment:
      CrossAxisAlignment.start,


      mainAxisSize:
      MainAxisSize.min,


      children: [


        const OnboardingHeader(

          title: Text(
            "Work Details",
          ),

          subtitle:
          "Tell customers about your experience and where you operate.",

        ),



        const SizedBox(height:30),



        AppTextField(

          controller:
          yearsController,

          label:
          "Years of Experience",

          hint:
          "e.g. 5",

          icon:
          Icons.work_outline,

          keyboardType:
          TextInputType.number,

        ),



        const SizedBox(height:22),



        AppTextField(

          controller:
          addressController,

          label:
          "Area of Operation",

          hint:
          "e.g. Lekki, Ajah",

          icon:
          Icons.location_on_outlined,

        ),



        const SizedBox(height:40),



        AppPrimaryButton(

          text:
          "Continue",


          onPressed: () {


            final years =
                int.tryParse(
                  yearsController.text,
                ) ?? 0;



            notifier.setWorkDetails(

              years,

              addressController.text.trim(),

            );


            notifier.nextStep();


          },

        ),



        const SizedBox(height:20),


      ],

    );

  }

}