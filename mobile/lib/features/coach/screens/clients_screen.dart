import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/providers/coach_provider.dart';
import 'package:mobile/core/models/membre_model.dart';
import 'package:mobile/core/models/course.dart';
import 'package:mobile/features/coach/screens/member_detail_screen.dart';
import 'package:mobile/features/coach/screens/course_detail_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFD44820);
const _kNavy = Color(0xFF1C1C1C);
const _kBg = Color(0xFFF5EDE8);
const _kGrey = Color(0xFF9A7060);
const _kGreen = Color(0xFF3DB87A);
const _kWhite = Colors.white;
const _kCardBg = Color(0xFFEFDDD5);

// ─── ClientsScreen (Dashboard Home) ──────────────────────────────────────────
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
        final assigned = provider.assignedMembers;
        final filtered = _filtered(assigned);
        final upcoming = provider.upcomingCourses.take(3).toList();
        final reviews = provider.reviews;
        final avgRating = provider.averageRating;

        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: RefreshIndicator(
              color: _kOrange,
              onRefresh: () async {
                await Future.wait([
                  provider.loadAssignedMembers(),
                  provider.loadCourses(),
                  provider.loadReviews(),
                ]);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Static header content ─────────────────────────────
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App bar
                        _buildAppBar(provider),

                        // Title
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Text(
                            'DASHBOARD',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: _kNavy,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Your coaching overview at a glance.',
                            style: TextStyle(
                                fontSize: 13,
                                color: _kGrey,
                                height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Stats row
                        _buildStatsRow(provider, assigned.length, upcoming.length, avgRating, reviews.length),
                        const SizedBox(height: 24),

                        // Upcoming courses
                        if (upcoming.isNotEmpty) ...[
                          _buildSectionHeader('UPCOMING COURSES', '${upcoming.length}'),
                          const SizedBox(height: 12),
                          _buildUpcomingCourses(upcoming, provider),
                          const SizedBox(height: 24),
                        ],

                        // Reviews summary
                        if (reviews.isNotEmpty) ...[
                          _buildSectionHeader('REVIEWS SUMMARY', '${reviews.length}'),
                          const SizedBox(height: 12),
                          _buildReviewsSummary(avgRating, reviews.length, provider),
                          const SizedBox(height: 24),
                        ],

                        // Assigned members header + search
                        _buildMembersHeader(assigned, filtered),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),

                  // ── Members list ──────────────────────────────────────
                  _buildMembersSliver(provider, assigned, filtered),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar(CoachProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD44820), Color(0xFFE8653A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: provider.profile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: provider.profile!.user.profilePhoto != null
                        ? Image.network(
                            provider.profile!.user.profilePhoto!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(
                                provider.profile!.user.initials,
                                style: const TextStyle(
                                    color: _kWhite,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              provider.profile!.user.initials,
                              style: const TextStyle(
                                  color: _kWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                  )
                : const Icon(Icons.person, color: _kWhite, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERFORMANCE LAB',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _kOrange,
                    letterSpacing: 1.2,
                  ),
                ),
                if (provider.profile != null)
                  Text(
                    'Hi, ${provider.profile!.user.firstName} 👋',
                    style: const TextStyle(
                        fontSize: 12,
                        color: _kGrey,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          const Icon(Icons.notifications_none, color: _kNavy, size: 24),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow(CoachProvider provider, int memberCount,
      int upcomingCount, double avgRating, int reviewCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatCard(
            label: 'CLIENTS',
            value: '$memberCount',
            subtitle: 'assigned members',
            icon: Icons.people_alt_rounded,
            isPrimary: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                _SmallStatCard(
                  label: 'UPCOMING',
                  value: '$upcomingCount',
                  icon: Icons.upcoming_rounded,
                  color: _kNavy,
                ),
                const SizedBox(height: 10),
                _SmallStatCard(
                  label: 'RATING',
                  value: reviewCount == 0
                      ? '—'
                      : avgRating.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                  color: _kOrange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, String badge) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _kNavy)),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _kOrange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(badge,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _kWhite)),
          ),
        ],
      ),
    );
  }

  // ── Upcoming courses ──────────────────────────────────────────────────────
  Widget _buildUpcomingCourses(List<Course> upcoming, CoachProvider provider) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: upcoming.length,
        itemBuilder: (_, i) {
          final c = upcoming[i];
          final enrolled =
              c.maxParticipants - c.spotsRemaining;
          final levelColor = switch (c.level) {
            'beginner' => _kGreen,
            'intermediate' => _kOrange,
            'advanced' => const Color(0xFFE74C3C),
            _ => _kGrey,
          };

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CourseDetailScreen(course: c)),
            ),
            child: Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kWhite,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: levelColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          c.level[0].toUpperCase() +
                              c.level.substring(1),
                          style: TextStyle(
                              fontSize: 9,
                              color: levelColor,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      const Spacer(),
                      Text('${c.durationMinutes}m',
                          style: const TextStyle(
                              fontSize: 10, color: _kGrey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kNavy,
                          height: 1.2)),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 11, color: _kGrey),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMM, h:mm a').format(c.dateTime),
                        style: const TextStyle(
                            fontSize: 10,
                            color: _kGrey,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 11, color: _kGrey),
                      const SizedBox(width: 4),
                      Text('$enrolled / ${c.maxParticipants}',
                          style: const TextStyle(
                              fontSize: 10, color: _kGrey)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Reviews summary ───────────────────────────────────────────────────────
  Widget _buildReviewsSummary(
      double avgRating, int total, CoachProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            // Average rating
            Column(
              children: [
                Text(avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: _kNavy,
                        height: 1)),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < avgRating.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 14,
                      color: _kOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text('$total review${total == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 11, color: _kGrey)),
              ],
            ),
            const SizedBox(width: 20),
            // Star bars
            Expanded(
              child: Column(
                children: List.generate(5, (i) {
                  final star = 5 - i;
                  final count = provider.reviewCountForStar(star);
                  final pct = total > 0 ? count / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text('$star',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _kGrey)),
                        const Icon(Icons.star_rounded,
                            size: 11, color: _kOrange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor:
                                  const Color(0xFFF0E0D8),
                              valueColor:
                                  const AlwaysStoppedAnimation(_kOrange),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('$count',
                            style: const TextStyle(
                                fontSize: 10, color: _kGrey)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Members header + search ───────────────────────────────────────────────
  Widget _buildMembersHeader(
      List<Membre> assigned, List<Membre> filtered) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('ASSIGNED MEMBERS',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _kNavy)),
              const SizedBox(width: 8),
              if (assigned.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: _kOrange,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('${assigned.length}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _kWhite)),
                ),
            ],
          ),
          if (assigned.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                  color: _kWhite,
                  borderRadius: BorderRadius.circular(14)),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search by name, email or goal…',
                  hintStyle: const TextStyle(
                      color: Color(0xFFD1B8A8), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: _kOrange, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              size: 18, color: _kGrey),
                          onPressed: () => setState(() {
                            _query = '';
                            _searchCtrl.clear();
                          }),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Members sliver ────────────────────────────────────────────────────────
  Widget _buildMembersSliver(
      CoachProvider provider, List<Membre> assigned, List<Membre> filtered) {
    if (provider.assignedMembersLoading && assigned.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
            child: CircularProgressIndicator(color: _kOrange)),
      );
    }
    if (provider.assignedMembersError != null && assigned.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: _kOrange),
              const SizedBox(height: 8),
              const Text('Failed to load assigned members'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => provider.loadAssignedMembers(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kOrange),
                child: const Text('Retry',
                    style: TextStyle(color: _kWhite)),
              ),
            ],
          ),
        ),
      );
    }
    if (assigned.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline,
                  size: 56, color: _kGrey),
              SizedBox(height: 8),
              Text('No assigned members yet',
                  style: TextStyle(
                      color: _kGrey,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              SizedBox(height: 4),
              Text(
                'Members assigned to you will appear here.',
                style: TextStyle(color: _kGrey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (filtered.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 56, color: _kGrey),
              const SizedBox(height: 8),
              Text('No results for "$_query"',
                  style: const TextStyle(
                      color: _kGrey, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MemberCard(membre: filtered[i]),
          ),
          childCount: filtered.length,
        ),
      ),
    );
  }
}

