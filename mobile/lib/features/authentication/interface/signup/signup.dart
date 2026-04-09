// signup_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile/core/services/apiservice.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/navigation/pages.dart';
import 'package:mobile/core/providers/signup_provider.dart';
import 'step1.dart';
import 'step2.dart';
import 'step3.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _controller = PageController();
  bool _isLoading = false;

  void _nextPage() => _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );

  void _previousPage() => _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );

  /// Called by Step3 when the user taps "Créer mon compte".
  /// Sends the multipart request and navigates on success.
  Future<void> _submit() async {
    final signupData = context.read<SignupProvider>().data;

    setState(() => _isLoading = true);

    try {
      final response = await Apiservice.instance.register(signupData);

      // ── Save token + id returned by Django ──────────────────────────────
      // Adjust key names to match your Django response JSON.
      // e.g. { "access": "eyJ...", "refresh": "eyJ...", "id": 42 }
      final body = response.data as Map<String, dynamic>;
      AuthHolder.token = body['access'] as String?;
      AuthHolder.id    = body['id']     as int?;

      if (!mounted) return;

      // Clear signup state so the form is fresh if the user signs up again.
      context.read<SignupProvider>().reset();

      // Navigate to home (or wherever post-signup should land).
      context.go(Pages.home);

    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e)),
          backgroundColor: const Color(0xFFE50000),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(Exception e) {
    return 'Une erreur est survenue. Vérifiez votre connexion et réessayez.';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: PageView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              Step1(onNext: _nextPage),
              Step2(onNext: _nextPage, onPrevious: _previousPage),
              Step3(onNext: _submit, onPrevious: _previousPage),
            ],
          ),
        ),

        // Full-screen loading overlay while the request is in-flight.
        if (_isLoading)
          const Opacity(
            opacity: 0.6,
            child: ModalBarrier(dismissible: false, color: Colors.black),
          ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFE50000)),
          ),
      ],
    );
  }
}