import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import '../db/questions_db.dart';
import '../questions/question_model.dart';

class QuestionSeedLoader {
  /// Carga preguntas desde un JSON en assets y las inserta en la tabla `questions`.
  ///
  /// - [assetPath] por ejemplo: 'assets/data/questions_g1.json'
  /// - Evita duplicar: si ya hay preguntas para ese topic_id, no inserta nada.
  static Future<void> seedFromJsonAsset(String assetPath) async {
    final db = await QuestionsDb.database;

    // 1) Leer el contenido del asset
    final jsonString = await rootBundle.loadString(assetPath);
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;

    if (jsonList.isEmpty) return;

    // 2) Tomamos el topic_id del primer registro (todas son G1 en tu JSON)
    final first = jsonList.first as Map<String, dynamic>;
    final String topicId = first['topic_id'] as String;

    // 3) Comprobar si ya hay preguntas para ese topic_id
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM questions WHERE topic_id = ?',
      [topicId],
    );

    final int existingCount =
        Sqflite.firstIntValue(countResult) ?? 0;

    if (existingCount > 0) {
      // Ya hay preguntas para este tema, no hacemos nada
      return;
    }

    // 4) Insertar todas las preguntas en un batch
    final Batch batch = db.batch();

    for (final item in jsonList) {
      final map = item as Map<String, dynamic>;

      final questionMap = <String, dynamic>{
        'topic_id': map['topic_id'],
        'topic_name': map['topic_name'],
        'text': map['text'],
        'correct': map['correct'],
        'wrong1': map['wrong1'],
        'wrong2': map['wrong2'],
        'wrong3': map['wrong3'],
      };

      batch.insert(
        'questions',
        questionMap,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await batch.commit(noResult: true);
  }
}
