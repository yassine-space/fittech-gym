import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/providers/coach_provider.dart';
import 'package:mobile/core/models/membre_model.dart';
import 'package:mobile/features/coach/screens/member_detail_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Membre> _filtered(List<Membre> all) {
    if (_query.trim().isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((m) {
      return m.user.fullName.toLowerCase().contains(q) ||
          m.user.email.toLowerCase().contains(q) ||
          (m.healthGoal?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoachProvider>(
      builder: (context, provider, _) {
        final allMembers = provider.members;
        final filtered = _filtered(allMembers);
        final courses = provider.myCourses;
        final totalClients = allMembers.length;
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
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Header + stats + search ───────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App-bar row
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
                                    : const Icon(Icons.person,
                                        color: Colors.white, size: 18),
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
                              const Icon(Icons.notifications_none,
                                  color: Color(0xFF1C1C1C), size: 24),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Title
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

                          // Stats row
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

                          // Members section header
                          Row(
                            children: [
                              const Text(
                                'MEMBERS',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1C1C1C),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (allMembers.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
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
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Search bar
                          if (allMembers.isNotEmpty) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) => setState(() => _query = v),
                                decoration: InputDecoration(
                                  hintText: 'Search by name, email or goal…',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFFD1B8A8),
                                    fontSize: 13,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: Color(0xFFD44820),
                                    size: 20,
                                  ),
                                  suffixIcon: _query.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear,
                                              size: 18,
                                              color: Color(0xFF9A7060)),
                                          onPressed: () => setState(() {
                                            _query = '';
                                            _searchCtrl.clear();
                                          }),
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── Members list ──────────────────────────────────────────
                  if (provider.membersLoading && allMembers.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFD44820)),
                      ),
                    )
                  else if (provider.membersError != null && allMembers.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Color(0xFFD44820)),
                            const SizedBox(height: 8),
                            const Text('Failed to load members'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => provider.loadMembers(),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD44820)),
                              child: const Text('Retry',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (allMembers.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 56, color: Color(0xFF9A7060)),
                            SizedBox(height: 8),
                            Text(
                              'No members yet',
                              style: TextStyle(
                                color: Color(0xFF9A7060),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (filtered.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded,
                                size: 56, color: Color(0xFF9A7060)),
                            const SizedBox(height: 8),
                            Text(
                              'No results for "$_query"',
                              style: const TextStyle(
                                color: Color(0xFF9A7060),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MemberCard(membre: filtered[i]),
                          ),
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatCard
// ─────────────────────────────────────────────────────────────────────────────
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
                    color:
                        isPrimary ? Colors.white70 : const Color(0xFF3DB87A),
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

// ─────────────────────────────────────────────────────────────────────────────
// _MemberCard
// ─────────────────────────────────────────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final Membre membre;
  const _MemberCard({required this.membre});

  static const _avatarColors = [
    Color(0xFF5A3826),
    Color(0xFF7A4A30),
    Color(0xFFD4956A),
    Color(0xFF8B4513),
    Color(0xFF6B3A2A),
  ];

  @override
  Widget build(BuildContext context) {
    final user = membre.user;
    final colorIndex = user.fullName.hashCode.abs() % _avatarColors.length;
    final joinDate = membre.joinDate != null
        ? DateFormat('d MMM yyyy').format(membre.joinDate!)
        : 'Unknown';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFDDD5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _avatarColors[colorIndex],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
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
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A5A4A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // Goal + join date row
                Row(
                  children: [
                    if (membre.healthGoal != null &&
                        membre.healthGoal!.isNotEmpty) ...[
                      const Icon(Icons.flag_outlined,
                          size: 10, color: Color(0xFF9A7060)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          membre.healthGoal!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF9A7060)),
                        ),
                      ),
                      const Text(' · ',
                          style: TextStyle(
                              color: Color(0xFF9A7060), fontSize: 10)),
                    ],
                    Text(
                      'Joined $joinDate',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9A7060)),
                    ),
                  ],
                ),
                // Medical restriction warning badge
                if (membre.medicalRestrictions != null &&
                    membre.medicalRestrictions!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD44820).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 10, color: Color(0xFFD44820)),
                        SizedBox(width: 3),
                        Text(
                          'Medical restrictions',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD44820),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // View details button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberDetailScreen(membre: membre),
              ),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFD1B8A8), width: 1),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_search_rounded,
                      size: 16, color: Color(0xFFD44820)),
                  SizedBox(height: 2),
                  Text(
                    'View',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}