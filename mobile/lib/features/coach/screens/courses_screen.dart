import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFD44820);
const _kNavy = Color(0xFF2D3142);
const _kOrangeSoft = Color(0xFFFAEDE8);
const _kNavySoft = Color(0xFFEEEFF3);
const _kGrey = Color(0xFF8A8FA8);
const _kBg = Color(0xFFF7F7FB);

const String _baseUrl = 'http://127.0.0.1:8000/'; // 🔁 replace with your API base URL

// ─── Models ──────────────────────────────────────────────────────────────────
class Course {
  final String id;
  final String title;
  final String description;
  final String level;
  final int maxParticipants;
  final int spotsRemaining;
  final int durationMinutes;
  final DateTime dateTime;
  final String coachName;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.maxParticipants,
    required this.spotsRemaining,
    required this.durationMinutes,
    required this.dateTime,
    required this.coachName,
  });

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: j['id'],
        title: j['title'],
        description: j['description'] ?? '',
        level: j['level_required'] ?? 'beginner',
        maxParticipants: j['max_participants'],
        spotsRemaining: j['spots_remaining'] ?? j['max_participants'],
        durationMinutes: j['duration_minutes'],
        dateTime: DateTime.parse(j['date_time']),
        coachName: j['coach_name'] ?? 'Coach',
      );

  bool get isFull => spotsRemaining <= 0;
}

// ─── API Service ─────────────────────────────────────────────────────────────
class CourseApiService {
  final String token;
  CourseApiService(this.token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<Course>> fetchCourses() async {
    final res = await http.get(Uri.parse('$_baseUrl/courses/'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Course.fromJson(e)).toList();
    }
    throw Exception('Failed to load courses');
  }

  Future<Map<String, dynamic>> reserveCourse(String courseId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/reservations/'),
      headers: _headers,
      body: jsonEncode({'course': courseId}),
    );
    return {'status': res.statusCode, 'body': jsonDecode(res.body)};
  }

  Future<Map<String, dynamic>> joinWaitlist(String courseId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/waitlist/'),
      headers: _headers,
      body: jsonEncode({'course': courseId}),
    );
    return {'status': res.statusCode, 'body': jsonDecode(res.body)};
  }
}

// ─── Main Screen ─────────────────────────────────────────────────────────────
class CoursesScreen extends StatefulWidget {
  final String token;
  final String userRole; // 'membre', 'coach', 'admin'

