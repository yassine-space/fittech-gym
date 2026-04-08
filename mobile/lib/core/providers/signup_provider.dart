// signup_provider.dart

import 'package:flutter/foundation.dart';
import 'package:mobile/core/models/signup_model.dart';
/// Manages all mutable state for the multi-step signup flow.
///
/// ## Image handling
/// Only local file paths are stored here. The actual network upload must be
/// done with `multipart/form-data` after the user completes the flow.
/// See [SignupData.croppedImagePath] for a ready-to-use snippet.
class SignupProvider extends ChangeNotifier {
  SignupData _data = const SignupData();

  SignupData get data => _data;

  // ─── Text fields ────────────────────────────────────────────────────────────

  void updatePrenom(String value) {
    _data = _data.copyWith(prenom: value.trim());
    notifyListeners();
  }

  void updateNom(String value) {
    _data = _data.copyWith(nom: value.trim());
    notifyListeners();
  }

  void updateEmail(String value) {
    _data = _data.copyWith(email: value.trim());
    notifyListeners();
  }

  void updatePassword(String value) {
    _data = _data.copyWith(password: value);
    notifyListeners();
  }

  void updatePhone(String value) {
    _data = _data.copyWith(phone: value.trim());
    notifyListeners();
  }

  // ─── Role ───────────────────────────────────────────────────────────────────

  /// Converts the legacy int representation (0 = member, 1 = coach) used in
  /// Step1 to a [UserRole] and resets role-specific lists so stale data
  /// never leaks into the API payload.
  void updateRoleFromIndex(int index) {
    updateRole(index == 0 ? UserRole.member : UserRole.coach);
  }

  /// Sets role and clears the previous role's list.
  void updateRole(UserRole role) {
    _data = _data.copyWith(
      role: role,
      goals: const [],
      specialties: const [],
    );
    notifyListeners();
  }

  // ─── Goals (Member) ─────────────────────────────────────────────────────────

  void updateGoals(List<String> goals) {
    _data = _data.copyWith(goals: List<String>.from(goals));
    notifyListeners();
  }

  void toggleGoal(String goal) {
    final updated = List<String>.from(_data.goals);
    updated.contains(goal) ? updated.remove(goal) : updated.add(goal);
    _data = _data.copyWith(goals: updated);
    notifyListeners();
  }

  // ─── Specialties (Coach) ────────────────────────────────────────────────────

  void updateSpecialties(List<String> specialties) {
    _data = _data.copyWith(specialties: List<String>.from(specialties));
    notifyListeners();
  }

  void toggleSpecialty(String specialty) {
    final updated = List<String>.from(_data.specialties);
    updated.contains(specialty)
        ? updated.remove(specialty)
        : updated.add(specialty);
    _data = _data.copyWith(specialties: updated);
    notifyListeners();
  }

  // ─── Profile image ──────────────────────────────────────────────────────────

  /// Stores both the original picked path and the cropped path together so
  /// Step3 can restore its drag-crop state on back-navigation.
  void updateProfileImages({
    required String original,
    required String cropped,
  }) {
    _data = _data.copyWith(
      originalImagePath: original,
      croppedImagePath: cropped,
    );
    notifyListeners();
  }

  /// Clears both image paths (e.g. user removes photo before submitting).
  void clearProfileImage() {
    _data = _data.copyWith(clearImages: true);
    notifyListeners();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  bool get hasRole => _data.role != null;
  bool get isMember => _data.role == UserRole.member;
  bool get isCoach => _data.role == UserRole.coach;

  bool get isBasicInfoComplete =>
      _data.prenom.isNotEmpty &&
      _data.nom.isNotEmpty &&
      _data.email.isNotEmpty &&
      _data.password.isNotEmpty &&
      _data.role != null;

  // ─── Reset ──────────────────────────────────────────────────────────────────

  void reset() {
    _data = const SignupData();
    notifyListeners();
  }
}