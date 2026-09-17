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