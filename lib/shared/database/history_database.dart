import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HistoryItem {
  final int? id;
  final String title;
  final String path;
  final String type;
  final String createdAt;

  HistoryItem({
    this.id,
    required this.title,
    required this.path,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'path': path,
      'type': type,
      'createdAt': createdAt,
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      path: map['path'] as String,
      type: map['type'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
}

class HistoryDatabase {
  static final HistoryDatabase instance = HistoryDatabase._init();
  static Database? _database;

  HistoryDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('history.db');
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
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        path TEXT NOT NULL,
        type TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insert(HistoryItem item) async {
    final db = await instance.database;
    return await db.insert('history', item.toMap());
  }

  Future<List<HistoryItem>> fetchAll() async {
    final db = await instance.database;
    final result = await db.query('history', orderBy: 'id DESC');
    return result.map((json) => HistoryItem.fromMap(json)).toList();
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }
}
