class MenuItem {
  final String name;
  final String description;
  final int price;
  final String imageAsset;
  final String category;
  final double rating;
  final int timesOrdered;

  /// Whether the item is currently available for ordering.
  ///
  /// Admins can toggle this; unavailable items are hidden from the student
  /// menu but remain visible in the admin panel.
  final bool available;

  /// Firestore document id, populated for admin CRUD operations.
  final String? docId;

  const MenuItem({
    required this.name,
    required this.description,
    required this.price,
    required this.imageAsset,
    required this.category,
    this.rating = 0,
    this.timesOrdered = 0,
    this.available = true,
    this.docId,
  });

  /// Builds an item from a `menu_items` document.
  ///
  /// Only primitives are read, so this works for both real Firestore documents
  /// and the bundled fallback data. Fields are optional because the document is
  /// authored by hand in the Firebase console.
  factory MenuItem.fromMap(Map<String, dynamic> data, {String? docId}) {
    return MenuItem(
      name: _asString(data['name']),
      description: _asString(data['description']),
      price: _asInt(data['price']),
      imageAsset: _asString(data['imageAsset']),
      category: _asString(data['category']),
      rating: _asDouble(data['rating']),
      timesOrdered: _asInt(data['timesOrdered']),
      available: data['available'] != false,
      docId: docId,
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
      'available': available,
    };
  }

  /// Whether this item can be rendered, i.e. it has a name.
  bool get isValid => name.isNotEmpty;

  MenuItem copyWith({
    String? name,
    String? description,
    int? price,
    String? imageAsset,
    String? category,
    double? rating,
    int? timesOrdered,
    bool? available,
    String? docId,
  }) {
    return MenuItem(
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageAsset: imageAsset ?? this.imageAsset,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      timesOrdered: timesOrdered ?? this.timesOrdered,
      available: available ?? this.available,
      docId: docId ?? this.docId,
    );
  }
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