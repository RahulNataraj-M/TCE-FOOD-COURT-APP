import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/app_scope.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final services = AppServices.production();
  // A missing Google web client ID must not prevent the login screen from
  // rendering. AuthService reports this configuration error when sign-in is
  // attempted.
  await services.initialize();

  runApp(TceFoodCourtApp(services: services));
}

class TceFoodCourtApp extends StatefulWidget {
  const TceFoodCourtApp({super.key, this.services});

  /// Firebase dependencies. Left null only in tests that build the app without
  /// a Firebase project behind it.
  final AppServices? services;

  @override
  State<TceFoodCourtApp> createState() => _TceFoodCourtAppState();
}

class _TceFoodCourtAppState extends State<TceFoodCourtApp> {
  late final AppServices _services = widget.services ?? AppServices.production();

  @override
  void initState() {
    super.initState();
    // Menu and orders load in the background: the bundled catalog renders
    // immediately and is replaced once Firestore answers.
    _services.loadData();
  }

  @override
  void dispose() {
    if (widget.services == null) _services.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: _services,
      child: MaterialApp(
        title: 'TCE Food Court',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AuthGate(),
      ),
    );
  }
}