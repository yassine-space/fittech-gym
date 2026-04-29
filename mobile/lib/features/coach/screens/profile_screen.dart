import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/coach_provider.dart';
import 'package:mobile/core/models/coach_profile_model.dart';
import 'package:mobile/navigation/pages.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CoachProvider>(
      builder: (context, provider, _) {
        if (provider.profileLoading && provider.profile == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5EDE8),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFD44820))),
          );
        }

        if (provider.profileError != null && provider.profile == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5EDE8),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Color(0xFFD44820)),
                  const SizedBox(height: 12),
                  const Text('Failed to load profile', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => provider.loadProfile(),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD44820)),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        final profile = provider.profile;

        return Scaffold(
          backgroundColor: const Color(0xFFF5EDE8),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF8B4513),
                        child: const Icon(Icons.person, color: Colors.white, size: 18),
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
                      const Icon(Icons.notifications_none, color: Color(0xFF1C1C1C), size: 24),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Profile Title
                  const Text(
                    'PROFILE',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1C1C1C),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage your account settings and preferences.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9A7060),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Card — dynamic data
                  _ProfileCard(profile: profile),
                  const SizedBox(height: 20),

                  // Account Settings
                  _SettingsSection(
                    title: 'ACCOUNT SETTINGS',
                    items: [
                      _SettingsItem(
                        icon: Icons.person_outline,
                        title: 'Personal Information',
                        subtitle: profile != null
                            ? '${profile.user.fullName} · ${profile.user.email}'
                            : 'Name, email, phone number',
                      ),
                      const _SettingsItem(
                        icon: Icons.lock_outline,
                        title: 'Security',
                        subtitle: 'Password, two-factor authentication',
                      ),
                      const _SettingsItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Push notifications, email alerts',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Coach Info
                  if (profile != null)
                    _SettingsSection(
                      title: 'COACH DETAILS',
                      items: [
                        _SettingsItem(
                          icon: Icons.star_outline,
                          title: 'Specialties',
                          subtitle: profile.specialties?.isNotEmpty == true
                              ? profile.specialties!
                              : 'Not set',
                        ),
                        _SettingsItem(
                          icon: Icons.info_outline,
                          title: 'Biography',
                          subtitle: profile.biography?.isNotEmpty == true
                              ? profile.biography!
                              : 'Not set',
                        ),
                        _SettingsItem(
                          icon: Icons.timeline,
                          title: 'Experience',
                          subtitle: '${profile.yearsOfExperience} years',
                        ),
                      ],
                    ),
                  if (profile != null) const SizedBox(height: 20),

                  // Preferences
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

                  // Support
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

                  // Danger Zone
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

  Future<void> _handleSignOut(BuildContext context, CoachProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9A7060))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD44820),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
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

class _ProfileCard extends StatelessWidget {
  final CoachProfile? profile;
  const _ProfileCard({this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?.user.fullName ?? 'Coach';
    final email = profile?.user.email ?? '';
    final initials = profile?.user.initials ?? 'CO';
    final specialties = profile?.specialtiesList ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Avatar
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
            child: Center(
              child: profile?.user.profilePhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        profile!.user.profilePhoto!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9A7060),
                  ),
                ),
                const SizedBox(height: 8),
                if (specialties.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD44820).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 12, color: Color(0xFFD44820)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            specialties.first,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD44820),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD44820).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 12, color: Color(0xFFD44820)),
                        SizedBox(width: 4),
                        Text(
                          'Coach',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD44820),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Edit button
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EDE8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFD44820)),
          ),
        ],
      ),
    );
  }
}

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
                if (i > 0) const Divider(height: 1, color: Color(0xFFF0E0D8)),
                items[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final Color? trailingColor;

  const _SettingsItem({
  required this.icon,
  required this.title,
  required this.subtitle,
  this.trailingColor,
  this.trailing,
});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EDE8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFFD44820)),
              ),
              const SizedBox(width: 14),
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
              if (trailing != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trailingColor == const Color(0xFF3DB87A)
                        ? const Color(0xFF3DB87A).withOpacity(0.1)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trailing!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: trailingColor ?? const Color(0xFFD44820),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: Color(0xFFD1B8A8)),
            ],
          ),
        ),
      ),
    );
  }
}

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
            border: Border.all(color: const Color(0xFFD44820).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSignOut,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBE8),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: const Icon(Icons.logout, size: 20, color: Color(0xFFD44820)),
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
                                  fontSize: 11,
                                  color: Color(0xFF9A7060),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.logout, size: 18, color: Color(0xFFD44820)),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: const Color(0xFFD44820).withOpacity(0.1)),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFFFEBE8),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.delete_outline, size: 20, color: Color(0xFFD44820)),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
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
                                  fontSize: 11,
                                  color: Color(0xFF9A7060),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.warning, size: 18, color: Color(0xFFD44820)),
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