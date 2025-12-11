import 'package:sqflite/sqflite.dart';
import '../db/questions_db.dart';
import 'question_model.dart';

class QuestionTopicFilter {
  final String blockId;
  final String topicCode;
  final String topicId;
  final String entityId;
  final String syllabusId;

  const QuestionTopicFilter({
    required this.blockId,
    required this.topicCode,
    required this.topicId,
    required this.entityId,
    required this.syllabusId,
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
      WHERE block_id = ?
        AND topic_code = ?
        AND topic_id = ?
        AND entity_id = ?
        AND syllabus_id = ?
      $orderClause
      LIMIT ?
      ''',
      [
        filter.blockId,
        filter.topicCode,
        filter.topicId,
        filter.entityId,
        filter.syllabusId,
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
    final blockIds = filters.map((f) => f.blockId).toSet().toList();
    final topicCodes = filters.map((f) => f.topicCode).toSet().toList();
    final entityIds = filters.map((f) => f.entityId).toSet().toList();
    final syllabusIds = filters.map((f) => f.syllabusId).toSet().toList();

    final topicPlaceholders = List.filled(topicIds.length, '?').join(', ');
    final blockPlaceholders = List.filled(blockIds.length, '?').join(', ');
    final topicCodePlaceholders = List.filled(topicCodes.length, '?').join(', ');
    final entityPlaceholders = List.filled(entityIds.length, '?').join(', ');
    final syllabusPlaceholders = List.filled(syllabusIds.length, '?').join(', ');

    final orderClause = randomOrder ? 'ORDER BY RANDOM()' : '';

    final result = await db.rawQuery(
      '''
      SELECT * FROM questions
      WHERE block_id IN ($blockPlaceholders)
        AND topic_code IN ($topicCodePlaceholders)
        AND topic_id IN ($topicPlaceholders)
        AND entity_id IN ($entityPlaceholders)
        AND syllabus_id IN ($syllabusPlaceholders)
      $orderClause
      LIMIT ?
      ''',
      [
        ...blockIds,
        ...topicCodes,
        ...topicIds,
        ...entityIds,
        ...syllabusIds,
        totalLimit,
      ],
    );

    return result.map((row) => Question.fromMap(row)).toList();
  }
}
