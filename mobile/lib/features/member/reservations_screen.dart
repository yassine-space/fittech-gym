import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/providers/coach_provider.dart';
import 'package:mobile/core/models/reservation_model.dart';

class ReservationsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  const ReservationsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoachProvider>().loadReservations();
      context.read<CoachProvider>().loadWaitlist();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoachProvider>(
      builder: (context, provider, _) {
        final reservations = provider.reservations
            .where((r) => r.courseId == widget.courseId)
            .toList();
        final confirmed = reservations
            .where((r) => r.reservationStatus == 'confirmed')
            .toList();
        final others = reservations
            .where((r) => r.reservationStatus != 'confirmed')
            .toList();
        final waitlist = provider.waitlistForCourse(widget.courseId);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F7FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3142)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.courseTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D3142),
                  ),
                ),
                Text(
                  '${confirmed.length} confirmed · ${waitlist.length} waiting',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A8FA8),
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabs,
              labelColor: const Color(0xFFD44820),
              unselectedLabelColor: const Color(0xFF8A8FA8),
              indicatorColor: const Color(0xFFD44820),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: 'Reservations (${reservations.length})'),
                Tab(text: 'Waitlist (${waitlist.length})'),
              ],
            ),
          ),
          body: provider.reservationsLoading && reservations.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD44820)),
                )
              : TabBarView(
                  controller: _tabs,
                  children: [
                    // Reservations tab
                    RefreshIndicator(
                      color: const Color(0xFFD44820),
                      onRefresh: () => provider.loadReservations(),
                      child: reservations.isEmpty
                          ? const _EmptyState(
                              icon: Icons.event_busy_rounded,
                              message: 'No reservations yet for this course',
                            )
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                if (confirmed.isNotEmpty) ...[
                                  _SectionHeader(
                                    label: 'CONFIRMED',
                                    count: confirmed.length,
                                    color: const Color(0xFF27AE60),
                                  ),
                                  const SizedBox(height: 8),
                                  ...confirmed.map((r) => _ReservationTile(
                                        reservation: r,
                                        members: provider.members,
                                        onCancel: () => _confirmCancel(context, provider, r),
                                      )),
                                  const SizedBox(height: 16),
                                ],
                                if (others.isNotEmpty) ...[
                                  _SectionHeader(
                                    label: 'OTHER STATUS',
                                    count: others.length,
                                    color: const Color(0xFF8A8FA8),
                                  ),
                                  const SizedBox(height: 8),
                                  ...others.map((r) => _ReservationTile(
                                        reservation: r,
                                        members: provider.members,
                                        onCancel: null,
                                      )),
                                ],
                              ],
                            ),
                    ),
                    // Waitlist tab
                    RefreshIndicator(
                      color: const Color(0xFFD44820),
                      onRefresh: () => provider.loadWaitlist(),
                      child: waitlist.isEmpty
                          ? const _EmptyState(
                              icon: Icons.playlist_add_check_rounded,
                              message: 'No one on the waitlist',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: waitlist.length,
                              itemBuilder: (_, i) => _WaitlistTile(
                                entry: waitlist[i],
                                members: provider.members,
                              ),
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    CoachProvider provider,
    CourseReservation r,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Reservation',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'This will cancel the reservation and promote the first person on the waitlist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep', style: TextStyle(color: Color(0xFF8A8FA8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel it'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await provider.cancelReservation(r.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation cancelled.'),
          backgroundColor: Color(0xFF2D3142),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel reservation.'),
          backgroundColor: Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SectionHeader({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }
}

class _ReservationTile extends StatelessWidget {
  final CourseReservation reservation;
  final List members;
  final VoidCallback? onCancel;

  const _ReservationTile({
    required this.reservation,
    required this.members,
    required this.onCancel,
  });

  Color get _statusColor => switch (reservation.reservationStatus) {
        'confirmed' => const Color(0xFF27AE60),
        'cancelled' => const Color(0xFFE74C3C),
        'attended' => const Color(0xFF2D3142),
        'no_show' => const Color(0xFFD44820),
        _ => const Color(0xFF8A8FA8),
      };

  @override
  Widget build(BuildContext context) {
    final member = members.cast<dynamic>().firstWhere(
          (m) => m.id == reservation.membreId,
          orElse: () => null,
        );
    final name = member?.user.fullName ?? 'Member';
    final email = member?.user.email ?? '';
    final initials = member?.user.initials ?? 'M';
    final dateStr = DateFormat('d MMM, HH:mm').format(reservation.reservationDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFD44820),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF2D3142))),
                  Text(email,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA8))),
                  const SizedBox(height: 4),
                  Text(
                    'Reserved $dateStr',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF8A8FA8)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    reservation.reservationStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: _statusColor,
                    ),
                  ),
                ),
                if (onCancel != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE74C3C).withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE74C3C),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitlistTile extends StatelessWidget {
  final dynamic entry;
  final List members;
  const _WaitlistTile({required this.entry, required this.members});

  @override
  Widget build(BuildContext context) {
    final member = members.cast<dynamic>().firstWhere(
          (m) => m.id == entry.membreId,
          orElse: () => null,
        );
    final name = member?.user.fullName ?? 'Member';
    final email = member?.user.email ?? '';
    final initials = member?.user.initials ?? 'M';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFD44820).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#${entry.position}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD44820),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF2D3142),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF2D3142))),
                  Text(email,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA8))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: const Color(0xFFD44820).withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF8A8FA8), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}