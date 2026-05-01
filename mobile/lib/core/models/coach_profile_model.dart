import 'package:mobile/core/models/user_model.dart';

/// Dart model matching the backend `CoachSerializer` response.
///
/// Fields: id, user (nested), specialties, biography,
/// years_of_experience, is_active.
class CoachProfile {
  final String id;
  final UserModel user;
  final String? specialties;
  final String? biography;
  final int yearsOfExperience;
  final bool isActive;

  const CoachProfile({
    required this.id,
    required this.user,
    this.specialties,
    this.biography,
    this.yearsOfExperience = 0,
    this.isActive = false,
  });

  factory CoachProfile.fromJson(Map<String, dynamic> json) {
    return CoachProfile(
      id: json['id'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
      specialties: json['specialties'],
      biography: json['biography'],
      yearsOfExperience: json['years_of_experience'] ?? 0,
      isActive: json['is_active'] ?? false,
    );
  }

  /// Returns specialties as a list (backend stores as comma-separated string).
  List<String> get specialtiesList {
    if (specialties == null || specialties!.isEmpty) return [];
    return specialties!.split(',').map((s) => s.trim()).toList();
  }
}
