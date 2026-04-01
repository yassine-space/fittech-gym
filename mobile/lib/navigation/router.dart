import 'package:go_router/go_router.dart';
import 'package:mobile/features/authentication/interface/signup/signup.dart';
import 'package:mobile/home.dart';
import 'package:mobile/features/authentication/interface/login.dart';
import 'package:mobile/navigation/pages.dart';

GoRouter appRouter = GoRouter(
  initialLocation: Pages.home,
  routes: [
    GoRoute(
      path: Pages.home,
      name: Pages.home,
      builder: (context, state) {
        return Home();
      },
    ),
    GoRoute(
      path: Pages.login,
      name: Pages.login,
      builder: (context, state) {
        return Login();
      },
    ),
    GoRoute(
      path: Pages.singup, 
      name: Pages.singup,
      builder: (context, state) {
        return SignupScreen();
      },
    ),
  ],
);
