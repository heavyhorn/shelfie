import 'models/product.dart';

/// Справочник типовых продуктов для автодополнения при добавлении.
/// Хранится в коде; при желании позже можно перенести в БД.
class ProductSuggestion {
  final String name;
  final ProductCategory category;
  final QuantityUnit defaultUnit;

  const ProductSuggestion(this.name, this.category, this.defaultUnit);
}

const List<ProductSuggestion> kProductSuggestions = [
  // Молочное
  ProductSuggestion('Молоко', ProductCategory.dairy, QuantityUnit.pieces),
  ProductSuggestion('Кефир', ProductCategory.dairy, QuantityUnit.pieces),
  ProductSuggestion('Йогурт', ProductCategory.dairy, QuantityUnit.pieces),
  ProductSuggestion('Сметана', ProductCategory.dairy, QuantityUnit.grams),
  ProductSuggestion('Творог', ProductCategory.dairy, QuantityUnit.grams),
  ProductSuggestion('Сыр', ProductCategory.dairy, QuantityUnit.grams),
  ProductSuggestion('Масло сливочное', ProductCategory.dairy, QuantityUnit.grams),

  // Бакалея
  ProductSuggestion('Рис', ProductCategory.grocery, QuantityUnit.grams),
  ProductSuggestion('Гречка', ProductCategory.grocery, QuantityUnit.grams),
  ProductSuggestion('Макароны', ProductCategory.grocery, QuantityUnit.grams),
  ProductSuggestion('Мука', ProductCategory.grocery, QuantityUnit.grams),
  ProductSuggestion('Сахар', ProductCategory.grocery, QuantityUnit.grams),
  ProductSuggestion('Соль', ProductCategory.grocery, QuantityUnit.grams),
  ProductSuggestion('Масло растительное', ProductCategory.grocery, QuantityUnit.milliliters),

  // Напитки
  ProductSuggestion('Вода', ProductCategory.drinks, QuantityUnit.milliliters),
  ProductSuggestion('Сок', ProductCategory.drinks, QuantityUnit.milliliters),
  ProductSuggestion('Чай', ProductCategory.drinks, QuantityUnit.packs),
  ProductSuggestion('Кофе', ProductCategory.drinks, QuantityUnit.packs),

  // Мясо
  ProductSuggestion('Курица', ProductCategory.meat, QuantityUnit.grams),
  ProductSuggestion('Говядина', ProductCategory.meat, QuantityUnit.grams),
  ProductSuggestion('Свинина', ProductCategory.meat, QuantityUnit.grams),
  ProductSuggestion('Фарш', ProductCategory.meat, QuantityUnit.grams),

  // Овощи и фрукты
  ProductSuggestion('Картофель', ProductCategory.vegetables, QuantityUnit.grams),
  ProductSuggestion('Морковь', ProductCategory.vegetables, QuantityUnit.grams),
  ProductSuggestion('Лук', ProductCategory.vegetables, QuantityUnit.grams),
  ProductSuggestion('Помидоры', ProductCategory.vegetables, QuantityUnit.grams),
  ProductSuggestion('Огурцы', ProductCategory.vegetables, QuantityUnit.grams),
  ProductSuggestion('Яблоки', ProductCategory.fruits, QuantityUnit.pieces),
  ProductSuggestion('Бананы', ProductCategory.fruits, QuantityUnit.pieces),
  ProductSuggestion('Апельсины', ProductCategory.fruits, QuantityUnit.pieces),

  // Заморозка
  ProductSuggestion('Пельмени', ProductCategory.frozen, QuantityUnit.grams),
  ProductSuggestion('Мороженое', ProductCategory.frozen, QuantityUnit.pieces),
];