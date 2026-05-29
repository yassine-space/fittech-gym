// lib/features/coach/screens/programs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/providers/workout_provider.dart';
import 'package:mobile/features/coach/screens/workout_log_detail_screen.dart';
import 'package:mobile/core/widgets/notification_bell.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kOrange    = Color(0xFFD44820);
const _kNavy      = Color(0xFF2D3142);
const _kOrangeSoft = Color(0xFFFAEDE8);
const _kGrey      = Color(0xFF8A8FA8);
const _kBg        = Color(0xFFF7F7FB);
const _kGreen     = Color(0xFF27AE60);
const _kRed       = Color(0xFFE74C3C);
const _kWhite     = Colors.white;

// ─────────────────────────────────────────────────────────────────────────────
// ProgramsScreen (tab host)
// ─────────────────────────────────────────────────────────────────────────────
class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<WorkoutProvider>();
      p.loadMachines();
      p.loadLogs();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _MemberLogsTab(),
                  _MachinesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Training',
                  style: TextStyle(
                      fontSize: 13,
                      color: _kGrey,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              const Text('Programs',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: _kNavy,
                      height: 1)),
            ],
          ),
          const Spacer(),
          Consumer<WorkoutProvider>(
            builder: (_, p, _) => GestureDetector(
              onTap: () {
                p.loadMachines();
                p.loadLogs();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kWhite,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: _kNavy.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: const Icon(Icons.refresh_rounded, color: _kNavy, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const NotificationBell(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: _kNavy.withOpacity(0.06), blurRadius: 6)
        ],
      ),
      child: TabBar(
        controller: _tab,
        indicator: BoxDecoration(
          color: _kNavy,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: _kWhite,
        unselectedLabelColor: _kGrey,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Member Logs'),
          Tab(text: 'Machines & Exercises'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Member Workout Logs
// ─────────────────────────────────────────────────────────────────────────────
class _MemberLogsTab extends StatefulWidget {
  const _MemberLogsTab();

  @override
  State<_MemberLogsTab> createState() => _MemberLogsTabState();
}

class _MemberLogsTabState extends State<_MemberLogsTab> {
  String? _selectedMember; // null = show all

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (_, p, _) {
        if (p.logsLoading && p.logs.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: _kOrange));
        }
        if (p.logsError != null && p.logs.isEmpty) {
          return _ErrorView(
              message: p.logsError!, onRetry: () => p.loadLogs());
        }
        if (p.logs.isEmpty) {
          return const _EmptyView(
            icon: Icons.fitness_center_rounded,
            title: 'No workout logs yet',
            subtitle: 'Your assigned members haven\'t logged any workouts.',
          );
        }

        final byMember = p.logsByMember;
        final memberNames = byMember.keys.toList();
        final displayLogs = _selectedMember == null
            ? p.logs
            : p.logsForMember(_selectedMember!);

        return RefreshIndicator(
          color: _kOrange,
          onRefresh: () => p.loadLogs(),
          child: CustomScrollView(
            slivers: [
              // ── Stats row ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    children: [
                      _MiniStat(
                          label: 'Total Logs',
                          value: '${p.logs.length}',
                          color: _kOrange),
                      const SizedBox(width: 10),
                      _MiniStat(
                          label: 'Members',
                          value: '${byMember.length}',
                          color: _kNavy),
                      const SizedBox(width: 10),
                      _MiniStat(
                          label: 'This Week',
                          value: '${_thisWeekCount(p.logs)}',
                          color: _kGreen),
                    ],
                  ),
                ),
              ),

              // ── Member filter chips ───────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _selectedMember == null,
                        onTap: () =>
                            setState(() => _selectedMember = null),
                      ),
                      ...memberNames.map((name) {
                        final memberId =
                            byMember[name]!.first.membreId;
                        return _FilterChip(
                          label: name.isEmpty ? 'Unknown' : name,
                          selected: _selectedMember == memberId,
                          onTap: () => setState(
                              () => _selectedMember = memberId),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // ── Log list ──────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _WorkoutLogCard(log: displayLogs[i]),
                    childCount: displayLogs.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _thisWeekCount(List<WorkoutLog> logs) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return logs.where((l) => l.loggedAt.isAfter(weekAgo)).length;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Machines & Exercises
// ─────────────────────────────────────────────────────────────────────────────
class _MachinesTab extends StatefulWidget {
  const _MachinesTab();

  @override
  State<_MachinesTab> createState() => _MachinesTabState();
}

class _MachinesTabState extends State<_MachinesTab> {
  String _filter = 'all'; // all | machine | free_weight

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMachineSheet(
        onAdded: () {
          Navigator.pop(context);
          _showSnack('✅ Added successfully!', _kGreen);
        },
      ),
    );
  }

  void _openEditSheet(Machine machine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditMachineSheet(
        machine: machine,
        onEdited: () {
          Navigator.pop(context);
          _showSnack('✅ Updated successfully!', _kGreen);
        },
      ),
    );
  }

  Future<void> _confirmDelete(Machine machine) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete',
            style: TextStyle(fontWeight: FontWeight.w800, color: _kNavy)),
        content: Text(
          'Delete "${machine.name}"? This cannot be undone.',
          style: const TextStyle(color: _kGrey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _kGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: _kWhite,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<WorkoutProvider>().deleteMachine(machine.id);
      _showSnack('🗑 Deleted.', _kNavy);
    } catch (_) {
      _showSnack('❌ Failed to delete.', _kRed);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (_, p, _) {
        final filtered = p.machines.where((m) {
          if (_filter == 'all') return true;
          return m.type == _filter;
        }).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAddSheet,
            backgroundColor: _kOrange,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, color: _kWhite),
            label: const Text('Add Equipment',
                style: TextStyle(
                    color: _kWhite,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ),
          body: p.machinesLoading && p.machines.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: _kOrange))
              : p.machinesError != null && p.machines.isEmpty
                  ? _ErrorView(
                      message: p.machinesError!,
                      onRetry: () => p.loadMachines())
                  : CustomScrollView(
                      slivers: [
                        // ── Type filter ──────────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(24, 8, 24, 0),
                            child: Row(
                              children: [
                                _TypeChip(
                                    label: 'All',
                                    selected: _filter == 'all',
                                    onTap: () =>
                                        setState(() => _filter = 'all')),
                                const SizedBox(width: 8),
                                _TypeChip(
                                    label: 'Machines',
                                    selected: _filter == 'machine',
                                    onTap: () => setState(
                                        () => _filter = 'machine')),
                                const SizedBox(width: 8),
                                _TypeChip(
                                    label: 'Free Weights',
                                    selected: _filter == 'free_weight',
                                    onTap: () => setState(
                                        () => _filter = 'free_weight')),
                              ],
                            ),
                          ),
                        ),

                        if (filtered.isEmpty)
                          SliverFillRemaining(
                            child: _EmptyView(
                              icon: Icons.fitness_center_rounded,
                              title: p.machines.isEmpty
                                  ? 'No equipment yet'
                                  : 'No results',
                              subtitle: p.machines.isEmpty
                                  ? 'Add machines and exercises for members to track.'
                                  : 'Try a different filter.',
                            ),
                          )
                        else
                          SliverPadding(
                            padding:
                                const EdgeInsets.fromLTRB(24, 12, 24, 100),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.3,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _MachineCard(
                                  machine: filtered[i],
                                  onEdit: () => _openEditSheet(filtered[i]),
                                  onDelete: () =>
                                      _confirmDelete(filtered[i]),
                                ),
                                childCount: filtered.length,
                              ),
                            ),
                          ),
                      ],
                    ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Workout Log Card
// ─────────────────────────────────────────────────────────────────────────────
class _WorkoutLogCard extends StatefulWidget {
  final WorkoutLog log;
  const _WorkoutLogCard({required this.log});

  @override
  State<_WorkoutLogCard> createState() => _WorkoutLogCardState();
}

class _WorkoutLogCardState extends State<_WorkoutLogCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => WorkoutLogDetailScreen(log: log)),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _kNavy.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // ── Top accent bar ─────────────────────────────────────────────
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                colors: log.machine.isFreeWeight
                    ? [_kGreen, const Color(0xFF8BC34A)]
                    : [_kOrange, _kNavy],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: log.machine.isFreeWeight
                            ? _kGreen.withOpacity(0.1)
                            : _kOrangeSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        log.machine.isFreeWeight
                            ? Icons.sports_gymnastics_rounded
                            : Icons.precision_manufacturing_rounded,
                        color: log.machine.isFreeWeight
                            ? _kGreen
                            : _kOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.machine.name,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _kNavy)),
                          Text(
                            log.membreName.isEmpty
                                ? 'Unknown member'
                                : log.membreName,
                            style: const TextStyle(
                                fontSize: 12, color: _kGrey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('d MMM, h:mm a').format(log.loggedAt),
                      style: const TextStyle(
                          fontSize: 11,
                          color: _kGrey,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Stats row ────────────────────────────────────────────
                Row(
                  children: [
                    _LogStat(
                        label: 'Sets',
                        value: '${log.totalSets}',
                        color: _kOrange),
                    const SizedBox(width: 8),
                    _LogStat(
                        label: 'Reps',
                        value: '${log.totalReps}',
                        color: _kNavy),
                    const SizedBox(width: 8),
                    _LogStat(
                        label: 'Max',
                        value: '${log.maxWeightKg}kg',
                        color: _kGreen),
                    const SizedBox(width: 8),
                    _LogStat(
                        label: 'Volume',
                        value: '${log.totalVolume.toStringAsFixed(0)}kg',
                        color: _kGrey),
                  ],
                ),

                // ── Notes ────────────────────────────────────────────────
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notes_rounded,
                            size: 14, color: _kGrey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(log.notes!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: _kGrey,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Expand sets ───────────────────────────────────────────
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _expanded = !_expanded);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Text(
                          _expanded ? 'Hide sets' : 'View sets',
                          style: const TextStyle(
                              fontSize: 12,
                              color: _kOrange,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: _kOrange),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Sets table ────────────────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _expanded
                      ? Column(
                          children: [
                            const SizedBox(height: 10),
                            // Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _kNavy,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                      child: Text('SET',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: _kWhite,
                                              letterSpacing: 0.8))),
                                  Expanded(
                                      child: Text('REPS',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: _kWhite,
                                              letterSpacing: 0.8))),
                                  Expanded(
                                      child: Text('WEIGHT',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: _kWhite,
                                              letterSpacing: 0.8))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...log.sets.map((s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: s.setNumber.isOdd
                                        ? _kBg
                                        : _kWhite,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text('Set ${s.setNumber}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: _kNavy)),
                                      ),
                                      Expanded(
                                        child: Text('${s.reps} reps',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: _kGrey)),
                                      ),
                                      Expanded(
                                        child: Text(
                                            '${s.weightKg} kg',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: _kOrange)),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  // closes GestureDetector
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Machine Card (grid)
// ─────────────────────────────────────────────────────────────────────────────
class _MachineCard extends StatelessWidget {
  final Machine machine;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _MachineCard({required this.machine, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isFw = machine.isFreeWeight;
    final color = isFw ? _kGreen : _kOrange;

    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _kNavy.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          // accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              color: color,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isFw
                              ? Icons.sports_gymnastics_rounded
                              : Icons.precision_manufacturing_rounded,
                          color: color,
                          size: 16,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: _kOrange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit_outlined,
                              size: 14, color: _kOrange),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: _kRed.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 15, color: _kRed),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(machine.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _kNavy,
                          height: 1.2)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isFw ? 'Free Weight' : 'Machine',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Machine Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AddMachineSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddMachineSheet({required this.onAdded});

  @override
  State<_AddMachineSheet> createState() => _AddMachineSheetState();
}

class _AddMachineSheetState extends State<_AddMachineSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'machine';
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('Please enter a name.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await context.read<WorkoutProvider>().createMachine(
            name: name,
            type: _type,
            description: _descCtrl.text.trim(),
          );
      widget.onAdded();
    } catch (_) {
      setState(() => _submitting = false);
      _showError('Failed to add. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: _kRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: _kOrangeSoft,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add_rounded,
                      color: _kOrange, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add Equipment',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _kNavy)),
                    Text('Machine or free weight exercise',
                        style: TextStyle(fontSize: 13, color: _kGrey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Type selector
            const Text('Type',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kNavy)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'machine'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _type == 'machine'
                            ? _kOrange.withOpacity(0.12)
                            : _kBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _type == 'machine'
                              ? _kOrange
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.precision_manufacturing_rounded,
                              color: _type == 'machine'
                                  ? _kOrange
                                  : _kGrey,
                              size: 22),
                          const SizedBox(height: 4),
                          Text('Machine',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _type == 'machine'
                                      ? _kOrange
                                      : _kGrey)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'free_weight'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == 'free_weight'
                            ? _kGreen.withOpacity(0.12)
                            : _kBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _type == 'free_weight'
                              ? _kGreen
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.sports_gymnastics_rounded,
                              color: _type == 'free_weight'
                                  ? _kGreen
                                  : _kGrey,
                              size: 22),
                          const SizedBox(height: 4),
                          Text('Free Weight',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _type == 'free_weight'
                                      ? _kGreen
                                      : _kGrey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            const Text('Name',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kNavy)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: _type == 'machine'
                    ? 'e.g. Leg Press, Treadmill'
                    : 'e.g. Squat, Deadlift, Bench Press',
                hintStyle:
                    TextStyle(color: _kGrey.withOpacity(0.7), fontSize: 13),
                prefixIcon: const Icon(Icons.fitness_center_rounded,
                    color: _kOrange, size: 18),
                filled: true,
                fillColor: _kBg,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            const Text('Description (optional)',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kNavy)),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Muscle groups targeted, tips, etc.',
                hintStyle:
                    TextStyle(color: _kGrey.withOpacity(0.7), fontSize: 13),
                filled: true,
                fillColor: _kBg,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange,
                  foregroundColor: _kWhite,
                  disabledBackgroundColor: _kOrange.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: _kWhite, strokeWidth: 2))
                    : const Text('➕  Add Equipment',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}

class _LogStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _LogStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: const TextStyle(fontSize: 9, color: _kGrey)),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _kOrange : _kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: selected
                    ? _kOrange.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? _kWhite : _kGrey)),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _kNavy : _kWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? _kNavy : Colors.grey.withOpacity(0.2)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? _kWhite : _kGrey)),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 56, color: _kOrange.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  color: _kNavy, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                foregroundColor: _kWhite,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyView(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: _kOrange.withOpacity(0.3)),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                    color: _kNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kGrey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Machine Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _EditMachineSheet extends StatefulWidget {
  final Machine machine;
  final VoidCallback onEdited;
  const _EditMachineSheet({required this.machine, required this.onEdited});

  @override
  State<_EditMachineSheet> createState() => _EditMachineSheetState();
}

