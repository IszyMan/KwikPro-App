import 'package:flutter/material.dart';

class UserHomeDrawer extends StatelessWidget {
  const UserHomeDrawer({
    super.key,
    required this.name,
    required this.profilePic,
    required this.location,
    required this.onEditProfile,
    required this.onJobHistory,
    required this.onPrivacyPolicy,
    required this.onTerms,
    required this.onDeleteAccount,
    required this.onLogout,
  });

  final String name;
  final String profilePic;
  final String location;

  final VoidCallback onEditProfile;
  final VoidCallback onJobHistory;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onTerms;
  final VoidCallback onDeleteAccount;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [

            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.blue,
              child: Column(
                children: [

                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                    profilePic.isNotEmpty
                        ? NetworkImage(profilePic)
                        : null,
                    child: profilePic.isEmpty
                        ? const Icon(Icons.person,size:40)
                        : null,
                  ),

                  const SizedBox(height:10),

                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize:18,
                    ),
                  ),

                  const SizedBox(height:5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size:16,
                      ),

                      const SizedBox(width:4),

                      Flexible(
                        child: Text(
                          location,
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height:10),

            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit Profile"),
              onTap: onEditProfile,
            ),

            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Job History"),
              onTap: onJobHistory,
            ),

            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text("Privacy Policy"),
              onTap: onPrivacyPolicy,
            ),

            ListTile(
              leading: const Icon(Icons.rule),
              title: const Text("Terms & Conditions"),
              onTap: onTerms,
            ),

            ListTile(
              leading: const Icon(
                Icons.delete_forever,
                color: Colors.red,
              ),
              title: const Text(
                "Delete Account",
                style: TextStyle(color: Colors.red),
              ),
              onTap: onDeleteAccount,
            ),

            const Spacer(),

            const Divider(),

            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text("Logout"),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}