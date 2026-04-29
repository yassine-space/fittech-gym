import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/models/coach_profile_model.dart';
import 'package:mobile/core/models/course.dart';
import 'package:mobile/core/models/membre_model.dart';
import 'package:mobile/core/services/coach_service.dart';
import 'package:mobile/core/services/apiservice.dart';

/// Provider that manages all coach-related state.
///
/// Consumed by coach screens via `Provider.of<CoachProvider>(context)`.
class CoachProvider extends ChangeNotifier {
  final CoachService _service = CoachService();

  // ─── State ──────────────────────────────────────────────────────────────

  CoachProfile? _profile;
  List<Membre> _members = [];
  List<Course> _courses = [];

  bool _profileLoading = false;
  bool _membersLoading = false;
  bool _coursesLoading = false;

  String? _profileError;
  String? _membersError;
  String? _coursesError;

  // ─── Getters ────────────────────────────────────────────────────────────

  CoachProfile? get profile => _profile;
  List<Membre> get members => _members;
  List<Course> get courses => _courses;

  bool get profileLoading => _profileLoading;
  bool get membersLoading => _membersLoading;
  bool get coursesLoading => _coursesLoading;

  String? get profileError => _profileError;
  String? get membersError => _membersError;
  String? get coursesError => _coursesError;

  /// All courses created by the current coach.
  List<Course> get myCourses {
    final coachId = _profile?.id ?? AuthHolder.coachProfileId;
    if (coachId == null) return _courses;
    return _courses.where((c) => c.coachId == coachId).toList();
  }

  /// Upcoming courses (date is in the future).
  List<Course> get upcomingCourses {
    final now = DateTime.now();
    return myCourses.where((c) => c.dateTime.isAfter(now)).toList();
  }

  /// Ended courses (date is in the past).
  List<Course> get endedCourses {
    final now = DateTime.now();
    return myCourses.where((c) => c.dateTime.isBefore(now)).toList();
  }

  // ─── Profile ────────────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    _profileLoading = true;
    _profileError = null;
    notifyListeners();

    try {
      _profile = await _service.getMyProfile();

      // Store coach profile ID for course filtering
      if (_profile != null) {
        AuthHolder.coachProfileId = _profile!.id;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('coach_profile_id', _profile!.id);
      }

      _profileLoading = false;
      notifyListeners();
    } catch (e) {
      _profileError = e.toString();
      _profileLoading = false;
      notifyListeners();
      debugPrint('❌ [CoachProvider] loadProfile error: $e');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      _profile = await _service.updateMyProfile(data);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [CoachProvider] updateProfile error: $e');
      rethrow;
    }
  }

  // ─── Members ────────────────────────────────────────────────────────────

  Future<void> loadMembers() async {
    _membersLoading = true;
    _membersError = null;
    notifyListeners();

    try {
      _members = await _service.getMembers();
      _membersLoading = false;
      notifyListeners();
    } catch (e) {
      _membersError = e.toString();
      _membersLoading = false;
      notifyListeners();
      debugPrint('❌ [CoachProvider] loadMembers error: $e');
    }
  }

  // ─── Courses ────────────────────────────────────────────────────────────

  Future<void> loadCourses() async {
    _coursesLoading = true;
    _coursesError = null;
    notifyListeners();

    try {
      _courses = await _service.getCourses();
      _coursesLoading = false;
      notifyListeners();
    } catch (e) {
      _coursesError = e.toString();
      _coursesLoading = false;
      notifyListeners();
      debugPrint('❌ [CoachProvider] loadCourses error: $e');
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
    final coachId = _profile?.id ?? AuthHolder.coachProfileId ?? '';
    await _service.createCourse(
      title: title,
      description: description,
      level: level,
      dateTime: dateTime,
      durationMinutes: durationMinutes,
      maxParticipants: maxParticipants,
      coachProfileId: coachId,
    );
    await loadCourses();
  }

  Future<void> deleteCourse(String id) async {
    await _service.deleteCourse(id);
    _courses.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // ─── Auth ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _service.logout();
    _profile = null;
    _members = [];
    _courses = [];
    notifyListeners();
  }

  // ─── Reset ──────────────────────────────────────────────────────────────

  void reset() {
    _profile = null;
    _members = [];
    _courses = [];
    _profileError = null;
    _membersError = null;
    _coursesError = null;
    notifyListeners();
  }
}
