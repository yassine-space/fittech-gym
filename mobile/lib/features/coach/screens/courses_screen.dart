// lib/features/coach/screens/courses_screen.dart
//
// Changes from previous version:
//   • _CoachCourseCard: tapping anywhere on the card navigates to
//     CourseDetailScreen (Fix #2).
//   • Header: refresh icon is now paired with a NotificationBell (Fix #3).
//   • Everything else is identical to the uploaded version.
//
// Place this file at:  lib/features/coach/screens/courses_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/models/course.dart';
import 'package:mobile/core/providers/coach_provider.dart';
import 'package:mobile/core/widgets/notification_bell.dart';               // ← NEW
import 'package:mobile/features/coach/screens/course_detail_screen.dart'; // ← NEW

// ─── Constants ────────────────────────────────────────────────────────────────
const _kOrange     = Color(0xFFD44820);
const _kNavy       = Color(0xFF2D3142);
const _kOrangeSoft = Color(0xFFFAEDE8);
const _kNavySoft   = Color(0xFFEEEFF3);
const _kGrey       = Color(0xFF8A8FA8);
const _kBg         = Color(0xFFF7F7FB);
const _kGreen      = Color(0xFF27AE60);
const _kRed        = Color(0xFFE74C3C);

// ─── Coach Courses Screen ─────────────────────────────────────────────────────
class CoachCoursesScreen extends StatefulWidget {
  const CoachCoursesScreen({super.key});

  @override
  State<CoachCoursesScreen> createState() => _CoachCoursesScreenState();
}

