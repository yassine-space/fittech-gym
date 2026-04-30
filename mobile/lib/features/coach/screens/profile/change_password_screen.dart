import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/providers/coach_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/navigation/pages.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _new2Ctrl = TextEditingController();
  bool _submitting = false;
  bool _showOld = false;
  bool _showNew = false;
  bool _showNew2 = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _new2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final old = _oldCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final newPass2 = _new2Ctrl.text.trim();

    if (old.isEmpty || newPass.isEmpty || newPass2.isEmpty) {
      _snack('Please fill in all fields.', const Color(0xFFE74C3C));
      return;
    }
    if (newPass != newPass2) {
      _snack('New passwords do not match.', const Color(0xFFE74C3C));
      return;
    }
    if (newPass.length < 8) {
      _snack('Password must be at least 8 characters.', const Color(0xFFE74C3C));
      return;
    }

    setState(() => _submitting = true);
    try {
      // Get refresh token from your auth storage
      final refreshToken = ''; // Replace with: await SecureStorage.getRefreshToken();
      await context.read<CoachProvider>().changePassword(
            oldPassword: old,
            newPassword: newPass,
            newPassword2: newPass2,
            refreshToken: refreshToken,
          );
      if (!mounted) return;
      _snack('Password changed. Please log in again.', const Color(0xFF27AE60));
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      // Force logout since backend blacklists the token
      await context.read<CoachProvider>().logout();
      if (!mounted) return;
      context.go(Pages.login);
    } catch (_) {
      setState(() => _submitting = false);
      _snack('Failed. Check your current password.', const Color(0xFFE74C3C));
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
          'CHANGE PASSWORD',
          style: TextStyle(
            color: Color(0xFF1C1C1C),
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD44820).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD44820).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFD44820), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'After changing your password, you will be logged out and need to sign in again.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9A7060),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _PasswordField(
                    label: 'Current Password',
                    controller: _oldCtrl,
                    show: _showOld,
                    onToggle: () => setState(() => _showOld = !_showOld),
                  ),
                  const Divider(height: 24, color: Color(0xFFF0E0D8)),
                  _PasswordField(
                    label: 'New Password',
                    controller: _newCtrl,
                    show: _showNew,
                    onToggle: () => setState(() => _showNew = !_showNew),
                  ),
                  const SizedBox(height: 14),
                  _PasswordField(
                    label: 'Confirm New Password',
                    controller: _new2Ctrl,
                    show: _showNew2,
                    onToggle: () => setState(() => _showNew2 = !_showNew2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD44820),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD44820).withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'Change Password',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool show;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.show,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9A7060))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !show,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: Color(0xFFD1B8A8)),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFD44820), size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF9A7060),
                size: 18,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: const Color(0xFFF5EDE8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}