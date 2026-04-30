// ─── Models ──────────────────────────────────────────────────────────────────
class Course {
  final String id;
  final String coachId;
  final String title;
  final String description;
  final String level;
  final int maxParticipants;
  final int spotsRemaining;
  final int durationMinutes;
  final DateTime dateTime;

  const Course({
    required this.id,
    required this.coachId,
    required this.title,
    required this.description,
    required this.level,
    required this.maxParticipants,
    required this.spotsRemaining,
    required this.durationMinutes,
    required this.dateTime,
  });

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: j['id'],
        coachId: j['coach'] ?? '',
        title: j['title'],
        description: j['description'] ?? '',
        level: j['level_required'] ?? 'beginner',
        maxParticipants: j['max_participants'],
        spotsRemaining: j['spots_remaining'] ?? j['max_participants'],
        durationMinutes: j['duration_minutes'],
        dateTime: DateTime.parse(j['date_time']),
      );

  bool get isFull => spotsRemaining <= 0;
}
