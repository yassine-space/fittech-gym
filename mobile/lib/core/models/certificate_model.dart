class CoachCertificate {
  final String id;
  final String coachId;
  final String title;
  final String issuingOrganization;
  final DateTime issueDate;
  final String? fileUrl;
  final DateTime createdAt;

  CoachCertificate({
    required this.id,
    required this.coachId,
    required this.title,
    required this.issuingOrganization,
    required this.issueDate,
    this.fileUrl,
    required this.createdAt,
  });

  factory CoachCertificate.fromJson(Map<String, dynamic> j) => CoachCertificate(
        id: j['id'],
        coachId: j['coach'] is Map ? j['coach']['id'] : j['coach'],
        title: j['title'],
        issuingOrganization: j['issuing_organization'],
        issueDate: DateTime.parse(j['issue_date']),
        fileUrl: j['file'],
        createdAt: DateTime.parse(j['created_at']),
      );
}