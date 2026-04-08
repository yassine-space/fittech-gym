// signup_model.dart

/// Represents the two possible roles a user can register as.
enum UserRole { member, coach }

/// Holds all data collected during the multi-step signup process.
class SignupData {
  final String prenom;
  final String nom;
  final String email;
  final String password;
  final String phone;

  /// Nullable so the UI can force the user to make an explicit choice.
  final UserRole? role;

  /// Populated only when [role] == UserRole.member.
  final List<String> goals;

  /// Populated only when [role] == UserRole.coach.
  final List<String> specialties;

  /// Original (uncropped) local image path picked from gallery.
  ///
  /// Keep this so Step3 can restore the draggable crop preview when the
  /// user navigates back and forth. Never send it in a JSON payload.
  final String? originalImagePath;

  /// Cropped square image path, ready for multipart/form-data upload.
  ///
  /// Upload example (using the `http` package):
  /// ```dart
  /// final request = http.MultipartRequest('POST', uri);
  /// request.files.add(
  ///   await http.MultipartFile.fromPath('avatar', croppedImagePath!),
  /// );
  /// request.fields.addAll(
  ///   signupData.toJsonWithoutImage().map((k, v) => MapEntry(k, v.toString())),
  /// );
  /// ```
  final String? croppedImagePath;

  const SignupData({
    this.prenom = '',
    this.nom = '',
    this.email = '',
    this.password = '',
    this.phone = '',
    this.role,
    this.goals = const [],
    this.specialties = const [],
    this.originalImagePath,
    this.croppedImagePath,
  });

  SignupData copyWith({
    String? prenom,
    String? nom,
    String? email,
    String? password,
    String? phone,
    UserRole? role,
    List<String>? goals,
    List<String>? specialties,
    String? originalImagePath,
    String? croppedImagePath,
    bool clearImages = false,
    bool clearRole = false,
  }) {
    return SignupData(
      prenom: prenom ?? this.prenom,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      role: clearRole ? null : (role ?? this.role),
      goals: goals ?? this.goals,
      specialties: specialties ?? this.specialties,
      originalImagePath:
          clearImages ? null : (originalImagePath ?? this.originalImagePath),
      croppedImagePath:
          clearImages ? null : (croppedImagePath ?? this.croppedImagePath),
    );
  }

  /// Serialises the data for the API, excluding both image paths.
  /// Only the role-specific list (goals OR specialties) is included.
  Map<String, dynamic> toJsonWithoutImage() {
    if (role == null) {
      throw StateError(
          'Cannot serialise SignupData: role has not been selected.');
    }
    final json = <String, dynamic>{
      'prenom': prenom,
      'nom': nom,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role!.name, // 'member' or 'coach'
    };
    if (role == UserRole.member) {
      json['goals'] = List<String>.from(goals);
    } else {
      json['specialties'] = List<String>.from(specialties);
    }
    return json;
  }
}