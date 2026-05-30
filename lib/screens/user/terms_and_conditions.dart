import 'package:flutter/material.dart';

class TermsAndConditions extends StatelessWidget {
  const TermsAndConditions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [

            Text(
              "Terms and Conditions for KwikPro",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              "Last Updated: May 2026",
              style: TextStyle(color: Colors.grey),
            ),

            SizedBox(height: 20),

            Text(
              "By accessing or using KwikPro, you agree to these Terms and Conditions.",
            ),

            SizedBox(height: 24),

            SectionTitle("About KwikPro"),

            Text(
              "KwikPro is a technology platform that connects users with independent technicians and service providers.",
            ),

            SizedBox(height: 10),

            Text(
              "KwikPro is not the direct provider of repair, maintenance, installation, or technical services offered by technicians on the platform.",
            ),

            SizedBox(height: 24),

            SectionTitle("Eligibility"),

            Text(
              "Users must be at least 18 years old or have consent from a parent or guardian to use the platform.",
            ),

            SizedBox(height: 24),

            SectionTitle("User Accounts"),

            Text("Users agree to:"),

            SizedBox(height: 10),

            BulletText("Provide accurate information"),
            BulletText("Keep login credentials secure"),
            BulletText("Use the platform responsibly"),
            BulletText("Avoid fraudulent activities"),

            SizedBox(height: 24),

            SectionTitle("Technician Accounts"),

            Text("Technicians agree to:"),

            SizedBox(height: 10),

            BulletText("Provide accurate professional information"),
            BulletText("Maintain valid contact details"),
            BulletText("Submit genuine verification documents"),
            BulletText("Deliver services professionally"),

            SizedBox(height: 10),

            Text(
              "Providing false information may result in suspension or permanent removal.",
            ),

            SizedBox(height: 24),

            SectionTitle("Service Requests"),

            Text("Users acknowledge that:"),

            SizedBox(height: 10),

            BulletText("Technicians are independent service providers"),
            BulletText("Service outcomes may vary"),
            BulletText("Prices may differ between technicians"),
            BulletText("Users are responsible for evaluating service providers before hiring"),

            SizedBox(height: 24),

            SectionTitle("Payments"),

            Text(
              "KwikPro facilitates connections between users and technicians only.",
            ),

            SizedBox(height: 10),

            Text(
              "Payments are arranged directly between users and technicians.",
            ),

            SizedBox(height: 10),

            Text(
              "KwikPro is not responsible for payment disputes outside the platform.",
            ),

            SizedBox(height: 24),

            SectionTitle("Ratings and Reviews"),

            Text(
              "Users may submit ratings and reviews based on genuine experiences.",
            ),

            SizedBox(height: 10),

            Text(
              "KwikPro may remove misleading, abusive, or fraudulent reviews.",
            ),

            SizedBox(height: 24),

            SectionTitle("Prohibited Activities"),

            Text("Users must not:"),

            SizedBox(height: 10),

            BulletText("Engage in fraud"),
            BulletText("Impersonate others"),
            BulletText("Upload harmful content"),
            BulletText("Harass other users"),
            BulletText("Circumvent platform rules"),
            BulletText("Use the platform for illegal activities"),

            SizedBox(height: 24),

            SectionTitle("Suspension and Termination"),

            Text(
              "KwikPro may suspend or terminate accounts that violate these Terms.",
            ),

            SizedBox(height: 24),

            SectionTitle("Limitation of Liability"),

            Text(
              "KwikPro provides a marketplace platform and does not guarantee:",
            ),

            SizedBox(height: 10),

            BulletText("Service quality"),
            BulletText("Technician performance"),
            BulletText("Availability of technicians"),
            BulletText("Successful completion of requested services"),

            SizedBox(height: 10),

            Text(
              "KwikPro is not liable for indirect, incidental, or consequential damages arising from use of the platform.",
            ),

            SizedBox(height: 24),

            SectionTitle("Job Cancellation"),

            Text(
              "Users and technicians may cancel a service request before work begins. Repeated cancellations may result in restrictions.",
            ),

            SizedBox(height: 24),

            SectionTitle("Safety Disclaimer"),

            Text(
              "Users should exercise caution when engaging technicians. Always verify service details before granting access to your property.",
            ),

            SizedBox(height: 24),

            SectionTitle("Account Deletion"),

            Text(
              "Users may request account deletion through the app or by contacting support.",
            ),

            SizedBox(height: 24),

            SectionTitle("Intellectual Property"),

            Text(
              "KwikPro branding, design, software, and content remain the property of KwikPro and may not be copied or reused without permission.",
            ),

            SizedBox(height: 24),

            SectionTitle("Changes to Terms"),

            Text(
              "We may update these Terms periodically.",
            ),

            SizedBox(height: 10),

            Text(
              "Continued use of KwikPro means you accept the updated Terms.",
            ),

            SizedBox(height: 24),

            SectionTitle("Contact Information"),

            Text("KwikPro Support"),
            SizedBox(height: 10),
            Text("Email: support@kwikpro.com"),
            Text("Website: kwikpro.com"),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/* ================= REUSABLE WIDGETS ================= */

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class BulletText extends StatelessWidget {
  final String text;

  const BulletText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• "),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}