import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/onboarding_header.dart';
import '../splash/splash_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String role;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.role,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController otpController =
  TextEditingController();

  final FocusNode otpFocusNode = FocusNode();

  bool isLoading = false;

  @override
  void dispose() {
    otpController.dispose();
    otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final code = otpController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter the 6-digit verification code."),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);

      final result = await authService.verifyOtp(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      final firebaseUser = result.user;

      if (firebaseUser == null) {
        throw Exception("User is null");
      }

      ref.read(authProvider.notifier).setUser(firebaseUser);

      if (!mounted) return;

      setState(() => isLoading = false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => SplashScreen(
            role: widget.role,
          ),
        ),
            (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        children: [
                          const SizedBox(height: 20),

                          const AppLogo(size: 90),

                          const SizedBox(height: 28),

                          OnboardingHeader(
                            title: Text("Verify OTP"),
                            subtitle:
                            "Enter the 6-digit verification code sent to\n${widget.phoneNumber}",
                          ),

                          const SizedBox(height: 40),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Verification Code",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
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
                            child: TextField(
                              controller: otpController,
                              focusNode: otpFocusNode,
                              autofocus: true,
                              keyboardType:
                              TextInputType.number,
                              textAlign: TextAlign.center,
                              textInputAction:
                              TextInputAction.done,
                              onSubmitted: (_) =>
                                  _verifyOtp(),
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly,
                                LengthLimitingTextInputFormatter(
                                    6),
                              ],
                              style: const TextStyle(
                                fontSize: 24,
                                letterSpacing: 10,
                                fontWeight:
                                FontWeight.bold,
                              ),
                              decoration:
                              const InputDecoration(
                                hintText: "123456",
                                counterText: "",
                                border:
                                InputBorder.none,
                                contentPadding:
                                EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

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
                                  Icons.sms_outlined,
                                  color:
                                  AppColors.primary,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Didn't receive the code? It may take a few moments for the SMS to arrive.",
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

                          AppPrimaryButton(
                            text: "Verify",
                            loading: isLoading,
                            onPressed: _verifyOtp,
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