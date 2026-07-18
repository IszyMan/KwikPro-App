import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kwikpro/screens/user/user_job_history_screen.dart';
import 'package:kwikpro/screens/user/user_profile_screen.dart';
import '../../core/colors.dart';
import '../chat/chats_screen.dart';
import '../showcase/showcase_screen.dart';
import 'user_home_screen.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    UserHomeScreen(),
    UserJobHistoryScreen(),
    ShowcaseScreen(),
    ChatsScreen(),
    UserProfileScreen(),

  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 0,
            right: 0,
            bottom: 10, // brings the navbar up
          ),
          child: SizedBox(
            height: 90,
            child: Stack(
              clipBehavior: Clip.none,
              children: [

                // NAV BAR
                Positioned(
                  left: 16,
                  right: 16,
                  top: 20,
                  child: Container(
                    height: 65,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [

                        _buildNavItem(Icons.home, "Home", 0),

                        _buildNavItem(Icons.history, "Jobs", 1),

                        const SizedBox(width: 50),

                        _buildChatNavItem(),

                        _buildNavItem(Icons.person, "Profile", 4),

                      ],
                    ),
                  ),
                ),

                // CENTER BUTTON
                Positioned(
                  top: -5,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _onItemTapped(2),
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(.35),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.collections_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blueAccent : Colors.grey,
            size: isSelected ? 28 : 24,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.blueAccent : Colors.grey,
              fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatNavItem() {
    final myId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .where("participants", arrayContains: myId)
          .snapshots(),
      builder: (context, chatSnapshot) {
        if (!chatSnapshot.hasData) {
          return _buildNavItem(Icons.chat_bubble_outline, "Chats", 3);
        }

        final chats = chatSnapshot.data!.docs;

        if (chats.isEmpty) {
          return _buildNavItem(Icons.chat_bubble_outline, "Chats", 3);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup("messages")
              .where("receiverId", isEqualTo: myId)
              .where("read", isEqualTo: false)
              .snapshots(),
          builder: (context, unreadSnapshot) {
            final unreadCount =
                unreadSnapshot.data?.docs.length ?? 0;

            final isSelected = _selectedIndex == 3;

            return GestureDetector(
              onTap: () => _onItemTapped(3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Stack(
                    clipBehavior: Clip.none,
                    children: [

                      Icon(
                        Icons.chat_bubble_outline,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey,
                        size: isSelected ? 28 : 24,
                      ),

                      if (unreadCount > 0)
                        Positioned(
                          right: -8,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99
                                    ? "99+"
                                    : "$unreadCount",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  Text(
                    "Chats",
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}