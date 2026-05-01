// lib/features/coach/coach_router.dart
import 'package:go_router/go_router.dart';
import 'screens/coach_dashboard.dart';

final coachRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/dashboard',
      name: 'coachDashboard',
      builder: (context, state) => const CoachDashboard(email: String.fromEnvironment(""),),
    ),
    // Add coach-specific routes here
  ],
);