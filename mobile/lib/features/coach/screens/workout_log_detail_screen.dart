// lib/features/coach/screens/workout_log_detail_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/providers/workout_provider.dart';

const _kOrange    = Color(0xFFD44820);
const _kNavy      = Color(0xFF2D3142);
const _kOrangeSoft = Color(0xFFFAEDE8);
const _kGrey      = Color(0xFF8A8FA8);
const _kBg        = Color(0xFFF7F7FB);
const _kGreen     = Color(0xFF27AE60);
const _kWhite     = Colors.white;

class WorkoutLogDetailScreen extends StatefulWidget {
  final WorkoutLog log;
  const WorkoutLogDetailScreen({super.key, required this.log});

  @override
  State<WorkoutLogDetailScreen> createState() =>
      _WorkoutLogDetailScreenState();
}

class _WorkoutLogDetailScreenState extends State<WorkoutLogDetailScreen> {
  late WorkoutLog _log;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _log = widget.log;
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final fresh = await context.read<WorkoutProvider>().fetchLog(_log.id);
    if (fresh != null && mounted) setState(() => _log = fresh);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isFw = _log.machine.isFreeWeight;
    final color = isFw ? _kGreen : _kOrange;

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: _kWhite, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: _kWhite, strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: _kWhite),
                  onPressed: _refresh,
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isFw
                        ? [_kGreen, const Color(0xFF1B5E20)]
                        : [_kOrange, _kNavy],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 56, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _kWhite.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isFw
                                    ? Icons.sports_gymnastics_rounded
                                    : Icons.precision_manufacturing_rounded,
                                color: _kWhite,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _log.machine.name,
                                style: const TextStyle(
                                  color: _kWhite,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _log.membreName.isEmpty
                              ? 'Unknown member'
                              : _log.membreName,
                          style: TextStyle(
                            color: _kWhite.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMMM d yyyy — h:mm a')
                              .format(_log.loggedAt),
                          style: TextStyle(
                            color: _kWhite.withOpacity(0.65),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Summary stats ───────────────────────────────────────
                Row(
                  children: [
                    _SummaryCard(
                        label: 'Sets',
                        value: '${_log.totalSets}',
                        icon: Icons.layers_rounded,
                        color: _kOrange),
                    const SizedBox(width: 10),
                    _SummaryCard(
                        label: 'Total Reps',
                        value: '${_log.totalReps}',
                        icon: Icons.repeat_rounded,
                        color: _kNavy),
                    const SizedBox(width: 10),
                    _SummaryCard(
                        label: 'Max Weight',
                        value: '${_log.maxWeightKg}kg',
                        icon: Icons.trending_up_rounded,
                        color: _kGreen),
                  ],
                ),
                const SizedBox(height: 10),
                _SummaryCard(
                  label: 'Total Volume',
                  value:
                      '${_log.totalVolume.toStringAsFixed(1)} kg',
                  icon: Icons.bar_chart_rounded,
                  color: color,
                  wide: true,
                  subtitle: 'Sum of (reps × weight) across all sets',
                ),

                const SizedBox(height: 20),

                // ── Notes ────────────────────────────────────────────────
                if (_log.notes != null && _log.notes!.isNotEmpty) ...[
                  _SectionTitle('Session Notes'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: color.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes_rounded,
                            color: color, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _log.notes!,
                            style: const TextStyle(
                                fontSize: 14,
                                color: _kNavy,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Sets table ───────────────────────────────────────────
                _SectionTitle('Sets Breakdown'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _kWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: _kNavy.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _kNavy,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                                flex: 1,
                                child: Text('SET',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _kWhite,
                                        letterSpacing: 1))),
                            Expanded(
                                flex: 2,
                                child: Text('REPS',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _kWhite,
                                        letterSpacing: 1))),
                            Expanded(
                                flex: 2,
                                child: Text('WEIGHT',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _kWhite,
                                        letterSpacing: 1))),
                            Expanded(
                                flex: 2,
                                child: Text('VOLUME',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _kWhite,
                                        letterSpacing: 1))),
                          ],
                        ),
                      ),
                      // Rows
                      ..._log.sets.asMap().entries.map((e) {
                        final i = e.key;
                        final s = e.value;
                        final vol = s.reps * s.weightKg;
                        final isLast =
                            i == _log.sets.length - 1;
                        final isPb = s.weightKg == _log.maxWeightKg;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: i.isOdd
                                ? _kBg
                                : _kWhite,
                            borderRadius: isLast
                                ? const BorderRadius.vertical(
                                    bottom: Radius.circular(16))
                                : null,
                            border: isLast
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                        color: Colors.grey
                                            .withOpacity(0.08))),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Row(
                                  children: [
                                    Text(
                                      '${s.setNumber}',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: color),
                                    ),
                                    if (isPb) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 1),
                                        decoration: BoxDecoration(
                                          color: _kGreen
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text('PB',
                                            style: TextStyle(
                                                fontSize: 8,
                                                fontWeight:
                                                    FontWeight.w800,
                                                color: _kGreen)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${s.reps} reps',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 13, color: _kNavy),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${s.weightKg} kg',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: color),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${vol.toStringAsFixed(1)} kg',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: _kGrey),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── View Progress button ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProgressChartScreen(
                          machine: _log.machine,
                          memberName: _log.membreName,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.show_chart_rounded,
                        size: 18),
                    label: Text(
                      'View ${_log.machine.name} Progress',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: _kWhite,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress Chart Screen
// ─────────────────────────────────────────────────────────────────────────────
class ProgressChartScreen extends StatefulWidget {
  final Machine machine;
  final String memberName;

  const ProgressChartScreen({
    super.key,
    required this.machine,
    required this.memberName,
  });

  @override
  State<ProgressChartScreen> createState() =>
      _ProgressChartScreenState();
}

class _ProgressChartScreenState extends State<ProgressChartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<WorkoutProvider>()
          .loadProgress(widget.machine.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (_, p, _) {
        final isFw = widget.machine.isFreeWeight;
        final color = isFw ? _kGreen : _kOrange;

        return Scaffold(
          backgroundColor: _kBg,
          appBar: AppBar(
            backgroundColor: color,
            foregroundColor: _kWhite,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.machine.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                Text(
                  widget.memberName.isEmpty
                      ? 'Progress'
                      : '${widget.memberName} · Progress',
                  style: TextStyle(
                      fontSize: 11,
                      color: _kWhite.withOpacity(0.8)),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () =>
                    p.loadProgress(widget.machine.id),
              ),
            ],
          ),
          body: p.progressLoading
              ? const Center(
                  child: CircularProgressIndicator(color: _kOrange))
              : p.progressError != null
                  ? _ProgressError(
                      error: p.progressError!,
                      onRetry: () =>
                          p.loadProgress(widget.machine.id))
                  : p.progress.isEmpty
                      ? _ProgressEmpty(machineName: widget.machine.name)
                      : _ProgressBody(
                          points: p.progress, color: color),
        );
      },
    );
  }
}

