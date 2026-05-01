import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/navigation/pages.dart';

class EmailSentScreen extends StatelessWidget {
  final String email;

  const EmailSentScreen({super.key, required this.email});

  static const Color primaryRed = Color(0xFFCC0000);
  static const Color bgColor = Color(0xFFF9F3F3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Email envoyé !',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Nous avons envoyé un lien de réinitialisation à votre adresse email',
                style: TextStyle(fontSize: 14, color: Colors.black45, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vérifiez votre boîte mail',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF3949AB)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Un email contenant un lien de réinitialisation a été envoyé à $email',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '💡 Le lien est valide pendant 1 heure. Si vous ne recevez pas l\'email, vérifiez votre dossier spam.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF3949AB), height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => context.go(Pages.login),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Retour à la connexion', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email renvoyé !'), backgroundColor: Colors.black54),
                  );
                },
                child: const Text("Renvoyer l'email", style: TextStyle(color: Colors.black45, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