class _CoachCoursesScreenState extends State<CoachCoursesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedLevel = 'all';

  static const _levels = ['all', 'beginner', 'intermediate', 'advanced'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Course> _filterByLevel(List<Course> list) {
    if (_selectedLevel == 'all') return list;
    return list.where((c) => c.level == _selectedLevel).toList();
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateCourseSheet(
        onCreated: () {
          Navigator.pop(context);
          _showSnack('✅ Course created successfully!', _kGreen);
        },
      ),
    );
  }

  Future<void> _onDelete(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Course',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: _kNavy)),
        content: Text(
          'Are you sure you want to delete "${course.title}"? This action cannot be undone.',
          style: TextStyle(color: _kGrey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _kGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await context.read<CoachProvider>().deleteCourse(course.id);
      _showSnack('🗑 Course deleted.', _kNavy);
    } catch (_) {
      _showSnack('❌ Failed to delete course.', _kRed);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoachProvider>(
      builder: (context, provider, _) {
        final upcoming = _filterByLevel(provider.upcomingCourses);
        final ended    = _filterByLevel(provider.endedCourses);
        final allMy    = provider.myCourses;

        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(provider),
                _buildStats(
                    allMy, provider.coursesLoading, provider.coursesError),
                _buildLevelFilter(),
                _buildTabs(upcoming, ended),
                Expanded(
                    child: _buildBody(provider, upcoming, ended)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreateSheet,
            backgroundColor: _kOrange,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'New Course',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(CoachProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My',
                  style: TextStyle(
                      fontSize: 13,
                      color: _kGrey,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Courses',
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: _kNavy,
                      height: 1)),
            ],
          ),
          const Spacer(),
          // Refresh
          GestureDetector(
            onTap: () => provider.loadCourses(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: _kNavy.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: _kNavy, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          // ← NEW: notification bell
          const NotificationBell(),
        ],
      ),
    );
  }

  Widget _buildStats(
      List<Course> allMy, bool loading, String? error) {
    if (loading || error != null) return const SizedBox(height: 12);
    final now           = DateTime.now();
    final upcomingCount = allMy.where((c) => c.dateTime.isAfter(now)).length;
    final endedCount    = allMy.where((c) => c.dateTime.isBefore(now)).length;
    final totalEnrolled = allMy.fold<int>(
        0, (sum, c) => sum + (c.maxParticipants - c.spotsRemaining));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          _StatCard(
              label: 'Upcoming',
              value: '$upcomingCount',
              color: _kOrange),
          const SizedBox(width: 10),
          _StatCard(label: 'Ended', value: '$endedCount', color: _kGrey),
          const SizedBox(width: 10),
          _StatCard(
              label: 'Enrolled',
              value: '$totalEnrolled',
              color: _kGreen),
        ],
      ),
    );
  }

  Widget _buildLevelFilter() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: _levels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final level    = _levels[i];
          final selected = _selectedLevel == level;
          return GestureDetector(
            onTap: () => setState(() => _selectedLevel = level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? _kOrange : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected ? _kOrange : Colors.transparent),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: _kOrange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4)
                      ],
              ),
              child: Text(
                level[0].toUpperCase() + level.substring(1),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _kGrey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabs(List<Course> upcoming, List<Course> ended) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: _kNavy.withOpacity(0.06), blurRadius: 6)
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _kNavy,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: _kGrey,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        padding: const EdgeInsets.all(4),
        tabs: [
          Tab(text: 'Upcoming (${upcoming.length})'),
          Tab(text: 'Ended (${ended.length})'),
        ],
      ),
    );
  }

  Widget _buildBody(CoachProvider provider, List<Course> upcoming,
      List<Course> ended) {
    if (provider.coursesLoading && provider.courses.isEmpty) {
      return Center(
          child: CircularProgressIndicator(color: _kOrange));
    }
    if (provider.coursesError != null && provider.courses.isEmpty) {
      return _buildError(provider);
    }
    return TabBarView(
      controller: _tabController,
      children: [
        _buildList(upcoming, isEnded: false),
        _buildList(ended, isEnded: true),
      ],
    );
  }

  Widget _buildList(List<Course> courses, {required bool isEnded}) {
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEnded
                  ? Icons.history_rounded
                  : Icons.upcoming_rounded,
              size: 56,
              color: _kOrange.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              isEnded ? 'No ended courses yet' : 'No upcoming courses',
              style: TextStyle(
                  color: _kGrey,
                  fontWeight: FontWeight.w600,
                  fontSize: 15),
            ),
            if (!isEnded) ...[
              const SizedBox(height: 8),
              Text('Tap "+ New Course" to create one',
                  style: TextStyle(
                      color: _kGrey.withOpacity(0.7), fontSize: 13)),
            ],
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () => context.read<CoachProvider>().loadCourses(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
        itemCount: courses.length,
        itemBuilder: (_, i) => _CoachCourseCard(
          course: courses[i],
          isEnded: isEnded,
          onDelete: () => _onDelete(courses[i]),
          onEdit: () => _showSnack('Edit — coming soon', _kNavy),
          // ← NEW: pass context so the card can navigate
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CourseDetailScreen(course: courses[i]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(CoachProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 56, color: _kOrange.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text('Connection error',
              style: TextStyle(
                  color: _kNavy,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 6),
          Text('Check your internet connection',
              style: TextStyle(color: _kGrey, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => provider.loadCourses(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}

// ─── Coach Course Card ────────────────────────────────────────────────────────
class _CoachCourseCard extends StatelessWidget {
  final Course course;
  final bool isEnded;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap; // ← NEW

  const _CoachCourseCard({
    required this.course,
    required this.isEnded,
    required this.onDelete,
    required this.onEdit,
    required this.onTap, // ← NEW
  });

  Color get _levelColor => switch (course.level) {
        'beginner'     => _kGreen,
        'intermediate' => _kOrange,
        'advanced'     => _kRed,
        _              => _kGrey,
      };

  @override
  Widget build(BuildContext context) {
    final enrolled =
        course.maxParticipants - course.spotsRemaining;
    final pct = course.maxParticipants > 0
        ? enrolled / course.maxParticipants
        : 1.0;

    // ← NEW: wrap the entire card in GestureDetector
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color:
              isEnded ? Colors.white.withOpacity(0.7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isEnded
              ? Border.all(color: Colors.grey.withOpacity(0.15))
              : null,
          boxShadow: [
            BoxShadow(
              color: _kNavy.withOpacity(isEnded ? 0.04 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top accent bar
            Container(
              height: 5,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
                gradient: LinearGradient(
                  colors: isEnded
                      ? [
                          _kGrey.withOpacity(0.4),
                          _kGrey.withOpacity(0.2)
                        ]
                      : [_kOrange, _kNavy],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              _levelColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          course.level[0].toUpperCase() +
                              course.level.substring(1),
                          style: TextStyle(
                              fontSize: 11,
                              color: _levelColor,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isEnded)
                        _badge('ENDED', _kGrey)
                      else if (course.isFull)
                        _badge('FULL', _kRed),
                      const Spacer(),
                      // Duration
                      Row(children: [
                        Icon(Icons.timer_outlined,
                            size: 14, color: _kGrey),
                        const SizedBox(width: 4),
                        Text('${course.durationMinutes}min',
                            style: TextStyle(
                                fontSize: 12,
                                color: _kGrey,
                                fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(width: 10),
                      // Action menu (stop tap bubbling to onTap)
                      if (!isEnded)
                        GestureDetector(
                          onTap: () {}, // absorb to prevent card nav
                          child: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') onEdit();
                              if (v == 'delete') onDelete();
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                            icon: Icon(Icons.more_vert_rounded,
                                color: _kGrey, size: 20),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Icons.edit_outlined,
                                      size: 16, color: _kNavy),
                                  SizedBox(width: 8),
                                  Text('Edit',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _kNavy)),
                                ]),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: _kRed),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _kRed)),
                                ]),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Title
                  Text(course.title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isEnded
                              ? _kNavy.withOpacity(0.6)
                              : _kNavy,
                          height: 1.2)),

                  if (course.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(course.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            color: _kGrey,
                            height: 1.4)),
                  ],

                  const SizedBox(height: 14),

                  // Date & time row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isEnded
                          ? Colors.grey.withOpacity(0.07)
                          : const Color(0xFFEEEFF3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _InfoChip(
                            icon: Icons.calendar_today_rounded,
                            text: DateFormat('EEE, d MMM')
                                .format(course.dateTime),
                            muted: isEnded),
                        const SizedBox(width: 16),
                        _InfoChip(
                            icon: Icons.access_time_rounded,
                            text: DateFormat('h:mm a')
                                .format(course.dateTime),
                            muted: isEnded),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Enrollment bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Enrollment',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _kGrey,
                                  fontWeight: FontWeight.w600)),
                          Text(
                            '$enrolled / ${course.maxParticipants}',
                            style: TextStyle(
                                fontSize: 12,
                                color: isEnded
                                    ? _kGrey
                                    : (course.isFull
                                        ? _kRed
                                        : _kGreen),
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor:
                              const Color(0xFFEEEFF3),
                          valueColor: AlwaysStoppedAnimation(
                            isEnded
                                ? _kGrey.withOpacity(0.4)
                                : (pct >= 1.0
                                    ? _kRed
                                    : pct > 0.7
                                        ? _kOrange
                                        : _kGreen),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!isEnded && course.spotsRemaining > 0)
                        Text(
                            '${course.spotsRemaining} spots remaining',
                            style: TextStyle(
                                fontSize: 11, color: _kGrey)),
                      if (isEnded)
                        Text(
                          enrolled > 0
                              ? '${(pct * 100).toStringAsFixed(0)}% capacity reached'
                              : 'No participants',
                          style: TextStyle(
                              fontSize: 11, color: _kGrey),
                        ),
                    ],
                  ),

                  // ← NEW: tap hint
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('View details',
                          style: TextStyle(
                              fontSize: 11,
                              color: _kOrange,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 13, color: _kOrange),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w800)),
      );
}

// ─── Info Chip ────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool muted;
  const _InfoChip(
      {required this.icon,
      required this.text,
      this.muted = false});

  @override
  Widget build(BuildContext context) {
    final color = muted ? _kGrey : _kNavy;
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 5),
      Text(text,
          style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600)),
    ]);
  }
}

