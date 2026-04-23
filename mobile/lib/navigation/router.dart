import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/authentication/emailsend.dart';
import 'package:mobile/features/authentication/forgot.dart';
import 'package:mobile/features/authentication/homescreen.dart' show HomeScreen;
import 'package:mobile/features/authentication/login.dart';
import 'package:mobile/features/authentication/signup/signup.dart';
import 'package:mobile/features/coach/screens/clients_screen.dart';
import 'package:mobile/navigation/pages.dart';
import 'package:mobile/features/coach/screens/coach_dashboard.dart'; 
GoRouter appRouter = GoRouter(
  initialLocation: Pages.coachDashboard,
  routes: [
    GoRoute(
      path: Pages.home,
      name: Pages.home,
     builder: (context, state) => HomeScreen(
  role: 'membre',
  email: (state.extra ?? '') as String,
),
    ),
    GoRoute(
      path: Pages.login,
      name: Pages.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: Pages.singup,
      name: Pages.singup,
      builder: (context, state) => SignupScreen(),
    ),
    GoRoute(
      path: Pages.forgotPassword,
      name: Pages.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: Pages.emailSent,
      name: Pages.emailSent,
      builder: (context, state) => EmailSentScreen(email: state.extra as String),
    ),
    GoRoute(
      path: Pages.membreDashboard,
      name: Pages.membreDashboard,
      builder: (context, state) => HomeScreen(role: 'membre', email: state.extra as String),
    ),
    GoRoute(
      path: Pages.coachDashboard,
      name: Pages.coachDashboard,
      builder: (context, state) => CoachDashboard(
        email: state.extra as String? ?? '',
    )
    ),
  ],
);
