import 'dart:math';
import '../../data/questions/question_model.dart';

/// Representa una opción de respuesta (correcta o incorrecta)
class AnswerOption {
  final String text;
  final bool isCorrect;

  const AnswerOption({
    required this.text,
    required this.isCorrect,
  });
}

/// Representa una sesión de test en curso
class TestSession {
  final List<Question> questions;

  /// Índice de la pregunta actual dentro de [questions]
  int currentIndex;

  /// Registro de respuestas del usuario:
  /// key = id de la pregunta, value = true (acertada), false (fallada)
  final Map<int, bool> _answersByQuestionId;

  TestSession({
    required this.questions,
    this.currentIndex = 0,
    Map<int, bool>? answersByQuestionId,
  }) : _answersByQuestionId = answersByQuestionId ?? {};

  /// Pregunta actual
  Question get currentQuestion => questions[currentIndex];

  /// ¿Ya se ha respondido esta pregunta?
  bool get isCurrentAnswered =>
      _answersByQuestionId.containsKey(currentQuestion.id);

  /// Devuelve true si la sesión ha llegado a la última pregunta y ya está contestada.
  bool get isFinished =>
      currentIndex == questions.length - 1 && isCurrentAnswered;

  /// Número de aciertos
  int get correctCount =>
      _answersByQuestionId.values.where((v) => v == true).length;

  /// Número de fallos
  int get wrongCount =>
      _answersByQuestionId.values.where((v) => v == false).length;

  /// Puntuación con penalización −0,33 por fallo
  double get scoreWithPenalty =>
      correctCount - wrongCount * 0.33;

  /// Devuelve las 4 opciones de respuesta de una pregunta, ya mezcladas.
  /// Si quieres usarlo para otra pregunta, pásala como parámetro;
  /// si no, usa la [currentQuestion].
  List<AnswerOption> getShuffledOptions({Question? question}) {
    final q = question ?? currentQuestion;

    final options = <AnswerOption>[
      AnswerOption(text: q.correctAnswer, isCorrect: true),
      AnswerOption(text: q.wrong1, isCorrect: false),
      AnswerOption(text: q.wrong2, isCorrect: false),
      AnswerOption(text: q.wrong3, isCorrect: false),
    ];

    options.shuffle(Random());
    return options;
  }

  /// Registra la respuesta del usuario a la [currentQuestion]
  /// [isCorrect] = true si ha elegido la correcta, false si se ha equivocado.
  void answerCurrent({required bool isCorrect}) {
    final questionId = currentQuestion.id;
    _answersByQuestionId[questionId] = isCorrect;
  }

  /// Avanza a la siguiente pregunta si existe
  void goToNext() {
    if (currentIndex < questions.length - 1) {
      currentIndex++;
    }
  }

  /// Retrocede a la pregunta anterior si existe
  void goToPrevious() {
    if (currentIndex > 0) {
      currentIndex--;
    }
  }

  /// Devuelve true si esa pregunta se respondió correctamente
  bool? wasQuestionCorrect(int questionId) {
    return _answersByQuestionId[questionId];
  }

  /// Devuelve el mapa interno de respuestas (útil para estadísticas, guardar progreso, etc.)
  Map<int, bool> get answers => Map.unmodifiable(_answersByQuestionId);
}
