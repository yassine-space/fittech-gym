import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For haptic feedback
// --- KEEP YOUR ORIGINAL IMPORTS ---
import 'clients_screen.dart';
import 'programs_screen.dart';
import 'schedule_screen.dart';
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

  // --- RESTORED YOUR ACTUAL SCREENS ---
  final List<Widget> _screens = [
    const ClientsScreen(),
    const ProgramsScreen(),
    const ScheduleScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // Using IndexedStack preserves the state of your pages
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 85, 
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              _buildNavItem(Icons.people_alt_rounded, 'CLIENTS', 0),
              _buildNavItem(Icons.fitness_center_rounded, 'PROGRAMS', 1),
              _buildNavItem(Icons.calendar_month_rounded, 'SCHEDULE', 2),
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
    const activeColor = Color(0xFFD44820);
    const inactiveColor = Color(0xFFB09080);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick(); // Adds a nice physical feel
          setState(() => _selectedIndex = index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicator bar that slides/fades in
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 4),
              height: 4,
              width: isSelected ? 18 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Scaled Icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: isSelected ? 1.2 : 1.0),
              duration: const Duration(milliseconds: 200),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            // Smooth text transition
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.5,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}