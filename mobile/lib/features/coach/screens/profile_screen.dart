import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/coach_provider.dart';
import 'package:mobile/core/models/coach_profile_model.dart';
import 'package:mobile/navigation/pages.dart';
// Screens navigated to from here
import 'package:mobile/features/coach/screens/profile/edit_profile_screen.dart';
import 'package:mobile/features/coach/screens/profile/change_password_screen.dart';
import 'package:mobile/features/coach/screens/profile/certificates_screen.dart';
import 'package:mobile/features/coach/screens/profile/reviews_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CoachProvider>(
      builder: (context, provider, _) {
        // ── Loading state ──────────────────────────────────────────────────
        if (provider.profileLoading && provider.profile == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5EDE8),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFD44820)),
            ),
          );
        }

        // ── Error state ────────────────────────────────────────────────────
        if (provider.profileError != null && provider.profile == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5EDE8),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Color(0xFFD44820)),
                  const SizedBox(height: 12),
                  const Text('Failed to load profile',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => provider.loadProfile(),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD44820)),
                    child: const Text('Retry',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        final profile = provider.profile;
        final clientCount = provider.members.length;
        final reviewCount = provider.reviews.length;
        final certCount = provider.certificates.length;
        final avgRating = provider.averageRating;

        return Scaffold(
          backgroundColor: const Color(0xFFF5EDE8),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── App-bar row ──────────────────────────────────────────
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF8B4513),
                        child: profile != null
                            ? Text(
                                profile.user.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : const Icon(Icons.person,
                                color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'PERFORMANCE LAB',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD44820),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.notifications_none,
                          color: Color(0xFF1C1C1C), size: 24),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Title ────────────────────────────────────────────────
                  const Text(
                    'PROFILE',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1C1C1C),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage your account settings and preferences.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9A7060),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Profile card ─────────────────────────────────────────
                  _ProfileCard(
                    profile: profile,
                    onEditTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Coaching status ──────────────────────────────────────
                  _SettingsSection(
                    title: 'COACHING STATUS',
                    items: [
                      _SettingsItem(
                        icon: Icons.people_outline,
                        title: 'Active Clients',
                        subtitle: 'You are managing $clientCount members',
                        trailing: '$clientCount',
                        trailingColor: const Color(0xFF3DB87A),
                      ),
                      _SettingsItem(
                        icon: Icons.star_half_rounded,
                        title: 'My Rating',
                        subtitle: reviewCount == 0
                            ? 'No reviews yet'
                            : '$reviewCount review${reviewCount == 1 ? '' : 's'} from members',
                        trailing: reviewCount == 0
                            ? '—'
                            : avgRating.toStringAsFixed(1),
                        trailingColor: const Color(0xFFD44820),
                        onTap: () => _goToReviews(context, provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Account settings ─────────────────────────────────────
                  _SettingsSection(
                    title: 'ACCOUNT SETTINGS',
                    items: [
                      _SettingsItem(
                        icon: Icons.person_outline,
                        title: 'Personal Information',
                        subtitle: profile != null
                            ? '${profile.user.fullName} · ${profile.user.phone ?? "No phone"}'
                            : 'Name, email, phone number',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfileScreen()),
                        ),
                      ),
                      _SettingsItem(
                        icon: Icons.lock_outline,
                        title: 'Security',
                        subtitle: 'Change your password',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen()),
                        ),
                      ),
                      const _SettingsItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Push notifications, email alerts',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Coach details ────────────────────────────────────────
                  if (profile != null) ...[
                    _SettingsSection(
                      title: 'COACH DETAILS',
                      items: [
                        _SettingsItem(
                          icon: Icons.fitness_center_outlined,
                          title: 'Specialties',
                          subtitle: profile.specialties?.isNotEmpty == true
                              ? profile.specialties!
                              : 'Not set — tap to edit',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen()),
                          ),
                        ),
                        _SettingsItem(
                          icon: Icons.info_outline,
                          title: 'Biography',
                          subtitle: profile.biography?.isNotEmpty == true
                              ? profile.biography!
                              : 'Not set — tap to edit',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen()),
                          ),
                        ),
                        _SettingsItem(
                          icon: Icons.timeline,
                          title: 'Experience',
                          subtitle: '${profile.yearsOfExperience} years of coaching',
                          trailing: '${profile.yearsOfExperience}y',
                        ),
                        _SettingsItem(
                          icon: Icons.workspace_premium_outlined,
                          title: 'My Certificates',
                          subtitle: certCount == 0
                              ? 'Add your coaching credentials'
                              : '$certCount certificate${certCount == 1 ? '' : 's'} on file',
                          trailing: certCount > 0 ? '$certCount' : null,
                          onTap: () => _goToCertificates(context, provider),
                        ),
                        _SettingsItem(
                          icon: Icons.reviews_outlined,
                          title: 'Member Reviews',
                          subtitle: reviewCount == 0
                              ? 'Reviews appear after members attend your courses'
                              : 'Avg ${avgRating.toStringAsFixed(1)} ★ · $reviewCount review${reviewCount == 1 ? '' : 's'}',
                          trailing: reviewCount > 0
                              ? '${avgRating.toStringAsFixed(1)}★'
                              : null,
                          trailingColor: const Color(0xFFD44820),
                          onTap: () => _goToReviews(context, provider),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Preferences ──────────────────────────────────────────
                  const _SettingsSection(
                    title: 'PREFERENCES',
                    items: [
                      _SettingsItem(
                        icon: Icons.language_outlined,
                        title: 'Language',
                        subtitle: 'English',
                        trailing: 'EN',
                      ),
                      _SettingsItem(
                        icon: Icons.attach_money,
                        title: 'Currency',
                        subtitle: 'USD - US Dollar',
                        trailing: '\$',
                      ),
                      _SettingsItem(
                        icon: Icons.calendar_today_outlined,
                        title: 'Time Zone',
                        subtitle: 'Eastern Time (ET)',
                        trailing: 'ET',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Support ──────────────────────────────────────────────
                  const _SettingsSection(
                    title: 'SUPPORT',
                    items: [
                      _SettingsItem(
                        icon: Icons.help_outline,
                        title: 'Help Center',
                        subtitle: 'FAQs and guides',
                      ),
                      _SettingsItem(
                        icon: Icons.email_outlined,
                        title: 'Contact Support',
                        subtitle: 'Get help from our team',
                      ),
                      _SettingsItem(
                        icon: Icons.description_outlined,
                        title: 'Terms & Privacy',
                        subtitle: 'Legal information',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Danger zone ──────────────────────────────────────────
                  _DangerZone(
                    onSignOut: () => _handleSignOut(context, provider),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Navigation helpers ─────────────────────────────────────────────────────

  void _goToReviews(BuildContext context, CoachProvider provider) {
    provider.loadReviews();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReviewsScreen()),
    );
  }

  void _goToCertificates(BuildContext context, CoachProvider provider) {
    provider.loadCertificates();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CertificatesScreen()),
    );
  }

  Future<void> _handleSignOut(
      BuildContext context, CoachProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9A7060))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD44820),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    await provider.logout();
    if (!context.mounted) return;
    context.go(Pages.login);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProfileCard
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final CoachProfile? profile;
  final VoidCallback onEditTap;

  const _ProfileCard({this.profile, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    final name = profile?.user.fullName ?? 'Coach';
    final email = profile?.user.email ?? '';
    final initials = profile?.user.initials ?? 'CO';
    final specialties = profile?.specialtiesList ?? [];
    final isApproved = profile?.isActive ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // ── Avatar ───────────────────────────────────────────────────────
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFD44820), Color(0xFFE8653A)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: profile?.user.profilePhoto != null
                  ? Image.network(
                      profile!.user.profilePhoto!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initialsText(initials),
                    )
                  : _initialsText(initials),
            ),
          ),
          const SizedBox(width: 16),

          // ── Info ─────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9A7060),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Status badge
                    _Badge(
                      label: isApproved ? 'Active' : 'Pending',
                      icon: isApproved
                          ? Icons.check_circle
                          : Icons.hourglass_top_rounded,
                      color: isApproved
                          ? const Color(0xFF3DB87A)
                          : Colors.orange,
                    ),
                    if (specialties.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: _Badge(
                          label: specialties.first,
                          icon: Icons.verified,
                          color: const Color(0xFFD44820),
                          overflow: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Edit button ──────────────────────────────────────────────────
          GestureDetector(
            onTap: onEditTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EDE8),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFD44820)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsText(String initials) => Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
}

// Small colored badge used inside the profile card
class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool overflow;

  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
    this.overflow = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        overflow
            ? Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700, color: color),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700, color: color),
              ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: content,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SettingsSection
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF9A7060),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: Color(0xFFF0E0D8)),
                items[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SettingsItem
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final Color? trailingColor;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.trailingColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EDE8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFFD44820)),
              ),
              const SizedBox(width: 14),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9A7060),
                      ),
                    ),
                  ],
                ),
              ),

              // Optional trailing badge
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (trailingColor ?? const Color(0xFFD44820))
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trailing!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: trailingColor ?? const Color(0xFFD44820),
                    ),
                  ),
                ),
              ],

              const SizedBox(width: 4),
              Icon(
                onTap != null
                    ? Icons.chevron_right
                    : Icons.chevron_right,
                size: 18,
                color: onTap != null
                    ? const Color(0xFFD1B8A8)
                    : const Color(0xFFE8D8D0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DangerZone
// ─────────────────────────────────────────────────────────────────────────────
class _DangerZone extends StatelessWidget {
  final VoidCallback onSignOut;
  const _DangerZone({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DANGER ZONE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFFD44820),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: const Color(0xFFD44820).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              // Sign out
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSignOut,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBE8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.logout,
                              size: 20, color: Color(0xFFD44820)),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign Out',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD44820),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Log out of your account',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF9A7060)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 18, color: Color(0xFFD44820)),
                      ],
                    ),
                  ),
                ),
              ),

              Divider(
                  height: 1,
                  color: const Color(0xFFD44820).withOpacity(0.1)),

              // Delete account
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // TODO: implement account deletion if backend supports it
                  },
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBE8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete_outline,
                              size: 20, color: Color(0xFFD44820)),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delete Account',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD44820),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Permanently delete your account and data',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF9A7060)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.warning_amber_rounded,
                            size: 18, color: Color(0xFFD44820)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}