// lib/features/coach/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/providers/notification_provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kOrange     = Color(0xFFD44820);
const _kNavy       = Color(0xFF2D3142);
const _kOrangeSoft = Color(0xFFFAEDE8);
const _kGrey       = Color(0xFF8A8FA8);
const _kBg         = Color(0xFFF7F7FB);
const _kGreen      = Color(0xFF27AE60);
const _kWhite      = Colors.white;
const _kYellow     = Color(0xFFF39C12);
const _kBlue       = Color(0xFF2980B9);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (_, provider, __) {
        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(provider),
                Expanded(child: _buildBody(provider)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(NotificationProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: _kNavy, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NOTIFICATIONS',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _kNavy,
                        letterSpacing: -0.5)),
                if (provider.unreadCount > 0)
                  Text(
                    '${provider.unreadCount} unread',
                    style: const TextStyle(
                        fontSize: 12,
                        color: _kOrange,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          if (provider.hasUnread)
            TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                provider.markAllRead();
              },
              icon: const Icon(Icons.done_all_rounded,
                  size: 16, color: _kOrange),
              label: const Text('Mark all read',
                  style: TextStyle(
                      fontSize: 12,
                      color: _kOrange,
                      fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                backgroundColor: _kOrangeSoft,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody(NotificationProvider provider) {
    if (provider.loading && provider.notifications.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: _kOrange));
    }

    if (provider.error != null && provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: _kOrange),
            const SizedBox(height: 8),
            Text(provider.error!,
                style: const TextStyle(color: _kGrey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.load(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange, foregroundColor: _kWhite),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 64, color: _kOrange.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('All caught up!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kNavy)),
            const SizedBox(height: 6),
            const Text(
              'No notifications yet.\nWe\'ll let you know when something happens.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kGrey, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () => provider.load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: provider.notifications.length,
        itemBuilder: (_, i) {
          final n = provider.notifications[i];
          // Section header: "New" above first unread, "Earlier" above first read
          final showNewHeader = i == 0 && !n.isRead;
          final showEarlierHeader = !n.isRead
              ? false
              : (i == 0 ||
                  !provider.notifications[i - 1].isRead);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showNewHeader) _SectionLabel('New'),
              if (showEarlierHeader) _SectionLabel('Earlier'),
              _NotificationCard(
                notification: n,
                onTap: () {
                  if (!n.isRead) {
                    HapticFeedback.selectionClick();
                    provider.markRead(n.id);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _kGrey,
              letterSpacing: 1.2)),
    );
  }
}

// ─── Notification card ────────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  // Per-type config
  static const _typeConfig = {
    'waitlist_promotion': (
      icon: Icons.celebration_rounded,
      color: _kGreen,
    ),
    'subscription_expiry': (
      icon: Icons.warning_amber_rounded,
      color: _kYellow,
    ),
    'coach_assignment': (
      icon: Icons.sports_rounded,
      color: _kOrange,
    ),
    'new_message': (
      icon: Icons.chat_bubble_rounded,
      color: _kBlue,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _typeConfig[notification.type] ??
        (icon: Icons.notifications_rounded, color: _kGrey);
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isUnread ? _kWhite : _kWhite.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: isUnread
              ? Border.all(color: cfg.color.withOpacity(0.25), width: 1.5)
              : Border.all(color: Colors.transparent),
          boxShadow: isUnread
              ? [
                  BoxShadow(
                      color: cfg.color.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 3))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6)
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon bubble
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cfg.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(cfg.icon, color: cfg.color, size: 22),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: _kNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isUnread ? cfg.color : _kGrey,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread ? _kNavy : _kGrey,
                        height: 1.4,
                        fontWeight: isUnread
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cfg.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _typeLabel(notification.type),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: cfg.color,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Unread dot
              if (isUnread)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cfg.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
        'waitlist_promotion'  => 'WAITLIST',
        'subscription_expiry' => 'SUBSCRIPTION',
        'coach_assignment'    => 'COACH',
        'new_message'         => 'MESSAGE',
        _                     => 'NOTIFICATION',
      };

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }
}