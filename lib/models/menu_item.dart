class MenuItem {
  final String name;
  final String description;
  final int price;
  final String imageAsset;
  final String category;
  final double rating;
  final int timesOrdered;

  const MenuItem({
    required this.name,
    required this.description,
    required this.price,
    required this.imageAsset,
    required this.category,
    this.rating = 0,
    this.timesOrdered = 0,
  });

  /// Builds an item from a `menu_items` document.
  ///
  /// Only primitives are read, so this works for both real Firestore documents
  /// and the bundled fallback data. Fields are optional because the document is
  /// authored by hand in the Firebase console.
  factory MenuItem.fromMap(Map<String, dynamic> data) {
    return MenuItem(
      name: _asString(data['name']),
      description: _asString(data['description']),
      price: _asInt(data['price']),
      imageAsset: _asString(data['imageAsset']),
      category: _asString(data['category']),
      rating: _asDouble(data['rating']),
      timesOrdered: _asInt(data['timesOrdered']),
    );
  }

  /// Serialisable form used when writing the item back to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageAsset': imageAsset,
      'category': category,
      'rating': rating,
      'timesOrdered': timesOrdered,
    };
  }

  /// Whether this item can be rendered, i.e. it has a name.
  bool get isValid => name.isNotEmpty;
}

String _asString(Object? value) => value?.toString() ?? '';

int _asInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class CartItem {
  final MenuItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  int get total => item.price * quantity;
}

class MenuCatalog {
  MenuCatalog._();

  static const List<MenuItem> items = [
    MenuItem(
      name: 'Chicken Biriyani',
      description: 'Aromatic basmati rice with tender chicken',
      price: 150,
      imageAsset: 'assets/images/biriyani_home.jpg',
      category: 'Rice',
      rating: 4.8,
      timesOrdered: 8,
    ),
    MenuItem(
      name: 'Chicken Rice',
      description: 'Stir-fried rice with chicken & veggies',
      price: 120,
      imageAsset: 'assets/images/chicken_fried_rice.jpg',
      category: 'Rice',
      rating: 4.5,
    ),
    MenuItem(
      name: 'Veg Rice',
      description: 'Classic vegetable stir-fried rice',
      price: 60,
      imageAsset: 'assets/images/veg_rice_bowl.jpg',
      category: 'Rice',
    ),
    MenuItem(
      name: 'Chicken Noodles',
      description: 'Wok-tossed noodles with chicken strips',
      price: 90,
      imageAsset: 'assets/images/chicken_noodles.jpg',
      category: 'Snacks',
    ),
    MenuItem(
      name: 'Veg Noodles',
      description: 'Noodles tossed with fresh vegetables',
      price: 70,
      imageAsset: 'assets/images/veg_noodles.jpg',
      category: 'Snacks',
    ),
    MenuItem(
      name: 'Parotta',
      description: 'Flaky layered flatbread',
      price: 20,
      imageAsset: 'assets/images/parotta.jpg',
      category: 'Breakfast',
    ),
    MenuItem(
      name: 'Lime Juice',
      description: 'Fresh squeezed sweet lime',
      price: 20,
      imageAsset: 'assets/images/lime_juice_glassy.jpg',
      category: 'Drinks',
      timesOrdered: 6,
    ),
    MenuItem(
      name: 'Dosa',
      description: 'Crispy South Indian pancake',
      price: 70,
      imageAsset: 'assets/images.jpeg',
      category: 'Breakfast',
    ),
  ];

  static const List<String> categories = [
    'All',
    'Breakfast',
    'Rice',
    'Snacks',
    'Drinks',
  ];
}