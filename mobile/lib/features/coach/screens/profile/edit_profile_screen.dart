import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/providers/coach_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _specialtiesCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CoachProvider>();
    final profile = provider.profile;
    if (profile != null) {
      _firstNameCtrl.text = profile.user.firstName;
      _lastNameCtrl.text = profile.user.lastName;
      _phoneCtrl.text = profile.user.phone ?? '';
      _specialtiesCtrl.text = profile.specialties ?? '';
      _bioCtrl.text = profile.biography ?? '';
      _experienceCtrl.text = '${profile.yearsOfExperience}';
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _specialtiesCtrl.dispose();
    _bioCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _submitting = true);
    final provider = context.read<CoachProvider>();
    try {
      await provider.updateUserInfo(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      await provider.updateCoachProfile(
        specialties: _specialtiesCtrl.text.trim(),
        biography: _bioCtrl.text.trim(),
        yearsOfExperience: int.tryParse(_experienceCtrl.text.trim()) ?? 0,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile.'),
          backgroundColor: Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'EDIT PROFILE',
          style: TextStyle(
            color: Color(0xFF1C1C1C),
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _save,
            child: _submitting
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(
                        color: Color(0xFFD44820), strokeWidth: 2))
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFFD44820),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: 'PERSONAL INFO',
              children: [
                _Field(label: 'First Name', controller: _firstNameCtrl,
                    icon: Icons.person_outline),
                _Field(label: 'Last Name', controller: _lastNameCtrl,
                    icon: Icons.person_outline),
                _Field(label: 'Phone', controller: _phoneCtrl,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
              ],
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'COACH DETAILS',
              children: [
                _Field(
                  label: 'Specialties',
                  controller: _specialtiesCtrl,
                  icon: Icons.fitness_center_outlined,
                  hint: 'e.g. Yoga, HIIT, Pilates',
                ),
                _Field(
                  label: 'Biography',
                  controller: _bioCtrl,
                  icon: Icons.info_outline,
                  maxLines: 4,
                  hint: 'Tell members about yourself...',
                ),
                _Field(
                  label: 'Years of Experience',
                  controller: _experienceCtrl,
                  icon: Icons.timeline,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800,
                color: Color(0xFF9A7060), letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? hint;

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: Color(0xFF9A7060))),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFD1B8A8), fontSize: 13),
              prefixIcon: maxLines == 1
                  ? Icon(icon, color: const Color(0xFFD44820), size: 18)
                  : null,
              filled: true,
              fillColor: const Color(0xFFF5EDE8),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}