import 'package:sqflite/sqflite.dart';
import '../db/questions_db.dart';
import 'question_model.dart';

abstract class QuestionRepository {
  Future<List<Question>> getQuestionsByTopic({
    required String topicId,
    required int limit,
    bool randomOrder,
  });

  Future<List<Question>> getQuestionsByTopics({
    required List<String> topicIds,
    required int totalLimit,
    bool randomOrder,
  });
}

class SqliteQuestionRepository implements QuestionRepository {
  @override
  Future<List<Question>> getQuestionsByTopic({
    required String topicId,
    required int limit,
    bool randomOrder = true,
  }) async {
    final db = await QuestionsDb.database;

    final orderClause = randomOrder ? 'ORDER BY RANDOM()' : '';
    final result = await db.rawQuery(
      '''
      SELECT * FROM questions
      WHERE topic_id = ?
      $orderClause
      LIMIT ?
      ''',
      [topicId, limit],
    );

    return result.map((row) => Question.fromMap(row)).toList();
  }

  @override
  Future<List<Question>> getQuestionsByTopics({
    required List<String> topicIds,
    required int totalLimit,
    bool randomOrder = true,
  }) async {
    final db = await QuestionsDb.database;

    final placeholders = List.filled(topicIds.length, '?').join(', ');

    final orderClause = randomOrder ? 'ORDER BY RANDOM()' : '';

    final result = await db.rawQuery(
      '''
      SELECT * FROM questions
      WHERE topic_id IN ($placeholders)
      $orderClause
      LIMIT ?
      ''',
      [...topicIds, totalLimit],
    );

    return result.map((row) => Question.fromMap(row)).toList();
  }
}
