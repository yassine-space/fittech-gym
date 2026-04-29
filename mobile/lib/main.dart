import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/signup_provider.dart';
import 'package:mobile/core/providers/coach_provider.dart';
import 'package:mobile/core/services/apiservice.dart';
import 'package:mobile/navigation/router.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Apiservice.instance.initToken();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SignupProvider()),
        ChangeNotifierProvider(create: (_) => CoachProvider()),
      ],
      child: MyApp(router: appRouter),
    ),
  );
}

class MyApp extends StatefulWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: widget.router,
    );
  }
}