import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vetcare.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users_profile (
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        photo_url TEXT,
        phone TEXT,
        created_at TEXT
      )
    ''');

    // 2. Table Pets
    await db.execute('''
      CREATE TABLE pets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        breed TEXT,
        birth_date TEXT,
        photo_url TEXT,
        gender TEXT,
        weight REAL,
        created_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users_profile (id) ON DELETE CASCADE
      )
    ''');

    // 3. Table Vaccinations
    await db.execute('''
      CREATE TABLE vaccinations (
        id TEXT PRIMARY KEY,
        pet_id TEXT NOT NULL,
        vaccine_name TEXT NOT NULL,
        date TEXT NOT NULL,
        clinic TEXT,
        doctor TEXT,
        next_schedule TEXT,
        notes TEXT,
        created_at TEXT,
        FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
      )
    ''');

    // 4. Table Treatments
    await db.execute('''
      CREATE TABLE treatments (
        id TEXT PRIMARY KEY,
        pet_id TEXT NOT NULL,
        date TEXT NOT NULL,
        diagnosis TEXT NOT NULL,
        medicine TEXT,
        dosage TEXT,
        doctor TEXT,
        clinic TEXT,
        notes TEXT,
        created_at TEXT,
        FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
      )
    ''');

    // 5. Table Allergies
    await db.execute('''
      CREATE TABLE allergies (
        id TEXT PRIMARY KEY,
        pet_id TEXT NOT NULL,
        allergen TEXT NOT NULL,
        reaction TEXT NOT NULL,
        notes TEXT,
        created_at TEXT,
        FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}