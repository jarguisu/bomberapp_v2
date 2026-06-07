import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import '../db/questions_db.dart';
import '../questions/question_model.dart';

class QuestionSeedLoader {
  /// Carga preguntas desde un JSON en assets y las inserta/actualiza en la tabla `questions`.
  ///
  /// - [assetPath] por ejemplo: 'assets/data/questions_g1.json'
  /// - Usa `id` como clave primaria para upsert; permite añadir o editar preguntas en los JSON sin duplicar.
  static Future<void> seedFromJsonAsset(String assetPath) async {
    final db = await QuestionsDb.database;

    // 1) Leer el contenido del asset
    final jsonString = await rootBundle.loadString(assetPath);
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;

    if (jsonList.isEmpty) return;

    // 2) Insertar/upsert todas las preguntas en un batch (por id)
    final Batch batch = db.batch();

    for (final item in jsonList) {
      final map = item as Map<String, dynamic>;
      final question = Question.fromJson(map);

      batch.insert(
        'questions',
        question.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }
}
