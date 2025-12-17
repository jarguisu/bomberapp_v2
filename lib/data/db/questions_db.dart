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
      version: 4,
      onCreate: (db, version) async {
        await _createQuestionsTable(db);
        await _createIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v2: Add syllabus columns and index for installs that were created before the fields existed.
        if (oldVersion < 2) {
          await _addMissingColumns(db);
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_questions_syllabus ON questions(syllabus_id);',
          );
        }
        // v3: Ensure all columns exist (covers devices that already upgraded to v2 before the wider backfill was added).
        if (oldVersion < 3) {
          await _addMissingColumns(db);
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_questions_syllabus ON questions(syllabus_id);',
          );
        }
        // v4: If schema types/columns mismatch, recreate table and preserve data.
        if (oldVersion < 4) {
          await _ensureQuestionsSchema(db);
        }
      },
    );
  }

  static Future<void> _createQuestionsTable(Database db) async {
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
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_questions_topic ON questions(topic_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_questions_block ON questions(block_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_questions_entity ON questions(entity_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_questions_syllabus ON questions(syllabus_id);',
    );
  }

  static const Map<String, String> _expectedSchema = {
    'id': 'TEXT',
    'block_id': 'TEXT',
    'topic_code': 'TEXT',
    'topic_id': 'TEXT',
    'topic_name': 'TEXT',
    'entity_id': 'TEXT',
    'entity_name': 'TEXT',
    'syllabus_id': 'TEXT',
    'syllabus_name': 'TEXT',
    'text': 'TEXT',
    'correct': 'TEXT',
    'wrong1': 'TEXT',
    'wrong2': 'TEXT',
    'wrong3': 'TEXT',
    'explanation': 'TEXT',
    'reference': 'TEXT',
    'difficulty': 'INTEGER',
    'source': 'TEXT',
    'year': 'INTEGER',
  };

  static Future<void> _ensureQuestionsSchema(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(questions);');
    final existingTypes = <String, String>{};
    for (final row in info) {
      final name = row['name'] as String?;
      final type = (row['type'] as String?)?.toUpperCase() ?? '';
      if (name != null) existingTypes[name] = type;
    }

    bool needsRecreate = false;
    _expectedSchema.forEach((column, expectedType) {
      final existingType = existingTypes[column];
      if (existingType == null || existingType != expectedType) {
        needsRecreate = true;
      }
    });

    if (needsRecreate) {
      await db.execute('ALTER TABLE questions RENAME TO questions_old;');
      await _createQuestionsTable(db);
      final commonColumns = _expectedSchema.keys
          .where((name) => existingTypes.containsKey(name))
          .join(', ');
      if (commonColumns.isNotEmpty) {
        await db.execute(
          'INSERT INTO questions ($commonColumns) SELECT $commonColumns FROM questions_old;',
        );
      }
      await db.execute('DROP TABLE questions_old;');
    }

    await _createIndexes(db);
  }

  static Future<void> _addMissingColumns(Database db) async {
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'block_id',
      definition: 'TEXT NOT NULL DEFAULT ""',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'topic_code',
      definition: 'TEXT NOT NULL DEFAULT ""',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'topic_id',
      definition: 'TEXT NOT NULL DEFAULT ""',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'topic_name',
      definition: 'TEXT NOT NULL DEFAULT ""',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'entity_id',
      definition: 'TEXT NOT NULL DEFAULT ""',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'entity_name',
      definition: 'TEXT NOT NULL DEFAULT ""',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'syllabus_id',
      definition: 'TEXT NOT NULL DEFAULT ""',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'syllabus_name',
      definition: 'TEXT NOT NULL DEFAULT ""',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'text',
      definition: 'TEXT NOT NULL DEFAULT ""',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'correct',
      definition: 'TEXT NOT NULL DEFAULT ""',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'wrong1',
      definition: 'TEXT NOT NULL DEFAULT ""',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'wrong2',
      definition: 'TEXT NOT NULL DEFAULT ""',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'wrong3',
      definition: 'TEXT NOT NULL DEFAULT ""',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'explanation',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'reference',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'difficulty',
      definition: 'INTEGER',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'source',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'year',
      definition: 'INTEGER',
    );
  }

  static Future<bool> _columnExists(
    Database db,
    String table,
    String column,
  ) async {
    final result = await db.rawQuery('PRAGMA table_info($table);');
    return result.any((row) => row['name'] == column);
  }

  static Future<void> _addColumnIfMissing(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final exists = await _columnExists(db, table, column);
    if (!exists) {
      await db.execute(
        'ALTER TABLE $table ADD COLUMN $column $definition;',
      );
    }
  }
}