// ─── Create Course Bottom Sheet ───────────────────────────────────────────────
// (unchanged from the original — included in full so the file is self-contained)
class _CreateCourseSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateCourseSheet({required this.onCreated});

  @override
  State<_CreateCourseSheet> createState() => _CreateCourseSheetState();
}

class _CreateCourseSheetState extends State<_CreateCourseSheet> {
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _maxCtrl      = TextEditingController(text: '10');
  final _durationCtrl = TextEditingController(text: '60');

  String _level       = 'beginner';
  DateTime _date      = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time     = const TimeOfDay(hour: 9, minute: 0);
  bool _submitting    = false;

  static const _levels = ['beginner', 'intermediate', 'advanced'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _maxCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.light(primary: _kOrange)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.light(primary: _kOrange)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _showError('Please enter a course title.');
      return;
    }
    final maxP = int.tryParse(_maxCtrl.text.trim());
    if (maxP == null || maxP < 1) {
      _showError('Enter a valid max participants number.');
      return;
    }
    final duration = int.tryParse(_durationCtrl.text.trim());
    if (duration == null || duration < 1) {
      _showError('Enter a valid duration in minutes.');
      return;
    }

    final dateTime = DateTime(
        _date.year, _date.month, _date.day, _time.hour, _time.minute);

