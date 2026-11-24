import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _dbName = 'shelfie.db';
  static const _dbVersion = 3;
  static const tableProducts = 'products';

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final fullPath = join(dbPath, _dbName);
    return openDatabase(
      fullPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableProducts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        category TEXT NOT NULL,
        added_at INTEGER NOT NULL,
        expiry_date INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 3) {
      // Пересоздаём таблицу без колонки subcategory.
      await db.execute('''
        CREATE TABLE ${tableProducts}_new (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          quantity REAL NOT NULL,
          unit TEXT NOT NULL,
          category TEXT NOT NULL,
          added_at INTEGER NOT NULL,
          expiry_date INTEGER
        )
      ''');
      await db.execute('''
        INSERT INTO ${tableProducts}_new (id, name, quantity, unit, category, added_at, expiry_date)
        SELECT id, name, quantity, unit, category, added_at, expiry_date
        FROM $tableProducts
      ''');
      await db.execute('DROP TABLE $tableProducts');
      await db.execute(
          'ALTER TABLE ${tableProducts}_new RENAME TO $tableProducts');
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}