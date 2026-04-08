// signup_screen.dart
// Main screen that controls multi-step signup navigation.

import 'package:flutter/material.dart';
import 'step1.dart';
import 'step2.dart';
import 'step3.dart'; // exports the Step3 router widget

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _controller = PageController();

  void _nextPage() => _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );

  void _previousPage() => _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        // Disable swipe — navigation is only via buttons so the provider
        // always has the latest typed values before moving between pages.
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Step1(onNext: _nextPage),
          Step2(onNext: _nextPage, onPrevious: _previousPage),
          // Step3 is a router: it reads the role from SignupProvider and
          // renders Step3Member or Step3Coach automatically.
          Step3(onNext: () {}, onPrevious: _previousPage),
        ],
      ),
    );
  }
}