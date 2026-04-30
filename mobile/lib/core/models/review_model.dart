class CoachReview {
  final String id;
  final String coachId;
  final String membreId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  CoachReview({
    required this.id,
    required this.coachId,
    required this.membreId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory CoachReview.fromJson(Map<String, dynamic> j) => CoachReview(
        id: j['id'],
        coachId: j['coach'] is Map ? j['coach']['id'] : j['coach'],
        membreId: j['membre'] is Map ? j['membre']['id'] : j['membre'],
        rating: j['rating'],
        comment: j['comment'] ?? '',
        createdAt: DateTime.parse(j['created_at']),
      );
}