// lib/features/coach/screens/member_detail_screen.dart
//
// Changes from previous version:
//   • Added a "WORKOUT LOGS" section at the bottom (Fix #5 / Sprint 4).
//     The coach sees the assigned member's most recent workout logs,
//     each tapping through to WorkoutLogDetailScreen.
//   • WorkoutProvider is consumed to fetch logs filtered by this member.
//   • Everything else (header card, health & goals) is identical.
//
// Place this file at:  lib/features/coach/screens/member_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/models/membre_model.dart';
import 'package:mobile/core/providers/workout_provider.dart';
import 'package:mobile/features/coach/screens/workout_log_detail_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFD44820);
const _kNavy   = Color(0xFF1C1C1C);
const _kBg     = Color(0xFFF5EDE8);
const _kGrey   = Color(0xFF9A7060);
const _kGreen  = Color(0xFF27AE60);
const _kWhite  = Colors.white;

class MemberDetailScreen extends StatefulWidget {
  final Membre membre;

  const MemberDetailScreen({super.key, required this.membre});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load workout logs so we can display this member's history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().loadLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final membre  = widget.membre;
    final joinDate = membre.joinDate != null
        ? DateFormat('MMMM d, yyyy').format(membre.joinDate!)
        : 'N/A';

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MEMBER PROFILE',
          style: TextStyle(
              color: _kNavy,
              fontWeight: FontWeight.w900,
              fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Header card ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kWhite,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: _kOrange,
                    child: Text(
                      membre.user.initials,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _kWhite),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    membre.user.fullName,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _kNavy),
                  ),
                  Text(
                    membre.user.email,
                    style: const TextStyle(color: _kGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Health & Goals ─────────────────────────────────────────────
            _buildInfoSection(
              title: 'HEALTH & GOALS',
              items: [
                _InfoTile(
                  icon: Icons.track_changes,
                  label: 'Health Goal',
                  value: membre.healthGoal ?? 'No goal set',
                ),
                _InfoTile(
                  icon: Icons.medical_services_outlined,
                  label: 'Medical Restrictions',
                  value: membre.medicalRestrictions ?? 'None reported',
                  valueColor: membre.medicalRestrictions != null
                      ? _kOrange
                      : null,
                ),
                _InfoTile(
                  icon: Icons.calendar_today,
                  label: 'Member Since',
                  value: joinDate,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Workout Logs (Sprint 4) ────────────────────────────────────
            _WorkoutLogsSection(membreId: membre.id),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      {required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _kGrey,
              letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
              color: _kWhite,
              borderRadius: BorderRadius.circular(20)),
          child: Column(children: items),
        ),
      ],
    );
  }
}

// ─── Workout Logs Section ─────────────────────────────────────────────────────
class _WorkoutLogsSection extends StatelessWidget {
  final String membreId;

  const _WorkoutLogsSection({required this.membreId});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        final logs = provider.logsForMember(membreId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                const Text(
                  'WORKOUT LOGS',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _kGrey,
                      letterSpacing: 1),
                ),
                const SizedBox(width: 8),
                if (logs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${logs.length}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _kWhite),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Loading
            if (provider.logsLoading && logs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: CircularProgressIndicator(color: _kOrange)),
              )

            // Error
            else if (provider.logsError != null && logs.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        color: _kOrange, size: 36),
                    const SizedBox(height: 8),
                    Text(provider.logsError!,
                        style: const TextStyle(color: _kGrey),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => provider.loadLogs(),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _kOrange),
                      child: const Text('Retry',
                          style: TextStyle(color: _kWhite)),
                    ),
                  ],
                ),
              )

            // Empty
            else if (logs.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _kWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center_rounded,
                        color: _kGrey, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'No workout logs yet',
                      style: TextStyle(
                          color: _kGrey,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                  ],
                ),
              )

            // Log list
            else
              Container(
                decoration: BoxDecoration(
                  color: _kWhite,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: logs.take(10).map((log) {
                    final isFw = log.machine.isFreeWeight;
                    final color = isFw ? _kGreen : _kOrange;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkoutLogDetailScreen(log: log),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Machine icon
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isFw
                                      ? Icons.sports_gymnastics_rounded
                                      : Icons
                                          .precision_manufacturing_rounded,
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.machine.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: _kNavy),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      DateFormat('EEE, d MMM yyyy · h:mm a')
                                          .format(log.loggedAt),
                                      style: const TextStyle(
                                          fontSize: 11, color: _kGrey),
                                    ),
                                  ],
                                ),
                              ),

                              // Stats badges
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  _Badge(
                                      label:
                                          '${log.totalSets} sets',
                                      color: color),
                                  const SizedBox(height: 4),
                                  _Badge(
                                      label:
                                          '${log.maxWeightKg} kg',
                                      color: _kNavy),
                                ],
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right_rounded,
                                  size: 18,
                                  color: Color(0xFFD1B8A8)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Show more hint if there are many logs
            if (logs.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    '+ ${logs.length - 10} more logs',
                    style: const TextStyle(
                        fontSize: 12,
                        color: _kGrey,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Small badge used inside log rows ────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color),
      ),
    );
  }
}

// ─── Info Tile (unchanged) ────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: _kOrange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: _kGrey)),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? _kNavy),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}