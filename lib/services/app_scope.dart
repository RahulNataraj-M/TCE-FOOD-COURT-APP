// `MenuController` also exists in the Flutter SDK (raw_menu_anchor).
import 'package:flutter/widgets.dart' hide MenuController;

import '../controllers/menu_controller.dart';
import '../controllers/orders_controller.dart';
import '../repositories/menu_repository.dart';
import '../repositories/order_repository.dart';
import 'auth_service.dart';

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
  });

  /// Wires the real Firebase Authentication and Cloud Firestore services.
  factory AppServices.production() {
    final authService = FirebaseAuthService();
    final menuRepository = MenuRepository();
    final orderRepository = OrderRepository(authService: authService);
    return AppServices(
      authService: authService,
      menuRepository: menuRepository,
      orderRepository: orderRepository,
      menuController: MenuController(repository: menuRepository),
      ordersController: OrdersController(
        repository: orderRepository,
        authService: authService,
      ),
    );
  }

  final AuthService authService;
  final MenuRepository menuRepository;
  final OrderRepository orderRepository;
  final MenuController menuController;
  final OrdersController ordersController;

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