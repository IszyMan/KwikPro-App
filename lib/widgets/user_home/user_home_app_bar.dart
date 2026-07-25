import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserHomeAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const UserHomeAppBar({
    super.key,
    required this.name,
    required this.location,
    required this.profilePic,
    required this.searchQuery,
    required this.onLocationTap,
    required this.onNotificationTap,
    required this.onProfileTap,
    required this.onSearchChanged,
  });

  final String name;
  final String location;
  final String profilePic;
  final String searchQuery;

  final VoidCallback onLocationTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  final ValueChanged<String> onSearchChanged;

  @override
  Size get preferredSize => const Size.fromHeight(126);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 10),
              Text("Hi, $name"),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: onLocationTap,
              child: Row(
                children: [

                  Expanded(
                    child: Text(
                     ' 📍 $location',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Edit",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      actions: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where(
            'recipientId',
            isEqualTo: FirebaseAuth.instance.currentUser!.uid,
          )
              .where('read', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.data?.docs.length ?? 0;

            return Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    size: 35,
                  ),
                  onPressed: onNotificationTap,
                ),

                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        const SizedBox(width: 4),

        GestureDetector(
          onTap: onProfileTap,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: profilePic.isNotEmpty
                  ? NetworkImage(profilePic)
                  : null,
              child: profilePic.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
          ),
        ),
      ],

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText:
              "Search for services (e.g plumber, electrician)",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}