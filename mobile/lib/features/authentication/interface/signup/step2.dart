import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/providers/signup_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/navigation/pages.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';

class Step2 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  const Step2({super.key, required this.onNext, required this.onPrevious});

  @override
  State<Step2> createState() => _Step2State();
}

class _Step2State extends State<Step2> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SignupProvider>();
    _passwordController.text = provider.data.password;
    _confirmController.text = provider.data.password;
  }

  void _back() {
    widget.onPrevious();
  }

  void _next() {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    //if (password.isEmpty || confirm.isEmpty) {
      //setState(() => _errorMessage = 'Veuillez remplir tous les champs.');
      //return;
    //}
    //if (password.length < 6) {
      //setState(() => _errorMessage = 'Minimum 6 caractères.');
      //return;
    //}
    //if (password != confirm) {
      //setState(
        //  () => _errorMessage = 'Les mots de passe ne correspondent pas.');
      //return;
    //}

    context.read<SignupProvider>().updatePassword(password);
    setState(() => _errorMessage = null);
    widget.onNext();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Inscription',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              Center(
                child: Text(
                  'Créez votre compte FitTech - Étape 2 sur 3',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Progress bar — 2 of 3 filled
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE50000),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      height: 5,
                      color: const Color(0xFFE50000),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              CustomTextField(
                label: 'Mot de passe *',
                hint: '••••••••••',
                controller: _passwordController,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Minimum 6 caractères',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 18),

              CustomTextField(
                label: 'Confirmer le mot de passe *',
                hint: '••••••••••',
                controller: _confirmController,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFE50000), fontSize: 13),
                ),
              ],

              const SizedBox(height: 36),

              // Buttons row: outlined Retour + filled Suivant
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _back,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.grey.shade200,
                        side:BorderSide.none,
                      ),
                      child: const Text(
                        '<  Retour',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Suivant >',
                      fontSize: 17,
                      onPressed: _next,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Already have an account
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'Vous avez déjà un compte ? ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            context.push(Pages.login);
                          },
                          child: const Text(
                            'Se connecter',
                            style: TextStyle(
                              color: Color(0xFFE50000),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}