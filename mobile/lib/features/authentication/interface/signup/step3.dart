import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/providers/signup_provider.dart';
import '../../../../core/widgets/goal_card.dart';
import '../../../../core/widgets/primary_button.dart';

class Step3 extends StatefulWidget {
  const Step3({super.key});

  @override
  State<Step3> createState() => _Step3State();
}

class _Step3State extends State<Step3> {
  bool _isLoading = false;
  String? _errorMessage;

  // Available fitness goals
  final List<Map<String, dynamic>> _goals = [
    {'label': 'Perdre du poids',     'icon': Icons.monitor_weight_outlined},
    {'label': 'Prendre du muscle',   'icon': Icons.fitness_center},
    {'label': 'Améliorer l\'endurance', 'icon': Icons.directions_run},
    {'label': 'Rester en forme',     'icon': Icons.favorite_outline},
    {'label': 'Réduire le stress',   'icon': Icons.self_improvement},
    {'label': 'Manger sainement',    'icon': Icons.restaurant_outlined},
  ];

  final Set<String> _selected = {};

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      setState(() => _errorMessage = 'Veuillez choisir au moins un objectif.');
      return;
    }

    final provider = context.read<SignupProvider>();
    provider.updateGoals(_selected.toList());

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      // TODO: replace with your real API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        // context.go(Pages.login); // uncomment when ready
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  'Créez votre compte FitTech - Étape 3 sur 3',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              // Progress bar — all filled
              Row(
                children: [
                  Expanded(child: Container(height: 4, color: Colors.red)),
                  const SizedBox(width: 6),
                  Expanded(child: Container(height: 4, color: Colors.red)),
                  const SizedBox(width: 6),
                  Expanded(child: Container(height: 4, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 32),

              const Text('Vos objectifs fitness',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 6),
              Text('Choisissez un ou plusieurs objectifs',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 20),

              // Goals grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: _goals.map((goal) {
                    final isSelected = _selected.contains(goal['label']);
                    return GoalCard(
                      goal: goal,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(goal['label']);
                          } else {
                            _selected.add(goal['label'] as String);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(_errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],

              const SizedBox(height: 16),

              PrimaryButton(
                text: 'Créer mon compte',
                onPressed: _submit,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}