// ─── _StatCard ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool isPrimary;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary ? _kOrange : _kCardBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPrimary ? Colors.white70 : _kGrey,
                    letterSpacing: 0.8)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: isPrimary ? _kWhite : _kNavy,
                    height: 1)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon,
                    color: isPrimary ? Colors.white70 : _kGreen,
                    size: 13),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(subtitle,
                      style: TextStyle(
                          color: isPrimary
                              ? Colors.white70
                              : _kGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _SmallStatCard ───────────────────────────────────────────────────────────
class _SmallStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SmallStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _kGrey,
                        letterSpacing: 0.5)),
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1.1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _MemberCard ──────────────────────────────────────────────────────────────
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
        color: _kCardBg,
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
                    color: _kWhite,
                    fontWeight: FontWeight.w800,
                    fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _kNavy)),
                const SizedBox(height: 3),
                Text(user.email,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7A5A4A),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (membre.healthGoal != null &&
                        membre.healthGoal!.isNotEmpty) ...[
                      const Icon(Icons.flag_outlined,
                          size: 10, color: _kGrey),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          membre.healthGoal!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, color: _kGrey),
                        ),
                      ),
                      const Text(' · ',
                          style: TextStyle(
                              color: _kGrey, fontSize: 10)),
                    ],
                    Text('Joined $joinDate',
                        style: const TextStyle(
                            fontSize: 10, color: _kGrey)),
                  ],
                ),
                if (membre.medicalRestrictions != null &&
                    membre.medicalRestrictions!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 10, color: _kOrange),
                        SizedBox(width: 3),
                        Text('Medical restrictions',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _kOrange)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // View button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      MemberDetailScreen(membre: membre)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _kWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFD1B8A8), width: 1),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_search_rounded,
                      size: 16, color: _kOrange),
                  SizedBox(height: 2),
                  Text('View',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _kNavy)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
