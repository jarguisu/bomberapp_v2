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
        await db.execute('''
          CREATE TABLE questions(
            id TEXT PRIMARY KEY,
            block_id TEXT NOT NULL,
            topic_code TEXT NOT NULL,
            topic_id TEXT NOT NULL,
            topic_name TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            entity_name TEXT NOT NULL,
            syllabus_id TEXT NOT NULL,
            syllabus_name TEXT NOT NULL,
            text TEXT NOT NULL,
            correct TEXT NOT NULL,
            wrong1 TEXT NOT NULL,
            wrong2 TEXT NOT NULL,
            wrong3 TEXT NOT NULL,
            explanation TEXT,
            reference TEXT,
            difficulty INTEGER,
            source TEXT,
            year INTEGER
          );
        ''');

        await db.execute(
          'CREATE INDEX idx_questions_topic ON questions(topic_id);',
        );
        await db.execute(
          'CREATE INDEX idx_questions_block ON questions(block_id);',
        );
        await db.execute(
          'CREATE INDEX idx_questions_entity ON questions(entity_id);',
        );
        await db.execute(
          'CREATE INDEX idx_questions_syllabus ON questions(syllabus_id);',
        );
      },
    );
  }
}
