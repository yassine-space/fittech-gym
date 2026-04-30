import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  final String email;
  const HomeScreen({super.key, required this.role, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  static const Color primaryRed = Color(0xFFCC0000);
  static const Color bgColor = Color(0xFFF9F3F3);

  final List<Map<String, String>> _upcomingCourses = [
    {'title': 'Cardio', 'date': '11/03/2026', 'time': '18:00PM', 'coach': 'Avec yacine'},
    {'title': 'Yoga', 'date': '19/03/2026', 'time': '10:00AM', 'coach': 'Avec rayane'},
    {'title': 'Judo', 'date': '01/04/2026', 'time': '18:00PM', 'coach': 'Avec sidall'},
  ];

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: TextButton.styleFrom(foregroundColor: primaryRed),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.email.split('@')[0];
    final initials = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryRed,
                    radius: 22,
                    child: Text(initials,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Standard',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54)),
                          ),
                          const SizedBox(width: 8),
                          const Text('Mensuel',
                              style: TextStyle(fontSize: 12, color: Colors.black45)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.black54),
                    onPressed: _logout,
                  ),
                ],
              ),
            ),

            // ── Red Tab Bar ──
            Container(
              color: primaryRed,
              child: Row(
                children: [
                  _buildTab('Tableau de bord', Icons.dashboard_outlined, 0),
                  _buildTab('Mes cours', Icons.calendar_month_outlined, 1),
                  _buildTab('Profil', Icons.person_outline, 2),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Locked Progress Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_outline,
                                size: 30, color: Colors.black45),
                          ),
                          const SizedBox(height: 12),
                          const Text('Suivi de progression',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Colors.black87)),
                          const SizedBox(height: 8),
                          const Text(
                            'Le suivi détaillé de vos performances n\'est pas inclus dans votre abonnement Standard',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.black45, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Passer à Medium (49.99€/mois)',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Upcoming Courses ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCECEC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.calendar_month_outlined,
                                  color: Colors.black54, size: 20),
                              SizedBox(width: 8),
                              Text('Mes prochains cours',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: Colors.black87)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._upcomingCourses.map((course) => _buildCourseItem(course)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Coaches Card ──
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryRed, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Color(0xFF3949AB),
                                  child:
                                      Icon(Icons.person, color: Colors.white, size: 20),
                                ),
                                Positioned(
                                  left: 14,
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.green.shade300,
                                    child: const Icon(Icons.person,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 40),
                            const Text('Nos Coachs',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Colors.black87)),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.black38),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Upgrade Banner ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryRed,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text('🎯', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 8),
                              Text('Passez au niveau supérieur !',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Débloquez le suivi de progression, les statistiques détaillées et bien plus encore avec l\'abonnement Medium à partir de 49.99€/mois.',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 10),
                            ),
                            child: const Text('Voir les offres',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseItem(Map<String, String> course) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course['title']!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black87)),
                const SizedBox(height: 3),
                Text('${course['date']}   ${course['time']}   ${course['coach']}',
                    style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black54,
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Annuler', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}