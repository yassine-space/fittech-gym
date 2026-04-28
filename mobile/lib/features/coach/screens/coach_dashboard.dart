import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'clients_screen.dart';
import 'programs_screen.dart';
import 'courses_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class CoachDashboard extends StatefulWidget {
  final String email;
  const CoachDashboard({super.key, required this.email});

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
  int _selectedIndex = 0;

  // Mock screens for demonstration - replace these with your actual imported widgets
   final List<Widget> _screens = [

const ClientsScreen(),

const ProgramsScreen(),

CoursesScreen(token: "myJwtToken", userRole: 'membre'),

const MessagesScreen(),

const ProfileScreen(),

]; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 100, // Adjusted height to match the photo's spacing
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.people_alt_rounded, 'CLIENTS', 0),
              _buildNavItem(Icons.fitness_center_rounded, 'PROGRAMS', 1),
              _buildNavItem(Icons.menu_book_rounded, 'COURSES', 2),
              _buildNavItem(Icons.chat_bubble_rounded, 'MESSAGES', 3),
              _buildNavItem(Icons.person_rounded, 'PROFILE', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    // Color Palette based on your image
    const activeColor = Color(0xFFD45E36);      // Darker peach/orange
    const activeBgColor = Color(0xFFFDECE7);    // Very light peach circle
    const inactiveColor = Color(0xFFAC9181);    // Muted brownish-grey

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedIndex = index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular highlight
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12), // Adjust padding for circle size
              decoration: BoxDecoration(
                color: isSelected ? activeBgColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            // Text Label
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}