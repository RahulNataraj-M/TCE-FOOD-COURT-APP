import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';

import '../models/app_role.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/login_screen.dart';
import '../screens/staff/staff_shell.dart';
import '../services/app_scope.dart';
import 'bottom_nav.dart';

/// Chooses the app's root screen from the Firebase Auth session and role.
///
/// Session state is the single source of truth, so signing in or out moves the
/// user between the login screen and the appropriate shell:
///   * Student  → [MainShell]     (Home / Profile)
///   * Staff    → [StaffShell]    (Orders / Profile)
///   * Admin    → [AdminShell]    (Menu / Users / Profile)
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
        return const _RoleGate();
      },
    );
  }
}

/// Resolves the signed-in user's role and renders the matching shell.
class _RoleGate extends StatefulWidget {
  const _RoleGate();

  @override
  State<_RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<_RoleGate> {
  Future<AppRole>? _roleFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolve the role once, after dependencies are available.
    _roleFuture ??= AppScope.of(context).authService.currentRole();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppRole>(
      future: _roleFuture,
      builder: (context, snapshot) {
        // While the role is loading, show the student shell so the app is
        // usable immediately; it swaps once the role resolves.
        if (!snapshot.hasData) return const MainShell();
        switch (snapshot.data!) {
          case AppRole.staff:
            return const StaffShell();
          case AppRole.admin:
            return const AdminShell();
          case AppRole.student:
            return const MainShell();
        }
      },
    );
  }
}

/// Convenience accessor for the signed-in user inside the main scaffold.
User? currentUserOf(BuildContext context) {
  return AppScope.of(context).authService.currentUser;
}