    setState(() => _submitting = true);
    try {
      await context.read<CoachProvider>().createCourse(
            title: title,
            description: _descCtrl.text.trim(),
            level: _level,
            dateTime: dateTime,
            durationMinutes: duration,
            maxParticipants: maxP,
          );
      widget.onCreated();
    } catch (_) {
      setState(() => _submitting = false);
      _showError('Failed to create course. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: _kRed,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kOrangeSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: _kOrange, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create Course',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _kNavy)),
                    Text('Fill in the details below',
                        style:
                            TextStyle(fontSize: 13, color: _kGrey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _FieldLabel('Course Title'),
            const SizedBox(height: 6),
            _InputField(
                controller: _titleCtrl,
                hint: 'e.g. Morning HIIT Blast',
                icon: Icons.fitness_center_rounded),
            const SizedBox(height: 16),
            _FieldLabel('Description (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'What will participants do in this course?',
                hintStyle: TextStyle(
                    color: _kGrey.withOpacity(0.7), fontSize: 13),
                filled: true,
                fillColor: _kBg,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel('Level'),
            const SizedBox(height: 8),
            Row(
              children: _levels.map((l) {
                final selected = _level == l;
                final color = switch (l) {
                  'beginner'     => _kGreen,
                  'intermediate' => _kOrange,
                  'advanced'     => _kRed,
                  _              => _kGrey,
                };
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _level = l),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                          right: l != 'advanced' ? 8 : 0),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withOpacity(0.12)
                            : _kBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? color
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        l[0].toUpperCase() + l.substring(1),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected ? color : _kGrey,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Date'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(children: [
                            const Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: _kOrange),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('d MMM yyyy').format(_date),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _kNavy),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Time'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(children: [
                            const Icon(Icons.access_time_rounded,
                                size: 16, color: _kOrange),
                            const SizedBox(width: 8),
                            Text(
                              _time.format(context),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _kNavy),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Duration (min)'),
                      const SizedBox(height: 6),
                      _InputField(
                          controller: _durationCtrl,
                          hint: '60',
                          icon: Icons.timer_outlined,
                          keyboardType: TextInputType.number),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Max Participants'),
                      const SizedBox(height: 6),
                      _InputField(
                          controller: _maxCtrl,
                          hint: '10',
                          icon: Icons.group_outlined,
                          keyboardType: TextInputType.number),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      _kOrange.withOpacity(0.5),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        '🚀  Create Course',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _kNavy));
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: _kGrey.withOpacity(0.7), fontSize: 13),
        prefixIcon: Icon(icon, color: _kOrange, size: 18),
        filled: true,
        fillColor: _kBg,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}