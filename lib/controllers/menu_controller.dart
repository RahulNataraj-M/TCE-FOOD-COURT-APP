import 'package:flutter/foundation.dart';

import '../models/menu_item.dart';
import '../repositories/menu_repository.dart';

/// Holds the menu shown by the home, menu and profile screens.
///
/// Starts from the bundled [MenuCatalog] so the app is fully usable offline and
/// before Firestore responds, then swaps in the Cloud Firestore menu when one is
/// available. A failed or empty read silently keeps the bundled catalog, which
/// means the UI can never end up blank.
class MenuController extends ChangeNotifier {
  MenuController({required this._repository});

  final MenuRepository _repository;

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

  /// Refreshes the menu from Firestore.
  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final remote = await _repository.fetchMenu();
      if (remote.isEmpty) {
        _useLocalCatalog();
      } else {
        _items = remote;
        _categories = _categoriesFor(remote);
        _isUsingLocalCatalog = false;
        _lastError = null;
      }
    } on Object catch (error) {
      _lastError = error;
      _useLocalCatalog();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
}