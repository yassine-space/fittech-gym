// signup_screen.dart
import 'package:dio/dio.dart';
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

  Future<void> _submit() async {
    final signupData = context.read<SignupProvider>().data;
    setState(() => _isLoading = true);

    try {
      // STEP 1: API call
      debugPrint('>>> [SIGNUP] Sending register request...');
      final response = await Apiservice.instance.register(signupData);
      debugPrint('>>> [SIGNUP] Status code: ${response.statusCode}');
      debugPrint('>>> [SIGNUP] Response body: ${response.data}');

      // STEP 2: Parse response
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        debugPrint('>>> [SIGNUP] ERROR: body is ${body.runtimeType}, not a Map');
        _showError('Réponse serveur inattendue.');
        return;
      }

      // STEP 3: Save token
      final accessToken = body['access'] as String?;
      if (accessToken == null) {
        debugPrint('>>> [SIGNUP] ERROR: no "access" key. Keys present: ${body.keys.toList()}');
        _showError('Token manquant dans la réponse serveur.');
        return;
      }
      AuthHolder.token = accessToken;
      debugPrint('>>> [SIGNUP] Token saved OK');

      // STEP 4: Save user id
      final userMap = body['user'] as Map<String, dynamic>?;
      AuthHolder.id = userMap?['id'] as String?;
      debugPrint('>>> [SIGNUP] User id: ${AuthHolder.id}');

      if (!mounted) return;
      context.read<SignupProvider>().reset();

      // STEP 5: Navigate
      final isPendingCoach = body['pending_approval'] == true;
      if (isPendingCoach) {
        debugPrint('>>> [SIGNUP] Coach pending → going to login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Compte créé ! Un administrateur doit approuver votre profil coach avant que vous puissiez vous connecter.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
        context.go(Pages.login);
        return;
      }

      debugPrint('>>> [SIGNUP] Navigating to Pages.home = "${Pages.home}"');
      context.go(Pages.home);
      debugPrint('>>> [SIGNUP] Navigation done');

    } on DioException catch (e) {
      debugPrint('>>> [SIGNUP] DioException type: ${e.type}');
      debugPrint('>>> [SIGNUP] Status: ${e.response?.statusCode}');
      debugPrint('>>> [SIGNUP] Data: ${e.response?.data}');
      if (!mounted) return;
      _showError(_friendlyDioError(e));

    } catch (e, stackTrace) {
      debugPrint('>>> [SIGNUP] Unexpected exception: $e');
      debugPrint('>>> [SIGNUP] Stack: $stackTrace');
      if (!mounted) return;
      _showError('Erreur inattendue : $e');

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE50000),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  String _friendlyDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final messages = data.entries.map((entry) {
        final value = entry.value;
        if (value is List) return value.join(' ');
        return value.toString();
      }).join('\n');
      if (messages.isNotEmpty) return messages;
    }
    if (data is String && data.isNotEmpty) return data;
    switch (e.response?.statusCode) {
      case 400: return 'Données invalides. Vérifiez vos informations.';
      case 401: return 'Non autorisé.';
      case 409: return 'Un compte avec cet email existe déjà.';
      case 500: return 'Erreur serveur. Réessayez plus tard.';
      default:  return 'Une erreur est survenue. Vérifiez votre connexion et réessayez.';
    }
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