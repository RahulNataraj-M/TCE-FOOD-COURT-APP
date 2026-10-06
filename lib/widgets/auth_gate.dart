import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../services/app_scope.dart';

/// Chooses the app's root screen from the Firebase Auth session.
///
/// Session state is the single source of truth, so signing in or out moves the
/// user between the login screen and the home screen without any manual
/// navigation. The signed-in destination matches the one the login screen used
/// to push by hand.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AppScope.of(context).authService;
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      initialData: authService.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return const HomeScreen();
      },
    );
  }
}

/// Convenience accessor for the signed-in user inside the main scaffold.
User? currentUserOf(BuildContext context) {
  return AppScope.of(context).authService.currentUser;
}