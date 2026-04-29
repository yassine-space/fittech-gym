import 'package:mobile/core/models/user_model.dart';

/// Dart model matching the backend `MembreSerializer` response.
///
/// Fields: id, user (nested), date_of_birth, health_goal,
/// medical_restrictions, join_date.
class Membre {
  final String id;
  final UserModel user;
  final DateTime? dateOfBirth;
  final String? healthGoal;
  final String? medicalRestrictions;
  final DateTime? joinDate;

  const Membre({
    required this.id,
    required this.user,
    this.dateOfBirth,
    this.healthGoal,
    this.medicalRestrictions,
    this.joinDate,
  });

  factory Membre.fromJson(Map<String, dynamic> json) {
    return Membre(
      id: json['id'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'])
          : null,
      healthGoal: json['health_goal'],
      medicalRestrictions: json['medical_restrictions'],
      joinDate: json['join_date'] != null
          ? DateTime.tryParse(json['join_date'])
          : null,
    );
  }
}
