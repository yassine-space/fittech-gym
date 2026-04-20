// signup_provider.dart

import 'package:flutter/foundation.dart';
import 'package:mobile/core/models/signup_model.dart';

class SignupProvider extends ChangeNotifier {

  SignupData _data = const SignupData();

  SignupData get data => _data;

  // ─── Text fields ─────────────────────────────────────────────────────────

  void updatefirst_name(String value) {
    _data = _data.copyWith(first_name: value.trim());
    notifyListeners();
  }

  void updatelast_name(String value) {
    _data = _data.copyWith(last_name: value.trim());
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

  // ─── Role ─────────────────────────────────────────────────────────────────

  void updateRoleFromIndex(int index) {
    updateRole(index == 0 ? UserRole.member : UserRole.coach);
  }

  void updateRole(UserRole role) {
    _data = _data.copyWith(
      role: role,
      goals: const [],//Reset goals to an empty list
      specialties: const [],//Reset specialties to an empty list
    );
    notifyListeners();
  }

  // ─── Goals (Member) ──────────────────────────────────────────────────────


  //Replaces all goals with a new list
  void updateGoals(List<String> goals) {
    _data = _data.copyWith(goals: List<String>.from(goals));
    notifyListeners();
  }
  
  //Toggles a single goal: adds it if not present, removes it if already selected
  //Adds OR removes a goal (like a checkbox)
  void toggleGoal(String goal) {
    final updated = List<String>.from(_data.goals);
    updated.contains(goal) ? updated.remove(goal) : updated.add(goal);
    _data = _data.copyWith(goals: updated);
    notifyListeners();
  }

  // ─── Specialties (Coach) ─────────────────────────────────────────────────

  //Replaces all Specialties with a new list
  void updateSpecialties(List<String> specialties) {
    _data = _data.copyWith(specialties: List<String>.from(specialties));
    notifyListeners();
  }


  //Adds OR removes a Specialty
  void toggleSpecialty(String specialty) {
    final updated = List<String>.from(_data.specialties);
    updated.contains(specialty)
        ? updated.remove(specialty)
        : updated.add(specialty);
    _data = _data.copyWith(specialties: updated);
    notifyListeners();
  }

  // ─── Profile image (cropped only) ────────────────────────────────────────

  /// Stores only the cropped circle image path.
  void updateCroppedImage(String croppedPath) {
    _data = _data.copyWith(croppedImagePath: croppedPath);
    notifyListeners();
  }

  /// Clears the cropped image (e.g. user removes photo before submitting).
  void clearProfileImage() {
    _data = _data.copyWith(clearImage: true);
    notifyListeners();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  bool get hasRole => _data.role != null;
  bool get isMember => _data.role == UserRole.member;
  bool get isCoach => _data.role == UserRole.coach;

  bool get isBasicInfoComplete =>
      _data.first_name.isNotEmpty &&
      _data.last_name.isNotEmpty &&
      _data.email.isNotEmpty &&
      _data.password.isNotEmpty &&
      _data.role != null;

  // ─── Reset ───────────────────────────────────────────────────────────────

  void reset() {
    _data = const SignupData();
    notifyListeners();
  }
}