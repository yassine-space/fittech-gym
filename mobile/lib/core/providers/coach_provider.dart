import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/models/coach_profile_model.dart';
import 'package:mobile/core/models/membre_model.dart';
import 'package:mobile/core/models/course.dart';
import 'package:mobile/core/models/reservation_model.dart';
import 'package:mobile/core/models/review_model.dart';
import 'package:mobile/core/models/certificate_model.dart';
import 'package:mobile/core/models/waitlist_model.dart';
import 'package:mobile/core/services/coach_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CoachProvider
// Handles all state that the coach-facing app needs.
// ─────────────────────────────────────────────────────────────────────────────
class CoachProvider extends ChangeNotifier {
  final CoachService _api;
  CoachProvider(this._api);

  // ── Profile ────────────────────────────────────────────────────────────────
  CoachProfile? _profile;
  bool profileLoading = false;
  String? profileError;

  CoachProfile? get profile => _profile;

  Future<void> loadProfile() async {
    profileLoading = true;
    profileError = null;
    notifyListeners();
    try {
      // ✅ USING THE SERVICE METHOD
      _profile = await _api.getMyProfile();
    } catch (e) {
      profileError = e.toString();
    } finally {
      profileLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCoachProfile({
    String? specialties,
    String? biography,
    int? yearsOfExperience,
  }) async {
    await _api.updateMyProfile({
      'specialties': ?specialties,
      'biography': ?biography,
      'years_of_experience': ?yearsOfExperience,
    });
    await loadProfile();
  }

  Future<void> updateUserInfo({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    await _api.updateMyUser({
      'first_name': ?firstName,
      'last_name': ?lastName,
      'phone': ?phone,
    });
    await loadProfile();
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPassword2,
    required String refreshToken, // Note: CoachService might not need this if it uses AuthHolder internally
  }) async {
    // ✅ USING THE SERVICE METHOD
    await _api.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      newPassword2: newPassword2,
    );
  }

  Future<void> logout() async {
    // ✅ USING THE SERVICE METHOD
    try {
      await _api.logout();
    } catch (_) {}
    
    _profile = null;
    _members = [];
    _courses = [];
    _reviews = [];
    _certificates = [];
    notifyListeners();
  }

  // ── Members (read-only for coach) ──────────────────────────────────────────
  List<Membre> _members = [];
  bool membersLoading = false;
  String? membersError;

  List<Membre> get members => _members;

  Future<void> loadMembers() async {
    membersLoading = true;
    membersError = null;
    notifyListeners();
    try {
      // ✅ USING THE SERVICE METHOD
      _members = await _api.getMembers();
    } catch (e) {
      membersError = e.toString();
    } finally {
      membersLoading = false;
      notifyListeners();
    }
  }

  // ── Courses ────────────────────────────────────────────────────────────────
  List<Course> _courses = [];
  bool coursesLoading = false;
  String? coursesError;

  List<Course> get courses => _courses;

  List<Course> get myCourses {
    if (_profile == null) return _courses;
    return _courses.where((c) => c.coachId == _profile!.id).toList();
  }

  List<Course> get upcomingCourses {
    final now = DateTime.now();
    return myCourses.where((c) => c.dateTime.isAfter(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Course> get endedCourses {
    final now = DateTime.now();
    return myCourses.where((c) => c.dateTime.isBefore(now)).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  Future<void> loadCourses() async {
    coursesLoading = true;
    coursesError = null;
    notifyListeners();
    try {
      // ✅ USING THE SERVICE METHOD
      _courses = await _api.getCourses();
    } catch (e) {
      coursesError = e.toString();
    } finally {
      coursesLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCourse({
    required String title,
    required String description,
    required String level,
    required DateTime dateTime,
    required int durationMinutes,
    required int maxParticipants,
  }) async {
    if (_profile == null) return;
    
    // ✅ USING THE SERVICE METHOD
    await _api.createCourse(
      title: title,
      description: description,
      level: level,
      dateTime: dateTime,
      durationMinutes: durationMinutes,
      maxParticipants: maxParticipants,
      coachProfileId: _profile!.id,
    );
    await loadCourses();
  }

  Future<void> deleteCourse(String courseId) async {
    await _api.deleteCourse(courseId);
    await loadCourses();
  }

  Future<void> updateCourse(
    String courseId, {
    required String title,
    required String description,
    required String level,
    required DateTime dateTime,
    required int durationMinutes,
    required int maxParticipants,
  }) async {
    if (_profile == null) return;
    await _api.updateCourse(courseId, {
      'title': title,
      'description': description,
      'level_required': level,
      'date_time': dateTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'max_participants': maxParticipants,
      'coach': _profile!.id,
    });
    await loadCourses();
  }

  // ── Reviews ────────────────────────────────────────────────────────────────
  List<CoachReview> _reviews = [];
  bool reviewsLoading = false;
  String? reviewsError;

  List<CoachReview> get reviews => _reviews;

  double get averageRating {
    if (_reviews.isEmpty) return 0.0;
    final sum = _reviews.fold<int>(0, (acc, r) => acc + r.rating);
    return sum / _reviews.length;
  }

  int reviewCountForStar(int star) =>
      _reviews.where((r) => r.rating == star).length;

  Future<void> loadReviews() async {
    if (_profile == null) return;
    reviewsLoading = true;
    reviewsError = null;
    notifyListeners();
    try {
      // ✅ USING THE SERVICE METHOD
      final rawData = await _api.getReviews(_profile!.id);
      _reviews = rawData
          .map((e) => CoachReview.fromJson(e))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      reviewsError = e.toString();
    } finally {
      reviewsLoading = false;
      notifyListeners();
    }
  }

  // ── Certificates ───────────────────────────────────────────────────────────
  List<CoachCertificate> _certificates = [];
  bool certificatesLoading = false;
  String? certificatesError;

  List<CoachCertificate> get certificates => _certificates;

  Future<void> loadCertificates() async {
    if (_profile == null) return;
    certificatesLoading = true;
    certificatesError = null;
    notifyListeners();
    try {
      // ✅ USING THE SERVICE METHOD
      final rawData = await _api.getCertificates(_profile!.id);
      _certificates = rawData
          .map((e) => CoachCertificate.fromJson(e))
          .toList()
        ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
    } catch (e) {
      certificatesError = e.toString();
    } finally {
      certificatesLoading = false;
      notifyListeners();
    }
  }

// Make sure to import 'package:file_picker/file_picker.dart'; at the top of coach_provider.dart

  Future<void> uploadCertificate({
    required String title,
    required String issuingOrganization,
    required DateTime issueDate,
    required PlatformFile file, // ✅ Changed from String filePath
  }) async {
    if (_profile == null) return;
    
    await _api.addCertificate(
      coachId: _profile!.id,
      title: title,
      issuingOrganization: issuingOrganization,
      issueDate: '${issueDate.year}-${issueDate.month.toString().padLeft(2, '0')}-${issueDate.day.toString().padLeft(2, '0')}',
      file: file, // ✅ Pass the PlatformFile to the API service
    );
    await loadCertificates();
  }
  Future<void> deleteCertificate(String certId) async {
    if (_profile == null) return;
    
    // ✅ USING THE SERVICE METHOD
    await _api.deleteCertificate(_profile!.id, certId);
    await loadCertificates();
  }
  // ── Reservations ─────────────────────────────────────────────────────────
  List<CourseReservation> _reservations = [];
  bool reservationsLoading = false;
  String? reservationsError;

  List<CourseReservation> get reservations => _reservations;

  Future<void> loadReservations() async {
    reservationsLoading = true;
    reservationsError = null;
    notifyListeners();
    try {
      _reservations = await _api.getReservations();
    } catch (e) {
      reservationsError = e.toString();
    } finally {
      reservationsLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateReservationStatus(String reservationId, String status) async {
    await _api.updateReservationStatus(reservationId, status);
    await loadReservations();
  }

  // ── Waitlist ─────────────────────────────────────────────────────────────
  List<CourseWaitlist> _waitlist = [];
  bool waitlistLoading = false;
  String? waitlistError;

  List<CourseWaitlist> get waitlist => _waitlist;

  Future<void> loadWaitlist() async {
    waitlistLoading = true;
    waitlistError = null;
    notifyListeners();
    try {
      _waitlist = await _api.getWaitlist();
    } catch (e) {
      waitlistError = e.toString();
    } finally {
      waitlistLoading = false;
      notifyListeners();
    }
  }

  // ── Assigned Members ──────────────────────────────────────────────────────
  List<Membre> _assignedMembers = [];
  bool assignedMembersLoading = false;
  String? assignedMembersError;

  List<Membre> get assignedMembers => _assignedMembers;

  Future<void> loadAssignedMembers() async {
    assignedMembersLoading = true;
    assignedMembersError = null;
    notifyListeners();
    try {
      _assignedMembers = await _api.getAssignedMembers();
    } catch (e) {
      assignedMembersError = e.toString();
    } finally {
      assignedMembersLoading = false;
      notifyListeners();
    }
  }
}