import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_role.dart';
import '../../models/user_profile.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';

/// Admin user management: lists all users with their current role and allows
/// promoting/demoting between student, staff, and admin.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<UserProfile> _users = const [];
  bool _isLoading = true;
  Object? _error;
  String _search = '';
  bool _didSubscribe = false;
  StreamSubscription<List<UserProfile>>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSubscribe) return;
    _didSubscribe = true;
    _subscribe();
  }

  /// Subscribes to the live users collection so role changes show up at once.
  void _subscribe() {
    _subscription?.cancel();
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _subscription =
        AppScope.of(context).userRepository.watchUsers().listen(
      (users) {
        if (!mounted) return;
        setState(() {
          _users = users;
          _isLoading = false;
          _error = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _error = error;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _changeRole(UserProfile user, AppRole newRole) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppScope.of(context).userRepository.updateRole(user.uid, newRole);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update role: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<UserProfile> get _filtered {
    if (_search.isEmpty) return _users;
    final q = _search.toLowerCase();
    return _users
        .where(
          (u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Users',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: const InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: AppColors.error),
                            const SizedBox(height: AppSpacing.sm),
                            Text('$_error'),
                            const SizedBox(height: AppSpacing.md),
                            FilledButton(
                              onPressed: _subscribe,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _subscribe(),
                        child: ListView(
                          padding: const EdgeInsets.all(
                            AppSpacing.marginMobile,
                          ),
                          children: [
                            for (final user in _filtered)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _UserCard(
                                  user: user,
                                  onChanged: (role) =>
                                      _changeRole(user, role),
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserProfile user;
  final ValueChanged<AppRole> onChanged;

  const _UserCard({required this.user, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final role = user.role;
    final roleColor = switch (role) {
      AppRole.student => AppColors.secondary,
      AppRole.staff => AppColors.tertiary,
      AppRole.admin => AppColors.primary,
    };
    final name = user.fullName;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: roleColor.withValues(alpha: 0.15),
            child: Text(
              (name.isEmpty ? '?' : name[0]).toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w700, color: roleColor),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Unknown' : name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: roleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<AppRole>(
            icon: const Icon(Icons.more_vert, color: AppColors.secondary),
            tooltip: 'Change role',
            onSelected: onChanged,
            itemBuilder: (context) => [
              for (final r in AppRole.values)
                PopupMenuItem(
                  value: r,
                  enabled: r != role,
                  child: Text(r.label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
