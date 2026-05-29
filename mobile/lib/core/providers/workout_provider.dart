// lib/core/providers/workout_provider.dart
import 'package:flutter/foundation.dart';
import 'package:mobile/core/services/apiservice.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class Machine {
  final String id;
  final String name;
  final String type; // machine | free_weight
  final String? description;

  Machine({
    required this.id,
    required this.name,
    required this.type,
    this.description,
  });

  factory Machine.fromJson(Map<String, dynamic> j) => Machine(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        type: j['type'] ?? 'machine',
        description: j['description'],
      );

  bool get isFreeWeight => type == 'free_weight';
}

class WorkoutSet {
  final String id;
  final int setNumber;
  final int reps;
  final double weightKg;

  WorkoutSet({
    required this.id,
    required this.setNumber,
    required this.reps,
    required this.weightKg,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> j) => WorkoutSet(
        id: j['id'] ?? '',
        setNumber: j['set_number'] ?? 0,
        reps: j['reps'] ?? 0,
        weightKg: (j['weight_kg'] as num?)?.toDouble() ?? 0.0,
      );
}

class WorkoutLog {
  final String id;
  final String membreId;
  final String membreName;
  final Machine machine;
  final String? notes;
  final DateTime loggedAt;
  final List<WorkoutSet> sets;
  final double maxWeightKg;

  WorkoutLog({
    required this.id,
    required this.membreId,
    required this.membreName,
    required this.machine,
    this.notes,
    required this.loggedAt,
    required this.sets,
    required this.maxWeightKg,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> j) {
    final sets = (j['sets'] as List? ?? [])
        .map((s) => WorkoutSet.fromJson(s))
        .toList();
    final membre = j['membre'] is Map ? j['membre'] : {};
    final membreUser = membre['user'] is Map ? membre['user'] : {};
    final firstName = membreUser['first_name'] ?? '';
    final lastName = membreUser['last_name'] ?? '';

    return WorkoutLog(
      id: j['id'] ?? '',
      membreId: membre['id']?.toString() ?? '',
      membreName: '$firstName $lastName'.trim(),
      machine: Machine.fromJson(
          j['machine'] is Map ? j['machine'] : {'id': '', 'name': '', 'type': 'machine'}),
      notes: j['notes'],
      loggedAt: DateTime.tryParse(j['logged_at'] ?? '') ?? DateTime.now(),
      sets: sets,
      maxWeightKg: (j['max_weight_kg'] as num?)?.toDouble() ??
          (sets.isEmpty
              ? 0.0
              : sets.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b)),
    );
  }

  int get totalSets => sets.length;
  int get totalReps => sets.fold(0, (sum, s) => sum + s.reps);
  double get totalVolume =>
      sets.fold(0.0, (sum, s) => sum + s.reps * s.weightKg);
}

class ProgressPoint {
  final String id;
  final DateTime loggedAt;
  final double maxWeightKg;
  final List<WorkoutSet> sets;
  final String? notes;

  ProgressPoint({
    required this.id,
    required this.loggedAt,
    required this.maxWeightKg,
    required this.sets,
    this.notes,
  });

