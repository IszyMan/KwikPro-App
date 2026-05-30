import 'package:flutter/material.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [

            Text(
              "Privacy Policy for KwikPro",
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
              "Welcome to KwikPro. KwikPro is a platform that connects customers with nearby technicians and service professionals. This Privacy Policy explains how we collect, use, and protect your information when you use the KwikPro mobile application and related services.",
            ),

            SizedBox(height: 24),

            SectionTitle("Information We Collect"),

            SectionTitle("Account Information", isSubTitle: true),

            BulletText("Full name"),
            BulletText("Phone number"),
            BulletText("Profile picture"),
            BulletText("Account type (Customer or Technician)"),

            SizedBox(height: 16),

            SectionTitle("Location Information", isSubTitle: true),

            Text(
              "KwikPro uses location data to help users find nearby technicians and to help technicians receive service requests within their service area.",
            ),

            SizedBox(height: 10),

            BulletText("While using the app"),
            BulletText("When searching for nearby technicians"),
            BulletText(
              "When technicians update their availability and service locations",
            ),

            SizedBox(height: 16),

            SectionTitle(
              "Technician Verification Information",
              isSubTitle: true,
            ),

            Text(
              "Technicians may be required to submit verification documents including:",
            ),

            SizedBox(height: 10),

            BulletText("Government-issued identification"),
            BulletText("National Identification Number (NIN)"),
            BulletText(
              "Other verification documents deemed necessary",
            ),

            SizedBox(height: 10),

            Text(
              "These documents are used solely for identity verification and platform security.",
            ),

            SizedBox(height: 16),

            SectionTitle("Communication Data", isSubTitle: true),

            BulletText("Chat messages exchanged through the platform"),
            BulletText("Call records initiated through the platform"),
            BulletText("Service-related communication history"),

            SizedBox(height: 16),

            SectionTitle("Uploaded Content", isSubTitle: true),

            BulletText("Profile photos"),
            BulletText("Job-related photos"),
            BulletText("Service completion images"),
            BulletText("Other content voluntarily submitted through the platform"),

            SizedBox(height: 16),

            SectionTitle("Device Information", isSubTitle: true),

            BulletText("Device model"),
            BulletText("Operating system"),
            BulletText("Device identifiers"),
            BulletText("IP address"),
            BulletText("App version"),

            SizedBox(height: 16),

            SectionTitle("Analytics Information", isSubTitle: true),

            Text(
              "KwikPro uses analytics services to understand user behavior and improve platform performance.",
            ),

            SizedBox(height: 10),

            BulletText("App usage statistics"),
            BulletText("Feature interactions"),
            BulletText("Error reports"),
            BulletText("Performance information"),

            SizedBox(height: 24),

            SectionTitle("How We Use Information"),

            BulletText("Create and manage user accounts"),
            BulletText("Match users with nearby technicians"),
            BulletText(
              "Facilitate communication between users and technicians",
            ),
            BulletText("Verify technician identities"),
            BulletText("Improve platform functionality"),
            BulletText("Provide customer support"),
            BulletText("Send service-related notifications"),
            BulletText("Prevent fraud, abuse, and unauthorized activity"),
            BulletText("Monitor platform security"),

            SizedBox(height: 24),

            SectionTitle("Information Sharing"),

            Text(
              "KwikPro does not sell personal information.",
            ),

            SizedBox(height: 16),

            SectionTitle(
              "Between Users and Technicians",
              isSubTitle: true,
            ),

            Text(
              "Relevant information such as names, phone numbers, locations, and service details may be shared when necessary to complete a service request.",
            ),

            SizedBox(height: 16),

            SectionTitle("Service Providers", isSubTitle: true),

            Text(
              "We may use trusted third-party providers for:",
            ),

            SizedBox(height: 10),

            BulletText("Analytics"),
            BulletText("Cloud hosting"),
            BulletText("Notifications"),
            BulletText("Security services"),

            SizedBox(height: 16),

            SectionTitle("Legal Compliance", isSubTitle: true),

            Text(
              "Information may be disclosed where required by law, regulation, court order, or government request.",
            ),

            SizedBox(height: 24),

            SectionTitle("Data Security"),

            Text(
              "We implement reasonable administrative, technical, and organizational safeguards to protect user information against unauthorized access, disclosure, alteration, or destruction.",
            ),

            SizedBox(height: 10),

            Text(
              "However, no internet-based service can guarantee absolute security.",
            ),

            SizedBox(height: 24),

            SectionTitle("User Rights"),

            BulletText("Update account information"),
            BulletText("Request correction of inaccurate information"),
            BulletText("Request account deletion"),
            BulletText("Contact support regarding privacy concerns"),

            SizedBox(height: 24),

            SectionTitle("Account Deletion"),

            Text(
              "Users may delete their account through the app or by contacting support.",
            ),

            SizedBox(height: 10),

            Text(
              "Upon deletion request, personal information will be removed or anonymized except where retention is required for legal, security, or dispute-resolution purposes.",
            ),

            SizedBox(height: 24),

            SectionTitle("Children's Privacy"),

            Text(
              "KwikPro is not intended for individuals under the age of 13.",
            ),

            SizedBox(height: 10),

            Text(
              "We do not knowingly collect information from children.",
            ),

            SizedBox(height: 24),

            SectionTitle("Changes to This Policy"),

            Text(
              "We may update this Privacy Policy periodically.",
            ),

            SizedBox(height: 10),

            Text(
              "Updated versions will be posted within the application and on our website.",
            ),

            SizedBox(height: 24),

            SectionTitle("Contact Us"),

            Text("KwikPro Support"),
            SizedBox(height: 8),
            Text("Phone: +234 7067455144"),
            Text("Email: support@kwikpro.com"),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final bool isSubTitle;

  const SectionTitle(
      this.title, {
        super.key,
        this.isSubTitle = false,
      });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isSubTitle ? 0 : 8,
        bottom: 12,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isSubTitle ? 18 : 20,
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
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}