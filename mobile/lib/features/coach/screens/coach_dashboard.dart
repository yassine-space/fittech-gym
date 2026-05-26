// lib/features/coach/screens/coach_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/providers/coach_provider.dart';
import 'package:mobile/core/providers/notification_provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Coach data
      final coach = context.read<CoachProvider>();
      coach.loadProfile();
      coach.loadMembers();
      coach.loadCourses();
      coach.loadReservations();
      coach.loadWaitlist();

      // Notifications — load once then poll every 30s
      final notif = context.read<NotificationProvider>();
      notif.load();
      notif.startPolling();
    });
  }

  @override
  void dispose() {
    context.read<NotificationProvider>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const ClientsScreen(),
      const ProgramsScreen(),
      const CoachCoursesScreen(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        height: 100,
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
    const activeColor = Color(0xFFD45E36);
    const activeBgColor = Color(0xFFFDECE7);
    const inactiveColor = Color(0xFFAC9181);

    // Show unread badge on MESSAGES tab
    final showBadge = index == 3 &&
        context.watch<NotificationProvider>().notifications.any(
              (n) => !n.isRead && n.type == 'new_message',
            );

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
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? activeBgColor : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon,
                      size: 26,
                      color: isSelected ? activeColor : inactiveColor),
                ),
                if (showBadge)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD44820),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w800 : FontWeight.w600,
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