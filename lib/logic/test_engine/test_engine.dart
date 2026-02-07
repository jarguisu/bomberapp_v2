import 'package:flutter/foundation.dart';

import '../../data/questions/question_repository.dart';
import '../../data/questions/question_model.dart';
import 'test_session.dart';

/// Configuración de un test por tema
class TopicTestConfig {
  final String blockId; // G, E o S
  final String topicCode; // G1, G2, E1...
  final String topicId; // Ej: GEN_CV_G2
  final String topicName; // por si quieres mostrarlo en la cabecera
  final String entityId; // GEN, CONSVAL...
  final String syllabusId; // GEN_CV, CONSVAL_2024...
  final int numQuestions;
  final bool withTimer; // cronómetro sí/no

  const TopicTestConfig({
    required this.blockId,
    required this.topicCode,
    required this.topicId,
    required this.topicName,
    required this.entityId,
    required this.syllabusId,
    required this.numQuestions,
    required this.withTimer,
  });

  QuestionTopicFilter toFilter() => QuestionTopicFilter(
        topicId: topicId,
      );
}

class CustomTestConfig {
  final List<QuestionTopicFilter> topics; // p.ej. filtros combinados
  final int numQuestions;
  final bool withTimer;

  const CustomTestConfig({
    required this.topics,
    required this.numQuestions,
    required this.withTimer,
  });
}

/// Motor principal de tests.
/// Se encarga de pedir preguntas al repositorio y
/// generar una TestSession lista para usar en la UI.
class TestEngine {
  final QuestionRepository questionRepository;

  const TestEngine({
    required this.questionRepository,
  });

  /// Crea una sesión de test para un solo tema concreto.
  Future<TestSession> startTopicTest(TopicTestConfig config) async {
    // 1) Pedimos preguntas al repositorio
    final List<Question> questions =
        await questionRepository.getQuestionsByTopic(
      filter: config.toFilter(),
      limit: config.numQuestions,
      randomOrder: true,
    );

    // 2) Comprobamos que haya preguntas suficientes (por si acaso)
    if (questions.isEmpty) {
      throw StateError(
        'No se han encontrado preguntas para el tema ${config.topicCode}.',
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[TestEngine] Generado test por tema '
        '${config.topicCode} (${config.topicName}) con ${questions.length} preguntas.',
      );
    }

    // 3) Devolvemos una sesión de test lista
    return TestSession(questions: questions);
  }

  /// Crea una sesión de test combinando varios temas.
  Future<TestSession> startCustomTest(CustomTestConfig config) async {
    final questions = await questionRepository.getQuestionsByTopics(
      filters: config.topics,
      totalLimit: config.numQuestions,
      randomOrder: true,
    );

    if (questions.isEmpty) {
      throw StateError(
        'No se han encontrado preguntas para los temas seleccionados.',
      );
    }

    return TestSession(questions: questions);
  }
}