// ─── Progress body ────────────────────────────────────────────────────────────
class _ProgressBody extends StatelessWidget {
  final List<ProgressPoint> points;
  final Color color;
  const _ProgressBody({required this.points, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxW = points.map((p) => p.maxWeightKg).reduce(
        (a, b) => a > b ? a : b);
    final minW = points.map((p) => p.maxWeightKg).reduce(
        (a, b) => a < b ? a : b);
    final first = points.first.maxWeightKg;
    final last = points.last.maxWeightKg;
    final gain = last - first;
    final gainPct = first > 0 ? (gain / first * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary cards ─────────────────────────────────────────────
          Row(
            children: [
              _ProgressStat(
                  label: 'Sessions',
                  value: '${points.length}',
                  color: color),
              const SizedBox(width: 10),
              _ProgressStat(
                  label: 'Best',
                  value: '${maxW}kg',
                  color: _kGreen),
              const SizedBox(width: 10),
              _ProgressStat(
                  label: 'Gain',
                  value:
                      '${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(1)}kg',
                  color: gain >= 0 ? _kGreen : _kRed),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up_rounded, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  gain >= 0
                      ? 'Improved by ${gainPct.toStringAsFixed(1)}% since first session'
                      : 'Down ${gainPct.abs().toStringAsFixed(1)}% since first session',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Chart ──────────────────────────────────────────────────────
          const _SectionTitle('Max Weight Per Session (kg)'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
            decoration: BoxDecoration(
              color: _kWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: _kNavy.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: _LineChart(points: points, color: color),
          ),

          const SizedBox(height: 20),

          // ── Session history ────────────────────────────────────────────
          const _SectionTitle('Session History'),
          const SizedBox(height: 8),
          ...points.reversed.map((pt) => _ProgressSessionCard(
              point: pt, color: color, isPb: pt.maxWeightKg == maxW)),
        ],
      ),
    );
  }
}

// ─── Pure-Flutter line chart (no library needed) ──────────────────────────────
class _LineChart extends StatelessWidget {
  final List<ProgressPoint> points;
  final Color color;
  const _LineChart({required this.points, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _ChartPainter(points: points, color: color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<ProgressPoint> points;
  final Color color;
  _ChartPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      // Single point — just draw a dot
      final paint = Paint()..color = color..strokeWidth = 3;
      canvas.drawCircle(
          Offset(size.width / 2, size.height / 2), 6, paint);
      return;
    }

    final weights = points.map((p) => p.maxWeightKg).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final range = (maxW - minW) == 0 ? 1.0 : (maxW - minW);
    final padding = const EdgeInsets.fromLTRB(40, 10, 12, 30);

    final chartW = size.width - padding.left - padding.right;
    final chartH = size.height - padding.top - padding.bottom;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.12)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = padding.top + chartH * (1 - i / 4);
      canvas.drawLine(
          Offset(padding.left, y),
          Offset(padding.left + chartW, y),
          gridPaint);
      // Y label
      final label =
          '${(minW + range * i / 4).toStringAsFixed(0)}kg';
      final tp = TextPainter(
        text: TextSpan(
            text: label,
            style: TextStyle(
                fontSize: 9,
                color: Colors.grey.withOpacity(0.7))),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(0, y - tp.height / 2));
    }

    // Compute point positions
    final coords = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = padding.left + chartW * i / (points.length - 1);
      final y = padding.top +
          chartH * (1 - (weights[i] - minW) / range);
      coords.add(Offset(x, y));
    }

    // Fill area under curve
    final fillPath = Path()..moveTo(coords.first.dx, padding.top + chartH);
    for (final c in coords) {
      fillPath.lineTo(c.dx, c.dy);
    }
    fillPath.lineTo(coords.last.dx, padding.top + chartH);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
        ).createShader(
            Rect.fromLTWH(0, padding.top, size.width, chartH)),
    );

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final linePath = Path()..moveTo(coords.first.dx, coords.first.dy);
    for (int i = 1; i < coords.length; i++) {
      linePath.lineTo(coords[i].dx, coords[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots + X labels
    for (int i = 0; i < coords.length; i++) {
      // Dot
      canvas.drawCircle(coords[i], 5,
          Paint()..color = _kWhite);
      canvas.drawCircle(coords[i], 4,
          Paint()..color = color);

      // X label (date) — show first, last, and every ~3rd
      if (i == 0 || i == coords.length - 1 || i % 3 == 0) {
        final label =
            DateFormat('d/M').format(points[i].loggedAt);
        final tp = TextPainter(
          text: TextSpan(
              text: label,
              style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.withOpacity(0.7))),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(coords[i].dx - tp.width / 2,
              size.height - padding.bottom + 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.points != points || old.color != color;
}

// ─── Progress session card ────────────────────────────────────────────────────
class _ProgressSessionCard extends StatelessWidget {
  final ProgressPoint point;
  final Color color;
  final bool isPb;
  const _ProgressSessionCard(
      {required this.point, required this.color, required this.isPb});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(14),
        border: isPb ? Border.all(color: _kGreen, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
              color: _kNavy.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.fitness_center_rounded,
                color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('EEE, d MMM yyyy')
                          .format(point.loggedAt),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kNavy),
                    ),
                    if (isPb) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('BEST',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _kGreen)),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${point.sets.length} sets · ${point.sets.fold(0, (s, e) => s + e.reps)} reps',
                  style: const TextStyle(fontSize: 11, color: _kGrey),
                ),
              ],
            ),
          ),
          Text(
            '${point.maxWeightKg}kg',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isPb ? _kGreen : color),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: _kNavy,
          letterSpacing: 0.3));
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;
  final String? subtitle;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: wide ? 18 : 16,
                      fontWeight: FontWeight.w900,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _kGrey)),
              if (subtitle != null)
                Text(subtitle!,
                    style: TextStyle(
                        fontSize: 10,
                        color: _kGrey.withOpacity(0.7))),
            ],
          ),
        ],
      ),
    );
    return wide ? SizedBox(width: double.infinity, child: card) : Expanded(child: card);
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ProgressStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _kGrey)),
          ],
        ),
      ),
    );
  }
}

class _ProgressError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ProgressError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: _kOrange),
          const SizedBox(height: 8),
          Text(error,
              style: const TextStyle(color: _kNavy, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange, foregroundColor: _kWhite),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ProgressEmpty extends StatelessWidget {
  final String machineName;
  const _ProgressEmpty({required this.machineName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart_rounded,
                size: 60, color: _kOrange.withOpacity(0.3)),
            const SizedBox(height: 14),
            const Text('No progress data yet',
                style: TextStyle(
                    color: _kNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              'Once your member logs sessions for $machineName, their progress chart will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kGrey, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

const _kRed = Color(0xFFE74C3C);