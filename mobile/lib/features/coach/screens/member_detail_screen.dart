// lib/screens/coach/member_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile/core/models/membre_model.dart';
import 'package:intl/intl.dart';

class MemberDetailScreen extends StatelessWidget {
  final Membre membre;

  const MemberDetailScreen({super.key, required this.membre});

  @override
  Widget build(BuildContext context) {
    final joinDate = membre.joinDate != null
        ? DateFormat('MMMM d, yyyy').format(membre.joinDate!)
        : 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C1C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MEMBER PROFILE',
          style: TextStyle(color: Color(0xFF1C1C1C), fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFFD44820),
                    child: Text(
                      membre.user.initials,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    membre.user.fullName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
                  ),
                  Text(
                    membre.user.email,
                    style: const TextStyle(color: Color(0xFF9A7060)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Health Info Section
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
                  valueColor: membre.medicalRestrictions != null ? const Color(0xFFD44820) : null,
                ),
                _InfoTile(
                  icon: Icons.calendar_today,
                  label: 'Member Since',
                  value: joinDate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF9A7060), letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD44820), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9A7060))),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF1C1C1C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}