class _EditMachineSheetState extends State<_EditMachineSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String _type;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.machine.name);
    _descCtrl = TextEditingController(text: widget.machine.description ?? '');
    _type = widget.machine.type;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { _showError('Please enter a name.'); return; }
    setState(() => _submitting = true);
    try {
      await context.read<WorkoutProvider>().editMachine(
        widget.machine.id, name: name, type: _type,
        description: _descCtrl.text.trim(),
      );
      widget.onEdited();
    } catch (_) {
      setState(() => _submitting = false);
      _showError('Failed to update. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: _kRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _kOrangeSoft,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.edit_rounded, color: _kOrange, size: 22)),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Edit Equipment', style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w800, color: _kNavy)),
                Text('Update name, type or description',
                    style: TextStyle(fontSize: 13, color: _kGrey)),
              ]),
            ]),
            const SizedBox(height: 24),
            const Text('Type', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: _kNavy)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _type = 'machine'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _type == 'machine' ? _kOrange.withOpacity(0.12) : _kBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _type == 'machine' ? _kOrange : Colors.transparent,
                        width: 1.5),
                  ),
                  child: Column(children: [
                    Icon(Icons.precision_manufacturing_rounded,
                        color: _type == 'machine' ? _kOrange : _kGrey, size: 22),
                    const SizedBox(height: 4),
                    Text('Machine', style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _type == 'machine' ? _kOrange : _kGrey)),
                  ]),
                ),
              )),
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _type = 'free_weight'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _type == 'free_weight' ? _kGreen.withOpacity(0.12) : _kBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _type == 'free_weight' ? _kGreen : Colors.transparent,
                        width: 1.5),
                  ),
                  child: Column(children: [
                    Icon(Icons.sports_gymnastics_rounded,
                        color: _type == 'free_weight' ? _kGreen : _kGrey, size: 22),
                    const SizedBox(height: 4),
                    Text('Free Weight', style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _type == 'free_weight' ? _kGreen : _kGrey)),
                  ]),
                ),
              )),
            ]),
            const SizedBox(height: 16),
            const Text('Name', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: _kNavy)),
            const SizedBox(height: 6),
            TextField(controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'Equipment name',
                hintStyle: TextStyle(color: _kGrey.withOpacity(0.7), fontSize: 13),
                prefixIcon: const Icon(Icons.fitness_center_rounded,
                    color: _kOrange, size: 18),
                filled: true, fillColor: _kBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              )),
            const SizedBox(height: 16),
            const Text('Description (optional)', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: _kNavy)),
            const SizedBox(height: 6),
            TextField(controller: _descCtrl, maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Muscle groups, tips…',
                hintStyle: TextStyle(color: _kGrey.withOpacity(0.7), fontSize: 13),
                filled: true, fillColor: _kBg,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              )),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange, foregroundColor: _kWhite,
                  disabledBackgroundColor: _kOrange.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: _kWhite, strokeWidth: 2))
                    : const Text('💾  Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}