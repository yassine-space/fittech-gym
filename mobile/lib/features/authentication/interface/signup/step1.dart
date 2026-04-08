// step1.dart
import 'package:flutter/material.dart';
import 'package:mobile/navigation/pages.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/signup_provider.dart';
import '../../../../core/widgets/role_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import 'package:go_router/go_router.dart';

class Step1 extends StatefulWidget {
  final VoidCallback onNext;
  const Step1({super.key, required this.onNext});

  @override
  State<Step1> createState() => _Step1State();
}

class _Step1State extends State<Step1> {
  // 0 = member, 1 = coach — kept as int for the RoleButton UI
  int selectedRole = 0;

  late TextEditingController _prenomController;
  late TextEditingController _nomController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SignupProvider>();
    _prenomController = TextEditingController(text: provider.data.prenom);
    _nomController    = TextEditingController(text: provider.data.nom);
    _emailController  = TextEditingController(text: provider.data.email);
    _phoneController  = TextEditingController(text: provider.data.phone);

    // Restore previously selected role index
    if (provider.data.role != null) {
      selectedRole = provider.isMember ? 0 : 1;
    }
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final provider = context.read<SignupProvider>();
    provider.updatePrenom(_prenomController.text);
    provider.updateNom(_nomController.text);
    provider.updateEmail(_emailController.text);
    provider.updatePhone(_phoneController.text);
    // Convert int index → UserRole inside the provider
    provider.updateRoleFromIndex(selectedRole);
    widget.onNext();
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
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Créez votre compte FitTech - Étape 1 sur 3',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(height: 24),

              // Progress bar — step 1
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE50000),
                        borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(3)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                      child: Container(height: 5, color: const Color(0xFFE8E8E8))),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(3)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                "Je suis un(e)",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: RoleButton(
                      title: 'Membre',
                      subtitle: "Je veux m'entraîner",
                      icon: Icons.fitness_center_rounded,
                      isSelected: selectedRole == 0,
                      onTap: () => setState(() => selectedRole = 0),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: RoleButton(
                      title: 'Coach',
                      subtitle: 'Je veux coacher',
                      icon: Icons.school_rounded,
                      isSelected: selectedRole == 1,
                      onTap: () => setState(() => selectedRole = 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Prénom *',
                      hint: 'Akram',
                      controller: _prenomController,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomTextField(
                      label: 'Nom *',
                      hint: 'Teffah',
                      controller: _nomController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              CustomTextField(
                label: 'Email *',
                hint: 'example@gmail.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),

              CustomTextField(
                label: 'Téléphone *',
                hint: '0775091962',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 36),

              PrimaryButton(
                text: 'Suivant >',
                fontSize: 17,
                onPressed: _handleNext,
              ),
              const SizedBox(height: 20),

              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'Vous avez déjà un compte ? ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => context.push(Pages.login),
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