import 'dart:math';

import '../../data/questions/question_model.dart';

class AnswerOption {
  final String text;
  final bool isCorrect;

  const AnswerOption({required this.text, required this.isCorrect});
}

class TestSession {
  final List<Question> questions;
  final Map<String, bool> _answersByQuestionId;

  int currentIndex;

  TestSession({
    required this.questions,
    Map<String, bool>? answersByQuestionId,
    this.currentIndex = 0,
  }) : _answersByQuestionId = answersByQuestionId ?? {};

  Question get currentQuestion => questions[currentIndex];

  bool get isCurrentAnswered =>
      _answersByQuestionId.containsKey(currentQuestion.id);

  /// Numero de aciertos
  int get correctCount =>
      _answersByQuestionId.values.where((v) => v == true).length;

  /// Numero de fallos
  int get wrongCount =>
      _answersByQuestionId.values.where((v) => v == false).length;

  double get _pointsPerQuestion =>
      questions.isEmpty ? 0 : 10 / questions.length;

  /// Puntuacion sobre 10 con penalizacion -0,33 por fallo.
  /// Acierto = + (10 / nPreguntas). Blanco = 0. Fallo = -0,33.
  double get scoreWithPenalty {
    final raw = correctCount * _pointsPerQuestion - wrongCount * 0.33;
    return raw.clamp(0, 10).toDouble();
  }

  /// Devuelve las 4 opciones de respuesta de una pregunta, ya mezcladas.
  /// Si quieres usarlo para otra pregunta, pasala como parametro;
  /// si no, usa la [currentQuestion].
  List<AnswerOption> getShuffledOptions({Question? question}) {
    final q = question ?? currentQuestion;

    final options = <AnswerOption>[
      AnswerOption(text: q.correct, isCorrect: true),
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

  /// Devuelve true si esa pregunta se respondio correctamente
  bool? wasQuestionCorrect(String questionId) {
    return _answersByQuestionId[questionId];
  }

  /// Devuelve el mapa interno de respuestas (util para estadisticas, guardar progreso, etc.)
  Map<String, bool> get answers => Map.unmodifiable(_answersByQuestionId);
}
