import 'package:sqflite/sqflite.dart';
import '../db/questions_db.dart';
import 'question_model.dart';

class QuestionTopicFilter {
  final String topicId;

  const QuestionTopicFilter({
    required this.topicId,
  });
}

abstract class QuestionRepository {
  Future<List<Question>> getQuestionsByTopic({
    required QuestionTopicFilter filter,
    required int limit,
    bool randomOrder,
  });

  Future<List<Question>> getQuestionsByTopics({
    required List<QuestionTopicFilter> filters,
    required int totalLimit,
    bool randomOrder,
  });

  Future<List<Question>> getQuestionsByIds(List<String> ids);

  /// Elimina todas las preguntas (útil para reseed completo).
  Future<void> clearAll();
}

class SqliteQuestionRepository implements QuestionRepository {
  @override
  Future<List<Question>> getQuestionsByTopic({
    required QuestionTopicFilter filter,
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
      [
        filter.topicId,
        limit,
      ],
    );

    return result.map((row) => Question.fromMap(row)).toList();
  }

  @override
  Future<List<Question>> getQuestionsByTopics({
    required List<QuestionTopicFilter> filters,
    required int totalLimit,
    bool randomOrder = true,
  }) async {
    final db = await QuestionsDb.database;

    final topicIds = filters.map((f) => f.topicId).toSet().toList();

    final topicPlaceholders = List.filled(topicIds.length, '?').join(', ');

    final orderClause = randomOrder ? 'ORDER BY RANDOM()' : '';

    final result = await db.rawQuery(
      '''
      SELECT * FROM questions
      WHERE topic_id IN ($topicPlaceholders)
      $orderClause
      LIMIT ?
      ''',
      [
        ...topicIds,
        totalLimit,
      ],
    );

    return result.map((row) => Question.fromMap(row)).toList();
  }

  @override
  Future<void> clearAll() async {
    final db = await QuestionsDb.database;
    await db.delete('questions');
  }

  @override
  Future<List<Question>> getQuestionsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final db = await QuestionsDb.database;

    final placeholders = List.filled(ids.length, '?').join(', ');
    final result = await db.rawQuery(
      '''
      SELECT * FROM questions
      WHERE id IN ($placeholders)
      ''',
      ids,
    );

    return result.map((row) => Question.fromMap(row)).toList();
  }
}
