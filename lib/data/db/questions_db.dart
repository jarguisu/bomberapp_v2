import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class QuestionsDb {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static const _expectedColumns = <String>[
    'id',
    'topic_id',
    'text',
    'correct',
    'wrong1',
    'wrong2',
    'wrong3',
    'explanation',
    'reference',
    'difficulty',
    'source',
    'year',
  ];

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bomberapp_questions.db');

    return openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await _createQuestionsTable(db);
        await _createIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v5: esquema normalizado para preguntas (solo los campos necesarios).
        if (oldVersion < 5) {
          await _recreateNormalizedQuestions(db);
        }
      },
    );
  }

  static Future<void> _recreateNormalizedQuestions(Database db) async {
    final exists = await _tableExists(db, 'questions');
    if (!exists) {
      await _createQuestionsTable(db);
      await _createIndexes(db);
      return;
    }

    final info = await db.rawQuery('PRAGMA table_info(questions);');
    final existingCols = info
        .map((row) => row['name'] as String)
        .toSet();

    // Construimos el SELECT con NULL para columnas que no existan en el esquema previo.
    final selectExpressions = _expectedColumns.map((col) {
      return existingCols.contains(col) ? col : 'NULL AS $col';
    }).join(', ');

    await db.execute('ALTER TABLE questions RENAME TO questions_old;');
    await _createQuestionsTable(db);

    await db.execute(
      '''
      INSERT OR IGNORE INTO questions (${_expectedColumns.join(', ')})
      SELECT $selectExpressions FROM questions_old;
      ''',
    );

    await db.execute('DROP TABLE questions_old;');
    await _createIndexes(db);
  }

  static Future<void> _createQuestionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE questions(
        id TEXT PRIMARY KEY,
        topic_id TEXT NOT NULL,
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
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_questions_topic ON questions(topic_id);',
    );
  }

  static Future<bool> _tableExists(Database db, String table) async {
    final result = await db.rawQuery(
      'SELECT name FROM sqlite_master WHERE type="table" AND name=?;',
      [table],
    );
    return result.isNotEmpty;
  }
}
