/// Dart model matching the backend `UserSerializer` response.
///
/// Fields: id, first_name, last_name, email, phone, role,
/// profile_photo, created_at, is_active, archived_at.
class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String role;
  final String? profilePhoto;
  final DateTime? createdAt;
  final bool isActive;
  final DateTime? archivedAt;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.role,
    this.profilePhoto,
    this.createdAt,
    this.isActive = true,
    this.archivedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'membre',
      profilePhoto: json['profile_photo'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      isActive: json['is_active'] ?? true,
      archivedAt: json['archived_at'] != null
          ? DateTime.tryParse(json['archived_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
    };
  }

  /// Full display name.
  String get fullName => '$firstName $lastName';

  /// Initials for avatar (e.g. "JD").
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }
}
