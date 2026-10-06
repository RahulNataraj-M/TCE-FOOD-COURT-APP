import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart' hide MenuController;
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';

import 'package:tce_foodcourt_app/controllers/cart_controller.dart';
import 'package:tce_foodcourt_app/controllers/menu_controller.dart';
import 'package:tce_foodcourt_app/controllers/orders_controller.dart';
import 'package:tce_foodcourt_app/main.dart';
import 'package:tce_foodcourt_app/models/menu_item.dart';
import 'package:tce_foodcourt_app/repositories/menu_repository.dart';
import 'package:tce_foodcourt_app/repositories/order_repository.dart';
import 'package:tce_foodcourt_app/screens/profile_screen.dart';
import 'package:tce_foodcourt_app/services/app_scope.dart';
import 'package:tce_foodcourt_app/services/auth_service.dart';

/// [AuthService] backed by `firebase_auth_mocks`.
///
/// `MockFirebaseAuth` drives the real `authStateChanges` stream and returns
/// `MockUser` instances, so the widget tree behaves exactly as it does with
/// Firebase Auth without needing a Firebase app or platform channels.
class MockAuthService extends AuthService {
  MockAuthService({MockUser? user})
    : _auth = MockFirebaseAuth(
        mockUser:
            user ??
            MockUser(
              uid: 'test-uid-1',
              email: 'johndoe@student.tce.edu',
              displayName: 'John Doe',
              // Empty so the profile falls back to the bundled avatar and the
              // test does not issue a real image request.
              photoURL: '',
            ),
      );

  final MockFirebaseAuth _auth;

  /// When set, [signInWithGoogle] throws it instead of signing in.
  AuthFailure? failWith;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<User> signInWithGoogle() async {
    final failure = failWith;
    if (failure != null) throw failure;
    final result = await _auth.signInWithCredential(null);
    return result.user!;
  }

  @override
  Future<User> signInWithEmailPassword(String email, String password) async {
    final failure = failWith;
    if (failure != null) throw failure;
    final result = await _auth.signInWithCredential(null);
    return result.user!;
  }

  @override
  Future<User> createAccountWithEmailPassword({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    final failure = failWith;
    if (failure != null) throw failure;
    final result = await _auth.signInWithCredential(null);
    return result.user!;
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

/// Services wired to fakes, mirroring [AppServices.production].
({AppServices services, MockAuthService auth}) buildTestServices({
  MockAuthService? authService,
  FakeFirebaseFirestore? firestore,
}) {
  final auth = authService ?? MockAuthService();
  final db = firestore ?? FakeFirebaseFirestore();
  final menuRepository = MenuRepository(firestore: db);
  final orderRepository = OrderRepository(firestore: db, authService: auth);
  final services = AppServices(
    authService: auth,
    menuRepository: menuRepository,
    orderRepository: orderRepository,
    menuController: MenuController(repository: menuRepository),
    ordersController: OrdersController(
      repository: orderRepository,
      authService: auth,
    ),
  );
  addTearDown(services.dispose);
  return (services: services, auth: auth);
}

void main() {
  setUp(() {
    CartController.instance.clear();
  });

  testWidgets('Full ordering flow works end to end', (tester) async {
    final test = buildTestServices();
    await tester.pumpWidget(TceFoodCourtApp(services: test.services));

    // Login screen
    expect(find.text('TCE Food Court'), findsOneWidget);

    // Continue with Google -> Home
    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('What are you hungry for?'), findsOneWidget);
    expect(find.text('Most Ordered'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);

    // Go to the menu (Order Food)
    await tester.tap(find.text('Order'));
    await tester.pumpAndSettle();

    expect(find.text('Search food...'), findsOneWidget);
    expect(find.text('Chicken Biriyani'), findsOneWidget);

    // Add Chicken Biriyani to cart
    await tester.tap(find.text('Add').first);
    await tester.pumpAndSettle();

    expect(CartController.instance.itemCount, 1);

    // Open cart via the floating bar
    await tester.tap(find.text('View Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Your Cart'), findsOneWidget);
    expect(find.text('Chicken Biriyani'), findsOneWidget);
    expect(find.text('₹150'), findsWidgets);

    // Proceed to payment
    await tester.tap(find.text('Proceed to Payment'));
    await tester.pumpAndSettle();

    expect(find.text('Payment Methods'), findsOneWidget);

    // Complete payment
    await tester.tap(find.text('Pay ₹150'));
    await tester.pumpAndSettle();

    expect(find.text('Payment Successful'), findsOneWidget);
    // The order number now comes from Firestore instead of being hardcoded.
    expect(find.textContaining('#TCE'), findsWidgets);

    // Cart should be cleared after successful payment
    expect(CartController.instance.itemCount, 0);

    // View Order -> Orders tab
    await tester.tap(find.text('View Order'));
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('Active Order'), findsOneWidget);
  });

  test('Cart item totals are computed correctly', () {
    const item = MenuItem(
      name: 'Test',
      description: '',
      price: 100,
      imageAsset: '',
      category: '',
    );
    final cartItem = CartItem(item: item, quantity: 3);
    expect(cartItem.total, 300);
  });

  testWidgets('The placed order is stored in Firestore', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final test = buildTestServices(firestore: firestore);

    await tester.pumpWidget(TceFoodCourtApp(services: test.services));

    // Sign in, add an item and check out.
    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proceed to Payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay ₹150'));
    await tester.pumpAndSettle();

    final orders = await firestore
        .collection('users')
        .doc('test-uid-1')
        .collection('orders')
        .get();

    expect(orders.docs, hasLength(1));
    final data = orders.docs.single.data();
    expect(data['total'], 150);
    expect(data['status'], 'placed');
    expect(data['displayId'], startsWith('#TCE'));
  });

  testWidgets(
    'Menu falls back to the bundled catalog when Firestore is empty',
    (tester) async {
      final test = buildTestServices();
      await tester.pumpWidget(TceFoodCourtApp(services: test.services));
      await tester.ensureVisible(find.text('Continue with Google'));
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.text('Chicken Biriyani'), findsWidgets);
      expect(test.services.menuController.isUsingLocalCatalog, isTrue);
    },
  );

