import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

import '../models/menu_item.dart';
import '../repositories/menu_repository.dart';
import '../services/auth_service.dart';

/// Holds the menu shown by the home, menu and profile screens.
///
/// Starts from the bundled [MenuCatalog] so the app is fully usable offline and
/// before Firestore responds, then swaps in the Cloud Firestore menu. The menu
/// is kept live: it re-subscribes whenever the auth state changes and re-reads
/// whenever the `menu_items` collection changes, so admin edits show up on the
/// student side without a manual refresh.
///
/// A failed or empty read keeps the bundled catalog, which means the UI can
/// never end up blank.
class MenuController extends ChangeNotifier {
  MenuController({
    required this._repository,
    required this._authService,
  }) {
    _authSubscription = _authService.authStateChanges.listen((_) => _sync());
  }

  final MenuRepository _repository;
  final AuthService _authService;

  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<List<MenuItem>>? _menuSubscription;

  List<MenuItem> _items = MenuCatalog.items;
  List<String> _categories = MenuCatalog.categories;
  bool _isLoading = false;
  bool _isUsingLocalCatalog = true;
  Object? _lastError;

  List<MenuItem> get items => List.unmodifiable(_items);

  List<String> get categories => List.unmodifiable(_categories);

  bool get isLoading => _isLoading;

  /// True while the bundled catalog is being shown.
  bool get isUsingLocalCatalog => _isUsingLocalCatalog;

  /// The last Firestore error, kept for diagnostics. The UI does not surface
  /// it because the bundled catalog keeps the screens working.
  Object? get lastError => _lastError;

  /// Re-reads the menu. Kept for [AppServices.loadData] and manual refresh.
  Future<void> load() async => _sync();

  /// (Re)subscribes to the live Firestore menu for the current auth state.
  void _sync() {
    _menuSubscription?.cancel();
    _menuSubscription = null;

    if (_authService.currentUser == null) {
      _lastError = null;
      _useLocalCatalog();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _menuSubscription = _repository.watchMenu().listen(
      (items) {
        if (items.isEmpty) {
          _useLocalCatalog();
        } else {
          _items = items;
          _categories = _categoriesFor(items);
          _isUsingLocalCatalog = false;
          _lastError = null;
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        _lastError = error;
        _useLocalCatalog();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _useLocalCatalog() {
    _items = MenuCatalog.items;
    _categories = MenuCatalog.categories;
    _isUsingLocalCatalog = true;
  }

  List<String> _categoriesFor(List<MenuItem> items) {
    final found = items.map((item) => item.category).where((c) => c.isNotEmpty);
    final sorted = found.toSet().toList()..sort();
    return ['All', ...sorted];
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _menuSubscription?.cancel();
    super.dispose();
  }
}
