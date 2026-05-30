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
      weightKg: double.tryParse(j['weight_kg']?.toString() ?? '0') ?? 0.0, // ← fix this line
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

  // handle both nested object AND plain string ID
  final membreRaw = j['membre'];
  final String membreId;
  final String membreName;
  if (membreRaw is Map) {
    final membreUser = membreRaw['user'] is Map ? membreRaw['user'] : {};
    membreId = membreRaw['id']?.toString() ?? '';
    membreName = '${membreUser['first_name'] ?? ''} ${membreUser['last_name'] ?? ''}'.trim();
  } else {
    membreId = membreRaw?.toString() ?? '';
    membreName = '';
  }

  // handle both nested object AND plain string ID
  final machineRaw = j['machine'];
  final Machine machine;
  if (machineRaw is Map) {
    machine = Machine.fromJson(machineRaw as Map<String, dynamic>);
  } else {
    machine = Machine(
      id: machineRaw?.toString() ?? '',
      name: 'Unknown',
      type: 'machine',
    );
  }

  return WorkoutLog(
    id: j['id'] ?? '',
    membreId: membreId,
    membreName: membreName,
    machine: machine,
    notes: j['notes'],
    loggedAt: DateTime.tryParse(j['logged_at'] ?? '') ?? DateTime.now(),
    sets: sets,
    maxWeightKg: (j['max_weight_kg'] as num?)?.toDouble() ??
        (sets.isEmpty
            ? 0.0
            : sets.fold<double>(0.0, (best, s) => s.weightKg > best ? s.weightKg : best)),
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
    maxWeightKg: double.tryParse(j['max_weight_kg']?.toString() ?? '0') ?? 0.0, // ← fix
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
      print('PROGRESS_ERROR: $e'); 
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

  // field — add near the top of WorkoutProvider class
Set<String> _memberIds = {};
Set<String> get memberIds => _memberIds;

// replace loadLogs() entirely
Future<void> loadLogs() async {
  _logsLoading = true;
  _logsError = null;
  notifyListeners();

  try {
    final res = await Apiservice.instance
        .request(DioMethode.get, '/workouts/');
    List data = res.data as List;

    if (data.isEmpty) {
      try {
        final membresRes = await Apiservice.instance
            .request(DioMethode.get, '/coaches/me/membres/');
        final List membres = membresRes.data as List;
        _memberIds = membres
            .map((m) => m['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
      } catch (_) {
        // membres fetch failed — not fatal, show empty logs
      }
    }

    _logs = data
        .map((j) => WorkoutLog.fromJson(j as Map<String, dynamic>))
        .toList();
    _logs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  } catch (e) {
     
    print('WORKOUT_ERROR: $e');   
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