import 'package:flutter/material.dart';
import 'package:mobile/navigation/pages.dart';
import 'package:go_router/go_router.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Home'),
            ElevatedButton(
              onPressed:(){
                context.push(Pages.singup);
              }, 
              child: const Text('Go to Signup')
              ),
            ElevatedButton(
              onPressed:(){
                context.push(Pages.login);
              }, 
              child: const Text('Go to Login')
              ),
          ],
        ),
      ),
    );
  }
}
