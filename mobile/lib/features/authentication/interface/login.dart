import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const Text('LOGIN PAGE'),
              ElevatedButton(onPressed:(){
                context.push('/singup');
              }, child: const Text('d\'ont have an acount signup')),
            ],
          ),
        ),
      ),
    );
  }
}