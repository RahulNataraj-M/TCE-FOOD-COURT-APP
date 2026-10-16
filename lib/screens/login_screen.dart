import 'package:flutter/material.dart';

import '../models/app_role.dart';
import '../services/app_scope.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSigningIn = false;
  AppRole _selectedRole = AppRole.student;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Runs the real Google sign-in through [AuthService].
  ///
  /// On success the [AuthGate] rebuilds with the signed-in session, so no manual
  /// navigation happens here.
  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);

    final messenger = ScaffoldMessenger.of(context);
    final authService = AppScope.of(context).authService;

    try {
      await authService.signInWithGoogle();
    } on AuthFailure catch (failure) {
      if (failure.reason == AuthFailureReason.cancelled) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(failure.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on Object {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sign-in failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signInWithEmailPassword() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);

    final messenger = ScaffoldMessenger.of(context);
    final authService = AppScope.of(context).authService;

    try {
      await authService.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
        role: _selectedRole,
      );
    } on AuthFailure catch (failure) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(failure.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on Object {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Email sign-in failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _createAccount() async {
    if (_isSigningIn) return;
    final details = await showDialog<_RegistrationDetails>(
      context: context,
      builder: (_) => const _RegistrationDialog(),
    );
    if (!mounted || details == null) return;

    setState(() => _isSigningIn = true);
    final messenger = ScaffoldMessenger.of(context);
    final authService = AppScope.of(context).authService;
    try {
      await authService.createAccountWithEmailPassword(
        firstName: details.firstName,
        lastName: details.lastName,
        phoneNumber: details.phoneNumber,
        email: details.email,
        password: details.password,
      );
    } on AuthFailure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    } on Object {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Account creation failed. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const _LoginHeader(),
                const SizedBox(height: AppSpacing.xl),
                SegmentedButton<AppRole>(
                  segments: const [
                    ButtonSegment(
                      value: AppRole.student,
                      label: Text('Student'),
                      icon: Icon(Icons.school, size: 18),
                    ),
                    ButtonSegment(
                      value: AppRole.staff,
                      label: Text('Staff'),
                      icon: Icon(Icons.restaurant, size: 18),
                    ),
                    ButtonSegment(
                      value: AppRole.admin,
                      label: Text('Admin'),
                      icon: Icon(Icons.admin_panel_settings, size: 18),
                    ),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedRole = selection.first);
                  },
                  showSelectedIcon: false,
                ),
                const SizedBox(height: AppSpacing.xl),
                _LoginMessage(role: _selectedRole),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enabled: !_isSigningIn,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: _selectedRole == AppRole.student
                        ? 'you@student.tce.edu'
                        : 'you@tce.edu',
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  enabled: !_isSigningIn,
                  onSubmitted: (_) => _signInWithEmailPassword(),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isSigningIn ? null : _signInWithEmailPassword,
                    child: Text(_selectedRole == AppRole.student
                        ? 'Sign in with email'
                        : 'Sign in'),
                  ),
                ),
                if (_selectedRole == AppRole.student) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isSigningIn ? null : _createAccount,
                      child: const Text('New user? Create an account'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _OrDivider(),
                  const SizedBox(height: AppSpacing.md),
                  _GoogleButton(isBusy: _isSigningIn, onTap: _signInWithGoogle),
                ],
                const SizedBox(height: AppSpacing.xl),
                _LoginFooter(role: _selectedRole),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text('OR', style: Theme.of(context).textTheme.labelSmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _RegistrationDetails {
  const _RegistrationDetails({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String password;
}

class _RegistrationDialog extends StatefulWidget {
  const _RegistrationDialog();

  @override
  State<_RegistrationDialog> createState() => _RegistrationDialogState();
}

class _RegistrationDialogState extends State<_RegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? 'Enter your $label.' : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _RegistrationDetails(
        firstName: _firstName.text,
        lastName: _lastName.text,
        phoneNumber: _phone.text,
        email: _email.text,
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create account'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (value) => _required(value, 'first name'),
              ),
              TextFormField(
                controller: _lastName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: (value) => _required(value, 'last name'),
              ),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number'),
                validator: (value) => _required(value, 'phone number'),
              ),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Student email',
                  hintText: 'you@student.tce.edu',
                ),
                validator: (value) {
                  final email = value?.trim().toLowerCase() ?? '';
                  if (!AuthService.isAllowedEmail(email)) {
                    return 'Use your @student.tce.edu email.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  helperText: 'At least 6 characters',
                ),
                validator: (value) => (value ?? '').length < 6
                    ? 'Use at least 6 characters.'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create account')),
      ],
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Image.asset(
            'assets/images/tce-logo.png',
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) {
              return Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'TCE',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'TCE Food Court',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            height: 40 / 32,
            letterSpacing: -0.64,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'ORDER. PAY. ENJOY.',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LoginMessage extends StatelessWidget {
  final AppRole role;

  const _LoginMessage({required this.role});

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (role) {
      AppRole.student => (
          'Welcome Back',
          'Order food from your campus food court quickly and efficiently.',
        ),
      AppRole.staff => (
          'Staff Login',
          'Sign in to view incoming orders and update their status.',
        ),
      AppRole.admin => (
          'Admin Login',
          'Sign in to manage menu items, prices, availability, and users.',
        ),
    };
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 16,
            height: 24 / 16,
            color: AppColors.secondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isBusy;

  const _GoogleButton({required this.onTap, this.isBusy = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: isBusy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: isBusy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onPrimary,
                ),
              )
            : const Icon(Icons.login, size: 20),
        label: Text(
          isBusy ? 'Signing in...' : 'Continue with Google',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  final AppRole role;

  const _LoginFooter({required this.role});

  @override
  Widget build(BuildContext context) {
    final (heading, detail) = switch (role) {
      AppRole.student => (
          'Use your student email account',
          'Only @student.tce.edu accounts can access the application.',
        ),
      AppRole.staff => (
          'Food Court Staff',
          'Use your staff email and password to sign in.',
        ),
      AppRole.admin => (
          'Administrator',
          'Use your admin email and password to sign in.',
        ),
    };
    return Column(
      children: [
        const Divider(color: AppColors.borderSubtle),
        const SizedBox(height: AppSpacing.sm),
        Text(
          heading,
          style: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onBackground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          style: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            color: AppColors.secondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
