class CourseReservation {
  final String id;
  final String courseId;
  final String membreId;
  final String reservationStatus; // confirmed | cancelled | attended | no_show
  final DateTime reservationDate;

  CourseReservation({
    required this.id,
    required this.courseId,
    required this.membreId,
    required this.reservationStatus,
    required this.reservationDate,
  });

  factory CourseReservation.fromJson(Map<String, dynamic> j) => CourseReservation(
        id: j['id'],
        courseId: j['course'] is Map ? j['course']['id'] : j['course'],
        membreId: j['membre'] is Map ? j['membre']['id'] : j['membre'],
        reservationStatus: j['reservation_status'],
        reservationDate: DateTime.parse(j['reservation_date']),
      );
}