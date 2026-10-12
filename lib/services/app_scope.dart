// `MenuController` also exists in the Flutter SDK (raw_menu_anchor).
import 'package:flutter/widgets.dart' hide MenuController;

import '../controllers/menu_controller.dart';
import '../controllers/orders_controller.dart';
import '../repositories/menu_repository.dart';
import '../repositories/order_repository.dart';
import 'auth_service.dart';
import 'local_database.dart';

/// The Firebase-backed dependencies of the app.
///
/// Production uses [AppServices.production], which talks to the real Firebase
/// project configured in `firebase_options.dart`. Tests pass their own
/// instances backed by mocks.
class AppServices {
  AppServices({
    required this.authService,
    required this.menuRepository,
    required this.orderRepository,
    required this.menuController,
    required this.ordersController,
    this.localDatabase,
  });

  /// Wires the real Firebase Authentication, Cloud Firestore and SQLite cache.
  factory AppServices.production() {
    final authService = FirebaseAuthService();
    final localDatabase = LocalDatabase();
    final menuRepository = MenuRepository(localDatabase: localDatabase);
    final orderRepository = OrderRepository(
      authService: authService,
      localDatabase: localDatabase,
    );
    return AppServices(
      authService: authService,
      menuRepository: menuRepository,
      orderRepository: orderRepository,
      menuController: MenuController(repository: menuRepository),
      ordersController: OrdersController(
        repository: orderRepository,
        authService: authService,
      ),
      localDatabase: localDatabase,
    );
  }

  final AuthService authService;
  final MenuRepository menuRepository;
  final OrderRepository orderRepository;
  final MenuController menuController;
  final OrdersController ordersController;

  /// The on-device SQLite cache used for offline menu and order access. Null in
  /// tests that do not exercise local storage.
  final LocalDatabase? localDatabase;

  /// Prepares Google Sign-In. Await this before the first sign-in attempt.
  Future<void> initialize() => authService.initialize();

  /// Starts loading Firestore data. Safe to call more than once.
  void loadData() {
    menuController.load();
    ordersController.load();
  }

  void dispose() {
    menuController.dispose();
    ordersController.dispose();
    localDatabase?.close();
  }
}

/// Makes [AppServices] available to the widget tree.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.services,
    required super.child,
  });

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope.of() was called outside of an AppScope.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.services != services;
}