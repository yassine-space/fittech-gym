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
  int selectedRole = 0;

  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleNext() {
    // Basic validation
    if (_prenomController.text.isEmpty ||
        _nomController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    final provider = context.read<SignupProvider>();

    // Save data
    provider.updateEmail(_emailController.text);
    provider.updatePhone(_phoneController.text);
    
    // Go to next step
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
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              Center(
                child: Text(
                  'Créez votre compte FitTech - Étape 1 sur 3',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Progress bar
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
                    child: Container(height: 5, color: const Color(0xFFE8E8E8)),
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
                      hint: 'akram',
                      controller: _prenomController,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomTextField(
                      label: 'Nom *',
                      hint: 'teffah',
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
                           onTap: () {
                              // Navigate to login page
                              context.push(Pages.login);
                           },
                           child: Text(
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