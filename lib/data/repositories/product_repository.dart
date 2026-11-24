import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/product.dart';

class ProductRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<Product>> getAll() async {
    final db = await _helper.database;
    final rows = await db.query(
      DatabaseHelper.tableProducts,
      orderBy: 'added_at DESC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<void> add(Product product) async {
    final db = await _helper.database;
    await db.insert(
      DatabaseHelper.tableProducts,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Product product) async {
    final db = await _helper.database;
    await db.update(
      DatabaseHelper.tableProducts,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _helper.database;
    await db.delete(
      DatabaseHelper.tableProducts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

   /// Списывает [amount] единиц продукта.
  /// Если остаток становится ≤ 0 — продукт удаляется.
  /// Возвращает true, если продукт был удалён (а не обновлён).
  Future<bool> writeOff(Product product, double amount) async {
    final remaining = product.quantity - amount;
    if (remaining <= 0) {
      await delete(product.id);
      return true;
    }
    final updated = product.copyWith(
      quantity: remaining,
      addedAt: DateTime.now(), // «последнее изменение» — для будущих пушей
    );
    await update(updated);
    return false;
  }
}