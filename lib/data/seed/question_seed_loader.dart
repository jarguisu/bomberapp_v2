import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import '../db/questions_db.dart';
import '../questions/question_model.dart';

class QuestionSeedLoader {
  /// Carga preguntas desde un JSON en assets y las inserta en la tabla `questions`.
  ///
  /// - [assetPath] por ejemplo: 'assets/data/questions_g1.json'
  /// - Evita duplicar: si ya hay preguntas para ese topic_id y syllabus_id, no inserta nada.
  static Future<void> seedFromJsonAsset(String assetPath) async {
    final db = await QuestionsDb.database;

    // 1) Leer el contenido del asset
    final jsonString = await rootBundle.loadString(assetPath);
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;

    if (jsonList.isEmpty) return;

    // 2) Tomamos los identificadores del primer registro
    final first = jsonList.first as Map<String, dynamic>;
    final String topicId = _requireString(first, 'topic_id');
    final String syllabusId = _requireString(first, 'syllabus_id');

    // 3) Comprobar si ya hay preguntas para ese topic_id y syllabus_id
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM questions WHERE topic_id = ? AND syllabus_id = ?',
      [topicId, syllabusId],
    );

    final int existingCount = Sqflite.firstIntValue(countResult) ?? 0;

    if (existingCount > 0) {
      // Ya hay preguntas para este tema, no hacemos nada
      return;
    }

    // 4) Insertar todas las preguntas en un batch
    final Batch batch = db.batch();

    for (final item in jsonList) {
      final map = item as Map<String, dynamic>;
      final question = Question.fromJson(map);

      batch.insert(
        'questions',
        question.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await batch.commit(noResult: true);
  }

  static String _requireString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException(
      'El campo "$key" es obligatorio en el JSON de semillas y debe ser una cadena no vacía.',
      map,
    );
  }
}
