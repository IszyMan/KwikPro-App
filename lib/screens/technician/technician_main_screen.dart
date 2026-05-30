import 'package:flutter/material.dart';
import 'package:kwikpro/screens/technician/technician_dashboard.dart';
import 'package:kwikpro/screens/technician/technician_home_screen.dart';


class TechnicianMainScreen extends StatefulWidget {
  const TechnicianMainScreen({super.key});

  @override
  State<TechnicianMainScreen> createState() => _TechnicianMainScreenState();
}

class _TechnicianMainScreenState extends State<TechnicianMainScreen> {

  int _selectedIndex = 0;

  final List<Widget> _screens = [
    TechnicianHomeScreen(),
    TechnicianDashboard(),
    Text("Profile")

  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: SizedBox(
        height: 85,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 🔵 BACKGROUND BAR
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
                  _buildTechNavItem(Icons.home, "Home", 0),

                  const SizedBox(width: 50), // space for center button

                  _buildTechNavItem(Icons.person, "Profile", 2),
                ],
              ),
            ),

            // 🔥 FLOATING CENTER BUTTON (REQUESTS)
            Positioned(
              top: -25,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _onItemTapped(1),
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
                      Icons.work,
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

  Widget _buildTechNavItem(IconData icon, String label, int index) {
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