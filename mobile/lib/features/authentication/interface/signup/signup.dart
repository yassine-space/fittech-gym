//👉 This is the main screen that controls navigation

import 'package:flutter/material.dart';
import 'step1.dart';
import 'step2.dart';
import 'step3.dart';
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController controller = PageController();

  void nextPage() {
    controller.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller,
        physics: NeverScrollableScrollPhysics(),
        children: [
          Step1(onNext: nextPage),
          Step2(onNext: nextPage),
          Step3(),
        ],
      ),
    );
  }
}