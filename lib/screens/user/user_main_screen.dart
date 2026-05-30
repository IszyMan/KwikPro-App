import 'package:flutter/material.dart';
import 'package:kwikpro/screens/user/search_technicians_screen.dart';
import 'package:kwikpro/screens/user/user_contacts.dart';
import 'package:kwikpro/screens/user/user_job_history_screen.dart';
import 'package:kwikpro/screens/user/user_profile_screen.dart';
import '../admin/customer_support.dart';
import 'user_home_screen.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _selectedIndex = 2;

  final List<Widget> _screens = [
    UserHomeScreen(),
    UserJobHistoryScreen(),
    SearchTechnicianScreen(),
    CustomerSupport(),
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
      bottomNavigationBar: SizedBox(
        height: 85,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 🔵 BACKGROUND NAV BAR
            Container(
              height: 65,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
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

                  const SizedBox(width: 50), // SPACE FOR FLOATING BUTTON

                  _buildNavItem(Icons.support_agent, "Support", 3),
                  _buildNavItem(Icons.person, "Profile", 4),
                ],
              ),
            ),

            // 🔥 FLOATING CENTER BUTTON (MTN STYLE)
            Positioned(
              top: -25,
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
                      color: Colors.blueAccent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.search,
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
}