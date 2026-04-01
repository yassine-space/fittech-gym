import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/providers/signup_provider.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';

class Step2 extends StatefulWidget {
  final VoidCallback onNext;
  const Step2({super.key, required this.onNext});

  @override
  State<Step2> createState() => _Step2State();
}

class _Step2State extends State<Step2> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  void _next() {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Minimum 6 caractères.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Les mots de passe ne correspondent pas.');
      return;
    }

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text('Inscription',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Créez votre compte FitTech - Étape 2 sur 3',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              // Progress bar
              Row(
                children: [
                  Expanded(child: Container(height: 4, color: Colors.red)),
                  const SizedBox(width: 6),
                  Expanded(child: Container(height: 4, color: Colors.red)),
                  const SizedBox(width: 6),
                  Expanded(child: Container(height: 4, color: Colors.grey[300])),
                ],
              ),
              const SizedBox(height: 40),

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
              const Text('Minimum 6 caractères',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 20),

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
                Text(_errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],

              const Spacer(),

              PrimaryButton(
                text: 'Suivant',
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}