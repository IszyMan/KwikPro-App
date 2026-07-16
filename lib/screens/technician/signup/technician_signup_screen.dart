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


  String title(int step){

    switch(step){

      case 0:
        return "Basic Information";

      case 1:
        return "Profile Picture";

      case 2:
        return "Work Details";

      case 3:
        return "Verification Documents";

      case 4:
        return "Complete Registration";

      default:
        return "Technician Signup";
    }

  }



  String subtitle(int step){

    switch(step){

      case 0:
        return "Tell us about yourself";

      case 1:
        return "Add a professional photo";

      case 2:
        return "Tell customers about your skills";

      case 3:
        return "Upload required documents";

      case 4:
        return "Review and submit your profile";

      default:
        return "";

    }

  }



  Widget currentStep(int step){

    switch(step){

      case 0:
        return const Step0BasicInfo();

      case 1:
        return const Step1ProfileImage();

      case 2:
        return const Step2WorkDetails();

      case 3:
        return const Step3Uploads();

      case 4:
        return const Step4Verification();

      default:
        return const Step0BasicInfo();

    }

  }



  @override
  Widget build(BuildContext context, WidgetRef ref) {


    final state = ref.watch(
      technicianSignupController,
    );


    return Scaffold(

      backgroundColor: const Color(0xffF8FAFC),


      body: SafeArea(

        child: Column(

          children: [


            // HEADER
            Container(

              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                25,
              ),


              decoration: const BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),

              ),


              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,


                children: [


                  Row(

                    children: [


                      if(state.step > 0)

                        InkWell(

                          onTap: (){

                            ref
                                .read(
                              technicianSignupController
                                  .notifier,
                            )
                                .back();

                          },


                          child: Container(

                            padding:
                            const EdgeInsets.all(10),

                            decoration:
                            BoxDecoration(

                              color:
                              Colors.grey.shade100,

                              shape:
                              BoxShape.circle,

                            ),


                            child: const Icon(
                              Icons.arrow_back,
                              size:20,
                            ),

                          ),

                        )


                      else

                        const SizedBox(
                          width:40,
                        ),



                      const Spacer(),



                      Text(

                        "${state.step + 1} / 5",

                        style:
                        const TextStyle(

                          color:
                          Colors.blue,

                          fontWeight:
                          FontWeight.bold,

                        ),

                      )


                    ],

                  ),



                  const SizedBox(height:25),



                  Text(

                    title(state.step),

                    style:
                    const TextStyle(

                      fontSize:28,

                      fontWeight:
                      FontWeight.bold,

                    ),

                  ),



                  const SizedBox(height:8),



                  Text(

                    subtitle(state.step),

                    style:
                    TextStyle(

                      fontSize:15,

                      color:
                      Colors.grey.shade600,

                    ),

                  ),



                  const SizedBox(height:25),



                  // STEP INDICATOR
                  Row(

                    children:
                    List.generate(

                      5,

                          (index){

                        final active =
                            index <= state.step;


                        return Expanded(

                          child:
                          AnimatedContainer(

                            duration:
                            const Duration(
                              milliseconds:300,
                            ),


                            margin:
                            const EdgeInsets.only(
                              right:6,
                            ),


                            height:6,


                            decoration:
                            BoxDecoration(

                              color:
                              active

                                  ? Colors.blue

                                  : Colors.grey.shade300,


                              borderRadius:
                              BorderRadius.circular(10),

                            ),

                          ),

                        );

                      },

                    ),

                  )

                ],

              ),

            ),



            const SizedBox(height:20),



            // FORM AREA
            Expanded(

              child:
              SingleChildScrollView(

                padding:
                const EdgeInsets.symmetric(
                  horizontal:20,
                ),


                child:
                Container(

                  width:
                  double.infinity,


                  padding:
                  const EdgeInsets.all(20),


                  decoration:
                  BoxDecoration(

                    color:
                    Colors.white,


                    borderRadius:
                    BorderRadius.circular(25),


                    boxShadow:[

                      BoxShadow(

                        color:
                        Colors.black
                            .withOpacity(.05),

                        blurRadius:20,

                        offset:
                        const Offset(0,8),

                      )

                    ],

                  ),


                  child:
                  currentStep(
                    state.step,
                  ),

                ),

              ),

            ),


          ],

        ),

      ),

    );

  }

}