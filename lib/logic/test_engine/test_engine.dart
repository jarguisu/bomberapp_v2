import 'package:flutter/foundation.dart';

import '../../data/questions/question_repository.dart';
import '../../data/questions/question_model.dart';
import 'test_session.dart';

/// Configuración de un test por tema
class TopicTestConfig {
  final String topicId;       // G1, G2, E1...
  final String topicName;     // por si quieres mostrarlo en la cabecera
  final int numQuestions;
  final bool withTimer;       // cronómetro sí/no

  const TopicTestConfig({
    required this.topicId,
    required this.topicName,
    required this.numQuestions,
    required this.withTimer,
  });
}

class CustomTestConfig {
  final List<String> topicIds; // p.ej. ['G1', 'G2']
  final int numQuestions;
  final bool withTimer;

  const CustomTestConfig({
    required this.topicIds,
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
      topicId: config.topicId,
      limit: config.numQuestions,
      randomOrder: true,
    );

    // 2) Comprobamos que haya preguntas suficientes (por si acaso)
    if (questions.isEmpty) {
      throw StateError(
        'No se han encontrado preguntas para el tema ${config.topicId}.',
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[TestEngine] Generado test por tema '
        '${config.topicId} (${config.topicName}) con ${questions.length} preguntas.',
      );
    }

    // 3) Devolvemos una sesión de test lista
    return TestSession(questions: questions);
  }

    /// Crea una sesión de test combinando varios temas.
  Future<TestSession> startCustomTest(CustomTestConfig config) async {
    final questions = await questionRepository.getQuestionsByTopics(
      topicIds: config.topicIds,
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
