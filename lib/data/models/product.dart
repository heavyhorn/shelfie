enum ProductCategory {
  drinks('Напитки'),
  grocery('Бакалея'),
  dairy('Молочные продукты, яйца'),
  meat('Мясо, птицы, колбасы'),
  vegetables('Овощи'),
  fruits('Фрукты и ягоды'),
  frozen('Заморозка'),
  other('Другое'),
  bread('Хлеб и выпечка'),
  fish('Рыба и морепродукты'),
  sweets('Сладости'),
  snack('Снеки и чипсы'),
  pet('Для животных'),
  care('Красота и гигиена'),
  home('Бытовая химия, уборка'),
  conserve('Консервы'),
  rte('Готовая еда'),
  
  ;


  final String label;
  const ProductCategory(this.label);

  static ProductCategory fromName(String name) =>
      ProductCategory.values.firstWhere((e) => e.name == name,
          orElse: () => ProductCategory.other);
}

enum QuantityUnit {
  pieces('шт.'),
  grams('гр'),
  kilograms('кг'),
  milliliters('мл'),
  packs('уп.');

  final String label;
  const QuantityUnit(this.label);

  static QuantityUnit fromName(String name) =>
      QuantityUnit.values.firstWhere((e) => e.name == name,
          orElse: () => QuantityUnit.pieces);
}

class Product {
  final String id;
  final String name;
  final double quantity;
  final QuantityUnit unit;
  final ProductCategory category;
  final DateTime addedAt;
  final DateTime? expiryDate;

  const Product({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.addedAt,
    this.expiryDate,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit.name,
        'category': category.name,
        'added_at': addedAt.millisecondsSinceEpoch,
        'expiry_date': expiryDate?.millisecondsSinceEpoch,
      };

  factory Product.fromMap(Map<String, Object?> map) => Product(
        id: map['id'] as String,
        name: map['name'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unit: QuantityUnit.fromName(map['unit'] as String),
        category: ProductCategory.fromName(map['category'] as String),
        addedAt:
            DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
        expiryDate: map['expiry_date'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['expiry_date'] as int),
      );

  Product copyWith({double? quantity, DateTime? addedAt}) => Product(
        id: id,
        name: name,
        quantity: quantity ?? this.quantity,
        unit: unit,
        category: category,
        addedAt: addedAt ?? this.addedAt,
        expiryDate: expiryDate,
      );
}