  factory ProgressPoint.fromJson(Map<String, dynamic> j) {
    final sets = (j['sets'] as List? ?? [])
        .map((s) => WorkoutSet.fromJson(s))
        .toList();
    return ProgressPoint(
      id: j['id'] ?? '',
      loggedAt: DateTime.tryParse(j['logged_at'] ?? '') ?? DateTime.now(),
      maxWeightKg: (j['max_weight_kg'] as num?)?.toDouble() ??
          (sets.isEmpty
              ? 0.0
              : sets.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b)),
      sets: sets,
      notes: j['notes'],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutProvider
// ─────────────────────────────────────────────────────────────────────────────

class WorkoutProvider extends ChangeNotifier {
  // ── Machines ───────────────────────────────────────────────────────────────
  List<Machine> _machines = [];
  List<Machine> get machines => _machines;
  bool _machinesLoading = false;
  bool get machinesLoading => _machinesLoading;
  String? _machinesError;
  String? get machinesError => _machinesError;

  // ── Workout logs (coach view — all assigned members) ───────────────────────
  List<WorkoutLog> _logs = [];
  List<WorkoutLog> get logs => _logs;
  bool _logsLoading = false;
  bool get logsLoading => _logsLoading;
  String? _logsError;
  String? get logsError => _logsError;

  // ── Machine form submitting ────────────────────────────────────────────────
  bool _submitting = false;
  bool get submitting => _submitting;

  // ─────────────────────────────────────────────────────────────────────────
  // Load machines
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadMachines() async {
    _machinesLoading = true;
    _machinesError = null;
    notifyListeners();

    try {
      final res = await Apiservice.instance
          .request(DioMethode.get, '/machines/');
      final List data = res.data;
      _machines = data.map((j) => Machine.fromJson(j)).toList();
    } catch (e) {
      _machinesError = 'Failed to load machines';
    } finally {
      _machinesLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Create machine
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> createMachine({
    required String name,
    required String type,
    String? description,
  }) async {
    _submitting = true;
    notifyListeners();

    try {
      final res = await Apiservice.instance.request(
        DioMethode.post,
        '/machines/',
        data: {
          'name': name,
          'type': type,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
      _machines.insert(0, Machine.fromJson(res.data));
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Edit machine
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> editMachine(
    String machineId, {
    required String name,
    required String type,
    String? description,
  }) async {
    _submitting = true;
    notifyListeners();

    try {
      final res = await Apiservice.instance.request(
        DioMethode.put,
        '/machines/$machineId/',
        data: {
          'name': name,
          'type': type,
          'description': ?description,
        },
      );
      final idx = _machines.indexWhere((m) => m.id == machineId);
      if (idx != -1) _machines[idx] = Machine.fromJson(res.data);
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Delete machine
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> deleteMachine(String machineId) async {
    await Apiservice.instance
        .request(DioMethode.delete, '/machines/$machineId/');
    _machines.removeWhere((m) => m.id == machineId);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Progress (per machine, for chart)
  // ─────────────────────────────────────────────────────────────────────────

  List<ProgressPoint> _progress = [];
  List<ProgressPoint> get progress => _progress;
  bool _progressLoading = false;
  bool get progressLoading => _progressLoading;
  String? _progressError;
  String? get progressError => _progressError;

  Future<void> loadProgress(String machineId) async {
    _progressLoading = true;
    _progressError = null;
    _progress = [];
    notifyListeners();

    try {
      final res = await Apiservice.instance.request(
        DioMethode.get,
        '/workouts/progress/?machine=$machineId',
      );
      final List data = res.data;
      _progress = data.map((j) => ProgressPoint.fromJson(j)).toList();
      _progress.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    } catch (e) {
      _progressError = 'Failed to load progress';
    } finally {
      _progressLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Single log detail
  // ─────────────────────────────────────────────────────────────────────────

  Future<WorkoutLog?> fetchLog(String logId) async {
    try {
      final res = await Apiservice.instance
          .request(DioMethode.get, '/workouts/$logId/');
      return WorkoutLog.fromJson(res.data);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadLogs() async {
    _logsLoading = true;
    _logsError = null;
    notifyListeners();

    try {
      final res = await Apiservice.instance
          .request(DioMethode.get, '/workouts/');
      final List data = res.data;
      _logs = data.map((j) => WorkoutLog.fromJson(j)).toList();
      // Sort newest first
      _logs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    } catch (e) {
      _logsError = 'Failed to load workout logs';
    } finally {
      _logsLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Logs grouped by member name
  Map<String, List<WorkoutLog>> get logsByMember {
    final map = <String, List<WorkoutLog>>{};
    for (final log in _logs) {
      map.putIfAbsent(log.membreName, () => []).add(log);
    }
    return map;
  }

  /// Logs for a specific member
  List<WorkoutLog> logsForMember(String memberId) =>
      _logs.where((l) => l.membreId == memberId).toList();
}