import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/models/course.dart';
import 'package:mobile/core/models/membre_model.dart';
import 'package:mobile/core/models/reservation_model.dart';
import 'package:mobile/core/models/waitlist_model.dart';
import 'package:mobile/core/providers/coach_provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFD44820);
const _kNavy = Color(0xFF1C1C1C);
const _kBg = Color(0xFFF5EDE8);
const _kGrey = Color(0xFF9A7060);
const _kGreen = Color(0xFF3DB87A);
const _kRed = Color(0xFFE74C3C);
const _kAmber = Color(0xFFF39C12);
const _kWhite = Colors.white;
const _kCardBg = Color(0xFFEFDDD5);

const _kAvatarColors = [
  Color(0xFF5A3826),
  Color(0xFF7A4A30),
  Color(0xFFD4956A),
  Color(0xFF8B4513),
  Color(0xFF6B3A2A),
];

// ─── Course Detail Screen ─────────────────────────────────────────────────────
class CourseDetailScreen extends StatefulWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _updatingReservationId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<CoachProvider>();
      p.loadReservations();
      p.loadWaitlist();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Attendance actions ────────────────────────────────────────────────────
  Future<void> _markStatus(CourseReservation r, String status) async {
    setState(() => _updatingReservationId = r.id);
    try {
      await context.read<CoachProvider>().updateReservationStatus(r.id, status);
      if (mounted) {
        _snack(
          status == 'attended' ? '✅ Marked as attended' : '❌ Marked as no-show',
          status == 'attended' ? _kGreen : _kAmber,
        );
      }
    } catch (_) {
      if (mounted) _snack('Failed to update status', _kRed);
    } finally {
      if (mounted) setState(() => _updatingReservationId = null);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600, color: _kWhite)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return Consumer<CoachProvider>(
      builder: (context, provider, _) {
        final participants = provider.reservations
            .where((r) => r.courseId == course.id)
            .toList()
          ..sort((a, b) => a.reservationDate.compareTo(b.reservationDate));
        final waitlist = provider.waitlist
            .where((w) => w.courseId == course.id)
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));

        final confirmed =
            participants.where((r) => r.reservationStatus == 'confirmed').length;
        final attended =
            participants.where((r) => r.reservationStatus == 'attended').length;
        final noShow =
            participants.where((r) => r.reservationStatus == 'no_show').length;
        final cancelled =
            participants.where((r) => r.reservationStatus == 'cancelled').length;

        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: Column(
              children: [
                // ── App bar ──────────────────────────────────────────────
                _buildHeader(context, course),

                // ── Course info card ─────────────────────────────────────
                _buildCourseCard(course, confirmed + attended),

                // ── Status stats row ─────────────────────────────────────
                _buildStatusRow(confirmed, attended, noShow, cancelled),

                // ── Tab bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kWhite,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6)
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                          color: _kNavy,
                          borderRadius: BorderRadius.circular(12)),
                      labelColor: _kWhite,
                      unselectedLabelColor: _kGrey,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                      padding: const EdgeInsets.all(4),
                      tabs: [
                        Tab(text: 'Participants (${participants.length})'),
                        Tab(text: 'Waitlist (${waitlist.length})'),
                      ],
                    ),
                  ),
                ),

                // ── Tab body ─────────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildParticipantsTab(participants, provider),
                      _buildWaitlistTab(waitlist, provider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, Course course) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06), blurRadius: 6)
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: _kNavy, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _kNavy,
                      height: 1.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Course Details',
                  style: TextStyle(fontSize: 12, color: _kGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Course info card ────────────────────────────────────────────────────────
  Widget _buildCourseCard(Course course, int enrolled) {
    final pct =
        course.maxParticipants > 0 ? enrolled / course.maxParticipants : 0.0;
    final levelColor = _levelColor(course.level);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(
                  label: course.level[0].toUpperCase() +
                      course.level.substring(1),
                  color: levelColor),
              const SizedBox(width: 6),
              _Badge(
                label: '${course.durationMinutes} min',
                color: _kGrey,
                icon: Icons.timer_outlined,
              ),
              const Spacer(),
              Text(
                DateFormat('EEE, d MMM · h:mm a').format(course.dateTime),
                style: const TextStyle(
                    fontSize: 11,
                    color: _kGrey,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Enrollment',
                  style: TextStyle(
                      fontSize: 12,
                      color: _kGrey,
                      fontWeight: FontWeight.w600)),
              Text(
                '$enrolled / ${course.maxParticipants}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: pct >= 1.0
                        ? _kRed
                        : pct > 0.7
                            ? _kOrange
                            : _kGreen),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF0E0D8),
              valueColor: AlwaysStoppedAnimation(
                pct >= 1.0
                    ? _kRed
                    : pct > 0.7
                        ? _kOrange
                        : _kGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status stats ───────────────────────────────────────────────────────────
  Widget _buildStatusRow(
      int confirmed, int attended, int noShow, int cancelled) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          _MiniStat(label: 'Confirmed', count: confirmed, color: _kOrange),
          const SizedBox(width: 6),
          _MiniStat(label: 'Attended', count: attended, color: _kGreen),
          const SizedBox(width: 6),
          _MiniStat(label: 'No Show', count: noShow, color: _kAmber),
          const SizedBox(width: 6),
          _MiniStat(label: 'Cancelled', count: cancelled, color: _kGrey),
        ],
      ),
    );
  }

  // ── Participants tab ───────────────────────────────────────────────────────
  Widget _buildParticipantsTab(
      List<CourseReservation> participants, CoachProvider provider) {
    if (provider.reservationsLoading && participants.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: _kOrange));
    }
    if (participants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 56, color: _kOrange.withOpacity(0.3)),
            const SizedBox(height: 12),
            const Text('No participants yet',
                style: TextStyle(
                    color: _kGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            const SizedBox(height: 6),
            Text('Participants will appear after booking',
                style: TextStyle(color: _kGrey.withOpacity(0.7), fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () => provider.loadReservations(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        itemCount: participants.length,
        itemBuilder: (_, i) {
          final r = participants[i];
          final member = provider.members
              .where((m) => m.id == r.membreId)
              .firstOrNull;
          return _ParticipantTile(
            reservation: r,
            member: member,
            isUpdating: _updatingReservationId == r.id,
            onAttended: () => _markStatus(r, 'attended'),
            onNoShow: () => _markStatus(r, 'no_show'),
          );
        },
      ),
    );
  }

  // ── Waitlist tab ───────────────────────────────────────────────────────────
  Widget _buildWaitlistTab(
      List<CourseWaitlist> waitlist, CoachProvider provider) {
    if (provider.waitlistLoading && waitlist.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: _kOrange));
    }
    if (waitlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_outlined,
                size: 56, color: _kOrange.withOpacity(0.3)),
            const SizedBox(height: 12),
            const Text('No one on waitlist',
                style: TextStyle(
                    color: _kGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            const SizedBox(height: 6),
            Text('Waitlisted members will appear here',
                style: TextStyle(color: _kGrey.withOpacity(0.7), fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () => provider.loadWaitlist(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        itemCount: waitlist.length,
        itemBuilder: (_, i) {
          final w = waitlist[i];
          final member =
              provider.members.where((m) => m.id == w.membreId).firstOrNull;
          return _WaitlistTile(entry: w, member: member);
        },
      ),
    );
  }
}

// ─── Level Color helper ───────────────────────────────────────────────────────
Color _levelColor(String level) => switch (level) {
      'beginner' => _kGreen,
      'intermediate' => _kOrange,
      'advanced' => _kRed,
      _ => _kGrey,
    };

// ─── _Badge ───────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon!, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ─── _MiniStat ────────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _MiniStat(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── _ParticipantTile ─────────────────────────────────────────────────────────
class _ParticipantTile extends StatelessWidget {
  final CourseReservation reservation;
  final Membre? member;
  final bool isUpdating;
  final VoidCallback onAttended;
  final VoidCallback onNoShow;

  const _ParticipantTile({
    required this.reservation,
    required this.member,
    required this.isUpdating,
    required this.onAttended,
    required this.onNoShow,
  });

  Color get _statusColor => switch (reservation.reservationStatus) {
        'confirmed' => _kOrange,
        'attended' => _kGreen,
        'no_show' => _kAmber,
        'cancelled' => _kGrey,
        _ => _kGrey,
      };

  String get _statusLabel => switch (reservation.reservationStatus) {
        'confirmed' => 'Confirmed',
        'attended' => 'Attended',
        'no_show' => 'No Show',
        'cancelled' => 'Cancelled',
        _ => reservation.reservationStatus,
      };

  IconData get _statusIcon => switch (reservation.reservationStatus) {
        'confirmed' => Icons.check_circle_outline,
        'attended' => Icons.check_circle_rounded,
        'no_show' => Icons.cancel_outlined,
        'cancelled' => Icons.remove_circle_outline,
        _ => Icons.circle_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final name = member?.user.fullName ?? 'Unknown Member';
    final initials = member?.user.initials ?? '?';
    final colorIdx = name.hashCode.abs() % _kAvatarColors.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kAvatarColors[colorIdx],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _kNavy)),
                    const SizedBox(height: 2),
                    Text(
                      'Booked ${DateFormat('d MMM yyyy').format(reservation.reservationDate)}',
                      style:
                          const TextStyle(fontSize: 11, color: _kGrey),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon, size: 12, color: _statusColor),
                    const SizedBox(width: 4),
                    Text(_statusLabel,
                        style: TextStyle(
                            fontSize: 11,
                            color: _statusColor,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),

          // ── Action buttons (only for confirmed) ───────────────────────
          if (reservation.reservationStatus == 'confirmed') ...[
            const SizedBox(height: 10),
            isUpdating
                ? const Center(
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kOrange),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onAttended,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _kGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _kGreen.withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded,
                                    size: 14, color: _kGreen),
                                SizedBox(width: 4),
                                Text('Attended',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _kGreen)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: onNoShow,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _kAmber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _kAmber.withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel_outlined,
                                    size: 14, color: _kAmber),
                                SizedBox(width: 4),
                                Text('No Show',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _kAmber)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ],
      ),
    );
  }
}

// ─── _WaitlistTile ────────────────────────────────────────────────────────────
class _WaitlistTile extends StatelessWidget {
  final CourseWaitlist entry;
  final Membre? member;
  const _WaitlistTile({required this.entry, required this.member});

  @override
  Widget build(BuildContext context) {
    final name = member?.user.fullName ?? 'Unknown Member';
    final initials = member?.user.initials ?? '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          // Position badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _kOrange.withOpacity(0.1),
              shape: BoxShape.circle,
              border:
                  Border.all(color: _kOrange.withOpacity(0.3), width: 1.5),
            ),
            child: Center(
              child: Text(
                '#${entry.position}',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _kOrange),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF7A4A30),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _kNavy)),
                const SizedBox(height: 2),
                Text(
                  'Added ${DateFormat('d MMM yyyy').format(entry.createdAt)}',
                  style:
                      const TextStyle(fontSize: 11, color: _kGrey),
                ),
              ],
            ),
          ),
          // Waiting badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Waiting',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kGrey)),
          ),
        ],
      ),
    );
  }
}
