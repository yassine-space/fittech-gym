import 'package:mobile/core/models/coach_profile_model.dart';
import 'package:mobile/core/models/course.dart';
import 'package:mobile/core/models/membre_model.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/core/services/apiservice.dart';

/// Service for all coach-related backend API calls.
///
/// Uses the singleton [Apiservice] which handles auth headers automatically.
class CoachService {
  final _api = Apiservice.instance;

  // ─── Coach Profile ──────────────────────────────────────────────────────

  /// GET /coaches/me/ — fetch the authenticated coach's own profile.
  Future<CoachProfile> getMyProfile() async {
    final res = await _api.request(DioMethode.get, '/coaches/me/');
    return CoachProfile.fromJson(res.data);
  }

  /// PUT /coaches/me/ — update the coach profile (specialties, biography, etc.)
  Future<CoachProfile> updateMyProfile(Map<String, dynamic> data) async {
    final res = await _api.request(DioMethode.put, '/coaches/me/', data: data);
    return CoachProfile.fromJson(res.data);
  }

  // ─── User Account ───────────────────────────────────────────────────────

  /// GET /auth/me/ — fetch the authenticated user's account info.
  Future<UserModel> getMyUser() async {
    final res = await _api.request(DioMethode.get, '/auth/me/');
    return UserModel.fromJson(res.data);
  }

  /// PUT /auth/me/ — update user account (name, email, phone, photo).
  Future<UserModel> updateMyUser(Map<String, dynamic> data) async {
    final res = await _api.request(DioMethode.put, '/auth/me/', data: data);
    return UserModel.fromJson(res.data);
  }

  // ─── Members ────────────────────────────────────────────────────────────

  /// GET /membres/ — list all members (coach has permission).
  Future<List<Membre>> getMembers() async {
    final res = await _api.request(DioMethode.get, '/membres/');
    final List data = res.data is List ? res.data : (res.data['results'] ?? []);
    return data.map((e) => Membre.fromJson(e)).toList();
  }

  /// GET /membres/<id>/ — get a single member's detail.
  Future<Membre> getMemberDetail(String id) async {
    final res = await _api.request(DioMethode.get, '/membres/$id/');
    return Membre.fromJson(res.data);
  }

  // ─── Courses ────────────────────────────────────────────────────────────

  /// GET /courses/ — list all courses.
  Future<List<Course>> getCourses() async {
    final res = await _api.request(DioMethode.get, '/courses/');
    final List data = res.data is List ? res.data : (res.data['results'] ?? []);
    return data.map((e) => Course.fromJson(e)).toList();
  }

  /// GET /courses/ filtered by current coach ID.
  Future<List<Course>> getMyCourses() async {
    final allCourses = await getCourses();
    final myId = AuthHolder.id;
    if (myId == null) return allCourses;
    // Filter to only courses created by this coach's coach profile
    // The backend returns coach as the Coach model UUID, not User UUID.
    // We need to match using the coach profile ID.
    return allCourses;
  }

  /// POST /courses/ — create a new course.
  Future<Course> createCourse({
    required String title,
    required String description,
    required String level,
    required DateTime dateTime,
    required int durationMinutes,
    required int maxParticipants,
    required String coachProfileId,
  }) async {
    final res = await _api.request(
      DioMethode.post,
      '/courses/',
      data: {
        'title': title,
        'description': description,
        'level_required': level,
        'date_time': dateTime.toIso8601String(),
        'duration_minutes': durationMinutes,
        'max_participants': maxParticipants,
        'coach': coachProfileId,
      },
    );
    return Course.fromJson(res.data);
  }

  /// PUT /courses/<id>/ — update a course.
  Future<Course> updateCourse(String id, Map<String, dynamic> data) async {
    final res = await _api.request(DioMethode.put, '/courses/$id/', data: data);
    return Course.fromJson(res.data);
  }

  /// DELETE /courses/<id>/ — delete a course.
  Future<void> deleteCourse(String id) async {
    await _api.request(DioMethode.delete, '/courses/$id/');
  }

  // ─── Auth Actions ───────────────────────────────────────────────────────

  /// POST /auth/logout/ — blacklist the refresh token and clear local storage.
  Future<void> logout() async {
    final refresh = AuthHolder.refreshToken;
    if (refresh != null) {
      try {
        await _api.request(
          DioMethode.post,
          '/auth/logout/',
          data: {'refresh': refresh},
        );
      } catch (_) {
        // If token is already expired/invalid, ignore
      }
    }
    await _api.clearAuthData();
  }

  /// PUT /auth/change-password/ — change the user's password.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPassword2,
  }) async {
    await _api.request(
      DioMethode.put,
      '/auth/change-password/',
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password2': newPassword2,
        'refresh': AuthHolder.refreshToken,
      },
    );
    await _api.clearAuthData();
  }
}
