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
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Terms & Conditions for KwikPro",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              "Last Updated: May 2026",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            SizedBox(height: 20),

            Text(
              "Welcome to KwikPro. These Terms & Conditions govern your access to and use of the KwikPro mobile application, website, and related services. By creating an account or using KwikPro, you agree to comply with these Terms & Conditions. If you do not agree, please do not use the platform.",
            ),

            SizedBox(height: 24),

            SectionTitle("About KwikPro"),

            Text(
              "KwikPro is a platform that connects customers with independent technicians and service professionals. KwikPro facilitates discovery, communication, and service requests between users and technicians.",
            ),

            SizedBox(height: 10),

            Text(
              "KwikPro does not directly provide repair, maintenance, installation, or technical services unless explicitly stated.",
            ),

            SizedBox(height: 24),

            SectionTitle("User Eligibility"),

            BulletText("Be at least 18 years old or have legal permission from a parent or guardian."),
            BulletText("Provide accurate and complete registration information."),
            BulletText("Comply with applicable laws and regulations."),

            SizedBox(height: 24),

            SectionTitle("User Accounts"),

            Text("Users are responsible for:"),
            SizedBox(height: 10),

            BulletText("Maintaining confidentiality of account credentials"),
            BulletText("Keeping account information accurate and updated"),
            BulletText("Protecting account from unauthorized access"),
            BulletText("Reporting suspicious activity immediately"),

            SizedBox(height: 10),

            Text(
              "Users remain responsible for all activities performed through their accounts.",
            ),

            SizedBox(height: 24),

            SectionTitle("Technician Verification"),

            Text(
              "Technicians may be required to submit identification and verification documents before using certain features.",
            ),

            SizedBox(height: 10),

            Text(
              "KwikPro reserves the right to approve, reject, suspend, or remove technician accounts that fail verification requirements.",
            ),

            SizedBox(height: 24),

            SectionTitle("Service Requests"),

            Text("Technicians are solely responsible for:"),

            SizedBox(height: 10),

            BulletText("Quality of services provided"),
            BulletText("Pricing and quotations"),
            BulletText("Workmanship and service outcomes"),
            BulletText("Compliance with applicable laws"),

            SizedBox(height: 10),

            Text(
              "Customers are responsible for evaluating technicians before hiring.",
            ),

            SizedBox(height: 24),

            SectionTitle("Payments"),

            Text(
              "Payments are agreements between customers and technicians unless otherwise stated.",
            ),

            SizedBox(height: 10),

            Text(
              "KwikPro may introduce payment processing features in the future.",
            ),

            SizedBox(height: 24),

            SectionTitle("Prohibited Activities"),

            BulletText("Provide false or misleading information"),
            BulletText("Impersonate others"),
            BulletText("Use platform for illegal activities"),
            BulletText("Upload harmful or abusive content"),
            BulletText("Attempt unauthorized access"),
            BulletText("Interfere with platform operations"),
            BulletText("Use scraping or automated tools without permission"),

            SizedBox(height: 24),

            SectionTitle("User Content"),

            Text(
              "Users may upload content such as profiles, photos, messages, and reviews.",
            ),

            SizedBox(height: 10),

            Text(
              "Users grant KwikPro permission to store and use such content for platform operations.",
            ),

            SizedBox(height: 24),

            SectionTitle("Ratings and Reviews"),

            Text(
              "KwikPro may remove fraudulent, abusive, or misleading reviews.",
            ),

            SizedBox(height: 24),

            SectionTitle("Account Suspension and Termination"),

            BulletText("Violation of Terms & Conditions"),
            BulletText("Fraudulent activity"),
            BulletText("Security threats"),
            BulletText("Abuse of other users"),
            BulletText("False verification details"),

            SizedBox(height: 10),

            Text(
              "Users may request account deletion at any time.",
            ),

            SizedBox(height: 24),

            SectionTitle("Limitation of Liability"),

            Text(
              "KwikPro acts solely as a technology platform that connects customers and independent technicians. KwikPro does not supervise, control, employ, or guarantee the conduct, performance, pricing, safety, legality, or reliability of any technician.",
            ),

            SizedBox(height: 10),

            Text(
              "To the maximum extent permitted by law, KwikPro shall not be liable for any damages, losses, or issues arising from the use of the platform or services provided by technicians.",
            ),

            SizedBox(height: 10),

            Text("This includes but is not limited to:"),

            SizedBox(height: 10),

            BulletText("Service quality or workmanship"),
            BulletText("Financial loss or payment disputes"),
            BulletText("Property damage or personal injury"),
            BulletText("Delays, cancellations, or failed service completion"),
            BulletText("Disputes between users and technicians"),

            SizedBox(height: 24),

            SectionTitle("Indemnification"),

            Text(
              "Users agree to indemnify and hold KwikPro harmless from claims, damages, and losses resulting from misuse of the platform.",
            ),

            SizedBox(height: 24),

            SectionTitle("Intellectual Property"),

            Text(
              "All KwikPro branding, software, and content remain the property of KwikPro and may not be copied or reused without permission.",
            ),

            SizedBox(height: 24),

            SectionTitle("Privacy"),

            Text(
              "Use of KwikPro is also governed by our Privacy Policy.",
            ),

            SizedBox(height: 24),

            SectionTitle("Changes to Terms"),

            Text(
              "KwikPro may update these Terms at any time. Continued use means acceptance of updated Terms.",
            ),

            SizedBox(height: 24),

            SectionTitle("Governing Law"),

            Text(
              "These Terms are governed by the laws of the jurisdiction where KwikPro operates.",
            ),

            SizedBox(height: 24),

            SectionTitle("Contact Us"),

            Text("KwikPro Support"),
            SizedBox(height: 8),
            Text("Phone: +234 7067455144"),
            Text("Email: iszifyaws@gmail.com.com"),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/* ================= REUSABLE WIDGETS ================= */

class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        text,
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