  testWidgets('Menu is read from Firestore when documents exist', (
    tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('menu_items').add({
      'name': 'Vada',
      'description': 'Crispy lentil fritter',
      'price': 25,
      'imageAsset': 'assets/images/veg_rice_bowl.jpg',
      'category': 'Snacks',
      'rating': 4.4,
      'timesOrdered': 12,
    });

    final test = buildTestServices(firestore: firestore);
    await tester.pumpWidget(TceFoodCourtApp(services: test.services));
    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    // The Firestore menu replaced the bundled catalog.
    expect(find.text('Vada'), findsWidgets);
    expect(find.text('Chicken Biriyani'), findsNothing);
    expect(test.services.menuController.isUsingLocalCatalog, isFalse);

    await tester.tap(find.text('Order'));
    await tester.pumpAndSettle();

    expect(find.text('Vada'), findsWidgets);
    expect(find.text('Search food...'), findsOneWidget);
  });

  testWidgets('A failed sign-in keeps the user on the login screen', (
    tester,
  ) async {
    final auth = MockAuthService()
      ..failWith = const AuthFailure(
        AuthFailureReason.network,
        'Cannot reach Google right now. Please try again.',
      );
    final test = buildTestServices(authService: auth);

    await tester.pumpWidget(TceFoodCourtApp(services: test.services));
    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('TCE Food Court'), findsOneWidget);
    expect(
      find.text('Cannot reach Google right now. Please try again.'),
      findsOneWidget,
    );
    expect(test.auth.currentUser, isNull);
  });

  testWidgets('Email and password sign-in uses the Firebase auth service', (
    tester,
  ) async {
    final test = buildTestServices();
    await tester.pumpWidget(TceFoodCourtApp(services: test.services));

    await tester.enterText(
      find.byType(TextField).at(0),
      'johndoe@student.tce.edu',
    );
    await tester.enterText(find.byType(TextField).at(1), 'password');
    final emailButton = find.text('Sign in with email');
    await tester.ensureVisible(emailButton);
    await tester.tap(emailButton);
    await tester.pumpAndSettle();

    expect(find.text('What are you hungry for?'), findsOneWidget);
    expect(test.auth.currentUser?.email, 'johndoe@student.tce.edu');
  });

  testWidgets('Student sign-up collects details and creates an account', (
    tester,
  ) async {
    final test = buildTestServices();
    await tester.pumpWidget(TceFoodCourtApp(services: test.services));

    final signUp = find.text('New user? Create an account');
    await tester.ensureVisible(signUp);
    await tester.tap(signUp);
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'John');
    await tester.enterText(fields.at(1), 'Doe');
    await tester.enterText(fields.at(2), '9876543210');
    await tester.enterText(fields.at(3), 'johndoe@student.tce.edu');
    await tester.enterText(fields.at(4), 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('What are you hungry for?'), findsOneWidget);
    expect(test.auth.currentUser?.email, 'johndoe@student.tce.edu');
  });

  testWidgets('Sign out returns to the login screen', (tester) async {
    final test = buildTestServices();
    await tester.pumpWidget(TceFoodCourtApp(services: test.services));
    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('What are you hungry for?'), findsOneWidget);

    // The profile tab lives in the bottom nav scaffold that the confirmation
    // screen opens, so get there through a real checkout.
    await tester.tap(find.text('Order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proceed to Payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay ₹150'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Order'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // The profile is rendered from the Firebase user, not hardcoded text.
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('johndoe@student.tce.edu'), findsOneWidget);

    // The logout button is the last, lazily built item of the profile list.
    await tester.scrollUntilVisible(
      find.text('Log Out'),
      300,
      scrollable: find.descendant(
        of: find.byType(ProfileScreen),
        matching: find.byType(widgets.Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(find.text('TCE Food Court'), findsOneWidget);
    expect(test.auth.currentUser, isNull);
  });
}