  const CoursesScreen({super.key, required this.token, required this.userRole});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with SingleTickerProviderStateMixin {
  late final CourseApiService _api;
  late final TabController _tabController;

  List<Course> _courses = [];
  bool _loading = true;
  String? _error;
  String _selectedLevel = 'all';

  static const _levels = ['all', 'beginner', 'intermediate', 'advanced'];

  @override
  void initState() {
    super.initState();
    _api = CourseApiService(widget.token);
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final courses = await _api.fetchCourses();
      setState(() { _courses = courses; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Course> get _filtered {
    final now = DateTime.now();
    final upcoming = _courses.where((c) => c.dateTime.isAfter(now)).toList();
    if (_selectedLevel == 'all') return upcoming;
    return upcoming.where((c) => c.level == _selectedLevel).toList();
  }

  List<Course> get _past {
    final now = DateTime.now();
    return _courses.where((c) => c.dateTime.isBefore(now)).toList();
  }

  Future<void> _onBook(Course course) async {
    final isFull = course.isFull;
    final action = isFull ? 'Join Waitlist' : 'Book';
    final confirmed = await _showConfirmDialog(course, action);
    if (!confirmed) return;

    try {
      final result = isFull
          ? await _api.joinWaitlist(course.id)
          : await _api.reserveCourse(course.id);

      final ok = result['status'] == 200 || result['status'] == 201;
      _showSnack(
        ok
            ? (isFull ? '✅ Added to waitlist!' : '✅ Course booked!')
            : '❌ ${result['body']['detail'] ?? 'Something went wrong'}',
        ok ? _kOrange : Colors.red,
      );
      if (ok) _load();
    } catch (_) {
      _showSnack('❌ Network error', Colors.red);
    }
  }

  Future<bool> _showConfirmDialog(Course course, String action) async {
    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _ConfirmSheet(course: course, action: action),
        ) ??
        false;
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildLevelFilter(),
            _buildTabs(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: widget.userRole != 'membre'
          ? FloatingActionButton.extended(
              onPressed: () => _showSnack('Create course — coming soon', _kNavy),
              backgroundColor: _kOrange,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Course',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Training', style: TextStyle(fontSize: 13, color: _kGrey, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Courses', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _kNavy, height: 1)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: _kNavy.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.refresh_rounded, color: _kNavy, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelFilter() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: _levels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final level = _levels[i];
          final selected = _selectedLevel == level;
          return GestureDetector(
            onTap: () => setState(() => _selectedLevel = level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? _kOrange : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? _kOrange : Colors.transparent),
                boxShadow: selected
                    ? [BoxShadow(color: _kOrange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
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

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: _kNavy.withOpacity(0.06), blurRadius: 6)],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _kNavy,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: _kGrey,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        padding: const EdgeInsets.all(4),
        tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past')],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: _kOrange));
    }
    if (_error != null) {
      return _buildError();
    }
    return TabBarView(
      controller: _tabController,
      children: [
        _buildList(_filtered, upcoming: true),
        _buildList(_past, upcoming: false),
      ],
    );
  }

  Widget _buildList(List<Course> courses, {required bool upcoming}) {
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center_rounded, size: 56, color: _kOrange.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('No ${upcoming ? 'upcoming' : 'past'} courses',
                style: TextStyle(color: _kGrey, fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _kOrange,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        itemCount: courses.length,
        itemBuilder: (_, i) => _CourseCard(
          course: courses[i],
          upcoming: upcoming,
          canBook: upcoming && widget.userRole == 'membre',
          onBook: () => _onBook(courses[i]),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: _kOrange.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text('Connection error', style: TextStyle(color: _kNavy, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Check your internet connection', style: TextStyle(color: _kGrey, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(backgroundColor: _kOrange, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }
}

// ─── Course Card ─────────────────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final Course course;
  final bool upcoming;
  final bool canBook;
  final VoidCallback onBook;

  const _CourseCard({
    required this.course,
    required this.upcoming,
    required this.canBook,
    required this.onBook,
  });

  Color get _levelColor => switch (course.level) {
        'beginner' => const Color(0xFF27AE60),
        'intermediate' => _kOrange,
        'advanced' => const Color(0xFFE74C3C),
        _ => _kGrey,
      };

  @override
  Widget build(BuildContext context) {
    final pct = course.maxParticipants > 0
        ? (course.maxParticipants - course.spotsRemaining) / course.maxParticipants
        : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _kNavy.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent bar
          Container(
            height: 5,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(colors: [_kOrange, _kNavy]),
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
                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _levelColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        course.level[0].toUpperCase() + course.level.substring(1),
                        style: TextStyle(fontSize: 11, color: _levelColor, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (course.isFull)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('FULL', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w800)),
                      ),
                    const Spacer(),
                    // Duration chip
                    Row(children: [
                      Icon(Icons.timer_outlined, size: 14, color: _kGrey),
                      const SizedBox(width: 4),
                      Text('${course.durationMinutes}min', style: TextStyle(fontSize: 12, color: _kGrey, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ),

                const SizedBox(height: 10),

                // Title
                Text(course.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kNavy, height: 1.2)),
                const SizedBox(height: 4),

                // Coach
                Row(children: [
                  Icon(Icons.person_outline_rounded, size: 14, color: _kOrange),
                  const SizedBox(width: 4),
                  Text(course.coachName, style: TextStyle(fontSize: 12, color: _kOrange, fontWeight: FontWeight.w600)),
                ]),

                if (course.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: _kGrey, height: 1.4)),
                ],

                const SizedBox(height: 14),

                // Date & time
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kNavySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _InfoChip(icon: Icons.calendar_today_rounded,
                          text: DateFormat('EEE, d MMM').format(course.dateTime)),
                      const SizedBox(width: 16),
                      _InfoChip(icon: Icons.access_time_rounded,
                          text: DateFormat('h:mm a').format(course.dateTime)),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Capacity bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Spots', style: TextStyle(fontSize: 12, color: _kGrey, fontWeight: FontWeight.w600)),
                        Text(
                          course.isFull ? 'Full' : '${course.spotsRemaining} left',
                          style: TextStyle(
                              fontSize: 12,
                              color: course.isFull ? Colors.red : const Color(0xFF27AE60),
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
                        backgroundColor: _kNavySoft,
                        valueColor: AlwaysStoppedAnimation(
                          pct >= 1.0 ? Colors.red : pct > 0.7 ? _kOrange : const Color(0xFF27AE60),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${course.maxParticipants - course.spotsRemaining}/${course.maxParticipants} enrolled',
                        style: TextStyle(fontSize: 11, color: _kGrey)),
                  ],
                ),

                // Book button
                if (canBook) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: course.isFull ? _kNavy : _kOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        course.isFull ? '⏳  Join Waitlist' : '⚡  Book Now',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Chip ────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: _kNavy),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(fontSize: 13, color: _kNavy, fontWeight: FontWeight.w600)),
    ]);
  }
}

// ─── Confirm Bottom Sheet ─────────────────────────────────────────────────────
class _ConfirmSheet extends StatelessWidget {
  final Course course;
  final String action;
  const _ConfirmSheet({required this.course, required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Text(action, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kNavy)),
          const SizedBox(height: 6),
          Text('Confirm your action for this course', style: TextStyle(color: _kGrey, fontSize: 14)),
          const SizedBox(height: 20),
          _SheetRow(icon: Icons.fitness_center_rounded, label: 'Course', value: course.title),
          _SheetRow(icon: Icons.calendar_today_rounded, label: 'Date',
              value: DateFormat('EEEE, d MMMM yyyy').format(course.dateTime)),
          _SheetRow(icon: Icons.access_time_rounded, label: 'Time',
              value: DateFormat('h:mm a').format(course.dateTime)),
          _SheetRow(icon: Icons.person_outline_rounded, label: 'Coach', value: course.coachName),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kNavy,
                    side: BorderSide(color: _kNavy.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(action, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SheetRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _kOrange),
          const SizedBox(width: 10),
          Text('$label: ', style: TextStyle(color: _kGrey, fontSize: 13, fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: const TextStyle(color: _kNavy, fontSize: 13, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}