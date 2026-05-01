import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/navigation/pages.dart';
import 'package:mobile/core/services/apiservice.dart';
import 'package:dio/dio.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedRole = 0;
  int _previousRole = 0;

  final List<String> _roles = ['member', 'coach'];

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  static const Color primaryRed = Color(0xFFCC0000);
  static const Color bgColor = Color(0xFFF9F3F3);
  static const Color fieldBg = Color(0xFFEEEEEE);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _changeRole(int index) {
    setState(() {
      _previousRole = _selectedRole;
      _selectedRole = index;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: primaryRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Image.asset(
                  'assets/images/login.png',
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: List.generate(_roles.length, (index) {
                    final isSelected = _selectedRole == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _changeRole(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              _roles[index],
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                fontSize: 14,
                                color: isSelected ? Colors.black87 : Colors.black45,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  final isGoingRight = _selectedRole > _previousRole;
                  final offsetBegin = isGoingRight ? const Offset(1.0, 0) : const Offset(-1.0, 0);
                  return SlideTransition(
                    position: Tween<Offset>(begin: offsetBegin, end: Offset.zero).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Column(
                  key: ValueKey(_selectedRole),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Email', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'teffah.akram@email.com',
                        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '••••••••••',
                        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black38),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  child: const Text('Mot de passe oublié ?', style: TextStyle(color: Colors.black45, fontSize: 14)),
                ),
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Pas encore membre ?  ", style: TextStyle(color: Colors.black45, fontSize: 14)),
                    TextButton(
                      onPressed: _handleSignUp,
                      style: TextButton.styleFrom(
                        foregroundColor: primaryRed,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("S'inscrire", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }


void _handleLogin() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Remplis tous les champs')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Use Apiservice instead of direct http call
    final response = await Apiservice.instance.login(email, password);

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = response.data;
      debugPrint('✅ LOGIN OK - role: ${data['user']['role']}');

      // Persist auth data and set AuthHolder for Dio-based API calls
      await Apiservice.instance.saveAuthData(
        accessToken: data['access'],
        refreshToken: data['refresh'],
        userId: data['user']['id'],
        userRole: data['user']['role'],
      );

      final role = data['user']['role'];
      if (!mounted) return;

      switch (role) {
        case 'membre':
          context.go(Pages.membreDashboard, extra: email);
          break;
        case 'coach':
          context.go(Pages.coachDashboard, extra: email);
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Role inconnu: $role')),
          );
      }
    }
  } on DioException catch (e) {
    debugPrint('❌ ERROR: $e');
    if (!mounted) return;
    
    String errorMessage = 'Erreur de connexion';
    if (e.response?.statusCode == 403) {
      errorMessage = e.response?.data?['detail'] ?? 'Accès refusé';
    } else if (e.response?.statusCode == 401) {
      errorMessage = 'Email ou mot de passe incorrect';
    } else if (e.response?.data?['detail'] != null) {
      errorMessage = e.response!.data['detail'];
    } else if (e.type == DioExceptionType.connectionTimeout || 
               e.type == DioExceptionType.connectionError) {
      errorMessage = 'Impossible de joindre le serveur';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: primaryRed,
      ),
    );
  } catch (e) {
    debugPrint('❌ ERROR: $e');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible de joindre le serveur')),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}


  void _handleForgotPassword() {
context.go(Pages.forgotPassword);
  }

  void _handleSignUp() {
     context.go(Pages.singup);
  }
}
