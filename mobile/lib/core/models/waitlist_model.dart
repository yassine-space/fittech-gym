class CourseWaitlist {
  final String id;
  final String courseId;
  final String membreId;
  final int position;
  final DateTime createdAt;

  CourseWaitlist({
    required this.id,
    required this.courseId,
    required this.membreId,
    required this.position,
    required this.createdAt,
  });

  factory CourseWaitlist.fromJson(Map<String, dynamic> j) => CourseWaitlist(
        id: j['id'],
        courseId: j['course'] is Map ? j['course']['id'] : j['course'],
        membreId: j['membre'] is Map ? j['membre']['id'] : j['membre'],
        position: j['position'],
        createdAt: DateTime.parse(j['created_at']),
      );
}