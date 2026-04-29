import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/providers/coach_provider.dart';
import 'package:mobile/core/models/membre_model.dart';
import 'package:intl/intl.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CoachProvider>(
      builder: (context, provider, _) {
        final members = provider.members;
        final courses = provider.myCourses;
        final totalClients = members.length;
        final totalCourses = courses.length;

        return Scaffold(
          backgroundColor: const Color(0xFFF5EDE8),
          body: SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFFD44820),
              onRefresh: () async {
                await provider.loadMembers();
                await provider.loadCourses();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF8B4513),
                          child: provider.profile != null
                              ? Text(
                                  provider.profile!.user.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : const Icon(Icons.person, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'PERFORMANCE LAB',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD44820),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.notifications_none, color: Color(0xFF1C1C1C), size: 24),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // OVERVIEW Title
                    const Text(
                      'OVERVIEW',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1C1C1C),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'TOTAL CLIENTS',
                            value: '$totalClients',
                            icon: Icons.trending_up,
                            iconColor: const Color(0xFF3DB87A),
                            subtitle: 'registered members',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'MY COURSES',
                            value: '$totalCourses',
                            icon: Icons.bolt,
                            iconColor: Colors.white,
                            subtitle: 'active courses',
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // MEMBERS Section
                    Row(
                      children: [
                        const Text(
                          'MEMBERS',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1C1C1C),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (members.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD44820),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$totalClients',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Loading state
                    if (provider.membersLoading && members.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: Color(0xFFD44820)),
                        ),
                      )
                    // Error state
                    else if (provider.membersError != null && members.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Color(0xFFD44820)),
                              const SizedBox(height: 8),
                              const Text('Failed to load members'),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => provider.loadMembers(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD44820),
                                ),
                                child: const Text('Retry', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    // Empty state
                    else if (members.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Color(0xFF9A7060)),
                              SizedBox(height: 8),
                              Text(
                                'No members yet',
                                style: TextStyle(
                                  color: Color(0xFF9A7060),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    // Members list
                    else
                      ...members.map((membre) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _MemberCard(membre: membre),
                          )),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Stats Card
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String subtitle;
  final bool isPrimary;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.subtitle,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFD44820) : const Color(0xFFEFDDD5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isPrimary ? Colors.white70 : const Color(0xFF9A7060),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: isPrimary ? Colors.white : const Color(0xFF1C1C1C),
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : const Color(0xFF3DB87A),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Member Card
class _MemberCard extends StatelessWidget {
  final Membre membre;

  const _MemberCard({required this.membre});

  @override
  Widget build(BuildContext context) {
    final user = membre.user;
    final joinDate = membre.joinDate != null
        ? DateFormat('d MMM yyyy').format(membre.joinDate!)
        : 'Unknown';

    // Generate a color based on the user's name for variety
    final colors = [
      const Color(0xFF5A3826),
      const Color(0xFF7A4A30),
      const Color(0xFFD4956A),
      const Color(0xFF8B4513),
      const Color(0xFF6B3A2A),
    ];
    final colorIndex = user.fullName.hashCode.abs() % colors.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFDDD5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors[colorIndex],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A5A4A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (membre.healthGoal != null && membre.healthGoal!.isNotEmpty) ...[
                      Flexible(
                        child: Text(
                          'Goal: ${membre.healthGoal}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9A7060),
                          ),
                        ),
                      ),
                      const Text(' · ', style: TextStyle(color: Color(0xFF9A7060), fontSize: 10)),
                    ],
                    Text(
                      'Joined $joinDate',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9A7060),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // View button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1B8A8), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'View\nDetails',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1C),
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}