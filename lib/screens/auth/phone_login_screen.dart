import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/onboarding_header.dart';
import 'otp_screen.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  final String role;

  const PhoneLoginScreen({
    super.key,
    required this.role,
  });

  @override
  ConsumerState<PhoneLoginScreen> createState() =>
      _PhoneLoginScreenState();
}

class _PhoneLoginScreenState
    extends ConsumerState<PhoneLoginScreen> {
  final TextEditingController phoneController =
  TextEditingController();

  final FocusNode phoneFocusNode = FocusNode();

  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    String phone = phoneController.text.trim();

    phone = phone.replaceAll(RegExp(r'\s+'), '');

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter your phone number"),
        ),
      );
      return;
    }

    // Normalize every valid format to +234xxxxxxxxxx
    if (phone.startsWith('+234')) {
      // already normalized
    } else if (phone.startsWith('234')) {
      phone = '+$phone';
    } else if (phone.startsWith('0')) {
      phone = '+234${phone.substring(1)}';
    } else if (phone.length == 10) {
      phone = '+234$phone';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter a valid Nigerian phone number"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final authService = ref.read(authServiceProvider);

    await authService.sendOtp(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        if (!mounted) return;

        setState(() => isLoading = false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              verificationId: verificationId,
              phoneNumber: phone,
              role: widget.role,
            ),
          ),
        );
      },
      onError: (error) {
        if (!mounted) return;

        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTechnician = widget.role == "technician";

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF4F9FF),
                  Colors.white,
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          const Center(
                            child: AppLogo(size: 90),
                          ),

                          const SizedBox(height: 28),

                          Center(
                            child: OnboardingHeader(
                              title: Text("Verify Your Phone"),
                              subtitle: isTechnician
                                  ? "Enter your Nigerian phone number to start receiving service requests."
                                  : "Enter your Nigerian phone number to book trusted technicians near you.",
                            ),
                          ),

                          const SizedBox(height: 40),

                          Text(
                            "Phone Number",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.border,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(.04),
                                  blurRadius: 10,
                                  offset:
                                  const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                  decoration:
                                  const BoxDecoration(
                                    color:
                                    AppColors.lightBlue,
                                    borderRadius:
                                    BorderRadius.only(
                                      topLeft:
                                      Radius.circular(
                                          16),
                                      bottomLeft:
                                      Radius.circular(
                                          16),
                                    ),
                                  ),
                                  child: const Text(
                                    "🇳🇬 +234",
                                    style: TextStyle(
                                      fontWeight:
                                      FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  child: TextField(
                                    controller:
                                    phoneController,
                                    focusNode:
                                    phoneFocusNode,
                                    keyboardType:
                                    TextInputType.phone,
                                    textInputAction:
                                    TextInputAction.done,
                                    onSubmitted: (_) =>
                                        _sendOtp(),
                                    inputFormatters: [
                                      FilteringTextInputFormatter
                                          .digitsOnly,
                                      LengthLimitingTextInputFormatter(
                                          10),
                                    ],
                                    style:
                                    const TextStyle(
                                      fontSize: 17,
                                    ),
                                    decoration:
                                    const InputDecoration(
                                      hintText:
                                      "9034697540",
                                      border:
                                      InputBorder.none,
                                      contentPadding:
                                      EdgeInsets
                                          .symmetric(
                                        horizontal: 16,
                                        vertical: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          Container(
                            padding:
                            const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                              AppColors.lightBlue,
                              borderRadius:
                              BorderRadius.circular(
                                  14),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color:
                                  AppColors.primary,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Enter your 10-digit Nigerian mobile number. We'll send you a verification code via SMS.",
                                    style: TextStyle(
                                      color: AppColors
                                          .textLight,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          Container(
                            key: const Key(
                                "recaptcha-container"),
                            height: 0,
                            width: 0,
                          ),

                          AppPrimaryButton(
                            text: "Continue",
                            loading: isLoading,
                            onPressed: _sendOtp,
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}