// lib/features/coach/screens/clients_screen.dart
//
// Changes from previous version:
//   • Notification bell in the app-bar now navigates to NotificationsScreen
//     via the shared NotificationBell widget (Fix #3).
//   • Everything else is identical to the uploaded version.
//
// Place this file at:  lib/features/coach/screens/clients_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/providers/coach_provider.dart';
import 'package:mobile/core/models/membre_model.dart';
import 'package:mobile/core/models/course.dart';
import 'package:mobile/core/widgets/notification_bell.dart';                // ← NEW
import 'package:mobile/features/coach/screens/member_detail_screen.dart';
import 'package:mobile/features/coach/screens/course_detail_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFD44820);
const _kNavy   = Color(0xFF1C1C1C);
const _kBg     = Color(0xFFF5EDE8);
const _kGrey   = Color(0xFF9A7060);
const _kGreen  = Color(0xFF3DB87A);
const _kWhite  = Colors.white;
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
        final assigned  = provider.assignedMembers;
        final filtered  = _filtered(assigned);
        final upcoming  = provider.upcomingCourses.take(3).toList();
        final reviews   = provider.reviews;
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
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAppBar(provider),
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
                                fontSize: 13, color: _kGrey, height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildStatsRow(provider, assigned.length,
                            upcoming.length, avgRating, reviews.length),
                        const SizedBox(height: 24),
                        if (upcoming.isNotEmpty) ...[
                          _buildSectionHeader(
                              'UPCOMING COURSES', '${upcoming.length}'),
                          const SizedBox(height: 12),
                          _buildUpcomingCourses(upcoming, provider),
                          const SizedBox(height: 24),
                        ],
                        if (reviews.isNotEmpty) ...[
                          _buildSectionHeader(
                              'REVIEWS SUMMARY', '${reviews.length}'),
                          const SizedBox(height: 12),
                          _buildReviewsSummary(
                              avgRating, reviews.length, provider),
                          const SizedBox(height: 24),
                        ],
                        _buildMembersHeader(assigned, filtered),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
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
          // Avatar chip
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
          // ← CHANGED: static icon replaced with tappable NotificationBell
          const NotificationBell(),
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
          Expanded(
            child: _SmallStatCard(
              label: 'ASSIGNED',
              value: '$memberCount',
              icon: Icons.people_alt_rounded,
              color: _kOrange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SmallStatCard(
              label: 'UPCOMING',
              value: '$upcomingCount',
              icon: Icons.event_rounded,
              color: _kGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SmallStatCard(
              label: 'AVG RATING',
              value: reviewCount == 0
                  ? '—'
                  : avgRating.toStringAsFixed(1),
              icon: Icons.star_rounded,
              color: const Color(0xFFF39C12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String badge) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _kGrey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _kOrange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _kWhite),
            ),
          ),
        ],
      ),
    );
  }

  // ── Upcoming courses ──────────────────────────────────────────────────────
  Widget _buildUpcomingCourses(List<Course> courses, CoachProvider provider) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: courses.length,
        itemBuilder: (_, i) {
          final course = courses[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CourseDetailScreen(course: course),
              ),
            ),
            child: Container(
              width: 180,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD44820), Color(0xFF2D3142)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _kWhite,
                        fontWeight: FontWeight.w800,
                        fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('EEE, d MMM').format(course.dateTime),
                    style: TextStyle(
                        color: _kWhite.withOpacity(0.8), fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people_outline,
                          size: 11, color: _kWhite.withOpacity(0.7)),
                      const SizedBox(width: 3),
                      Text(
                        '${course.maxParticipants - course.spotsRemaining}/${course.maxParticipants}',
                        style: TextStyle(
                            color: _kWhite.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
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
      double avg, int count, CoachProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF39C12).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.star_rounded,
                  color: Color(0xFFF39C12), size: 28),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  avg.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: _kNavy,
                      height: 1),
                ),
                Text(
                  '$count review${count == 1 ? '' : 's'} from members',
                  style: const TextStyle(fontSize: 12, color: _kGrey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Members header + search ───────────────────────────────────────────────
  Widget _buildMembersHeader(
      List<Membre> all, List<Membre> filtered) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ASSIGNED MEMBERS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _kGrey,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              if (all.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kOrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${all.length}',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _kWhite),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (all.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: _kWhite,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search members…',
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
      ),
    );
  }

  // ── Members sliver list ───────────────────────────────────────────────────
  Widget _buildMembersSliver(CoachProvider provider, List<Membre> all,
      List<Membre> filtered) {
    if (provider.membersLoading && all.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
              child: CircularProgressIndicator(color: _kOrange)),
        ),
      );
    }
    if (provider.membersError != null && all.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline,
                    size: 40, color: _kOrange),
                const SizedBox(height: 8),
                const Text('Failed to load members'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: provider.loadAssignedMembers,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kOrange),
                  child: const Text('Retry',
                      style: TextStyle(color: _kWhite)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (all.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.people_outline,
                    size: 48, color: _kGrey),
                SizedBox(height: 8),
                Text(
                  'No assigned members yet',
                  style: TextStyle(
                      color: _kGrey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text(
              'No results for "$_query"',
              style: const TextStyle(
                  color: _kGrey, fontWeight: FontWeight.w600),
            ),
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
    final user       = membre.user;
    final colorIndex = user.fullName.hashCode.abs() % _avatarColors.length;
    final joinDate   = membre.joinDate != null
        ? DateFormat('d MMM yyyy').format(membre.joinDate!)
        : 'Unknown';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MemberDetailScreen(membre: membre)),
      ),
      child: Container(
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
                            style:
                                const TextStyle(fontSize: 10, color: _kGrey),
                          ),
                        ),
                        const Text(' · ',
                            style:
                                TextStyle(color: _kGrey, fontSize: 10)),
                      ],
                      Text('Joined $joinDate',
                          style:
                              const TextStyle(fontSize: 10, color: _kGrey)),
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
            // Chevron
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFD1B8A8), size: 20),
          ],
        ),
      ),
    );
  }
}