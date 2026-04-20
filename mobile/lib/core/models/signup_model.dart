// signup_model.dart

enum UserRole { member, coach }

class SignupData {
  final String first_name;
  final String last_name;
  final String email;
  final String password;
  final String phone;
  final UserRole? role;
  final List<String> goals;
  final List<String> specialties;
  final String? croppedImagePath;

  const SignupData({
    this.first_name = '',
    this.last_name = '',
    this.email = '',
    this.password = '',
    this.phone = '',
    this.role,
    this.goals = const [],
    this.specialties = const [],
    this.croppedImagePath,
  });


  SignupData copyWith({
    String? first_name,
    String? last_name,
    String? email,
    String? password,
    String? phone,
    UserRole? role,
    List<String>? goals,
    List<String>? specialties,
    String? croppedImagePath,
    bool clearImage = false,
    bool clearRole = false,
  }) {
    return SignupData(
      first_name:           first_name      ?? this.first_name,
      last_name:              last_name         ?? this.last_name,
      email:            email       ?? this.email,
      password:         password    ?? this.password,
      phone:            phone       ?? this.phone,
      role:             clearRole   ? null : (role ?? this.role),
      goals:            goals       ?? this.goals,
      specialties:      specialties ?? this.specialties,
      croppedImagePath: clearImage  ? null : (croppedImagePath ?? this.croppedImagePath),
    );
  }
}