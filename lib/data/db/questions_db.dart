import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class QuestionsDb {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bomberapp_questions.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Aquí metes tu SQL de creación de tablas
        await db.execute('''
          CREATE TABLE topics(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            block TEXT
          );
        ''');

        await db.execute('''
  CREATE TABLE questions(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id TEXT NOT NULL,
    topic_name TEXT NOT NULL,
    text TEXT NOT NULL,
    correct TEXT NOT NULL,
    wrong1 TEXT NOT NULL,
    wrong2 TEXT NOT NULL,
    wrong3 TEXT NOT NULL,
    FOREIGN KEY(topic_id) REFERENCES topics(id)
  );
''');

        await db.execute(
          'CREATE INDEX idx_questions_topic ON questions(topic_id);',
        );

        // Opcional: insertar datos iniciales
      },
    );
  }
}
