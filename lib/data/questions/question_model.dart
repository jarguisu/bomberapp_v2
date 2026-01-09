class Question {
  final String id; // ID único de la pregunta
  final String topicId; // Relación con el tema en el catálogo
  final String text; // Enunciado de la pregunta
  final String correct; // Respuesta correcta
  final String wrong1; // Respuesta incorrecta 1
  final String wrong2; // Respuesta incorrecta 2
  final String wrong3; // Respuesta incorrecta 3
  final String? explanation; // Explicación opcional
  final String? reference; // Referencia legal/artículo opcional
  final int? difficulty; // 1 = fácil, 2 = media, 3 = difícil
  final String? source; // Origen (Oficial, Elaboración propia...)
  final int? year; // Año del examen si aplica

  const Question({
    required this.id,
    required this.topicId,
    required this.text,
    required this.correct,
    required this.wrong1,
    required this.wrong2,
    required this.wrong3,
    this.explanation,
    this.reference,
    this.difficulty,
    this.source,
    this.year,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as String,
      topicId: map['topic_id'] as String,
      text: map['text'] as String,
      correct: map['correct'] as String,
      wrong1: map['wrong1'] as String,
      wrong2: map['wrong2'] as String,
      wrong3: map['wrong3'] as String,
      explanation: map['explanation'] as String?,
      reference: map['reference'] as String?,
      difficulty: map['difficulty'] as int?,
      source: map['source'] as String?,
      year: map['year'] as int?,
    );
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    // Permitimos JSON con campos extra; sólo leemos los necesarios.
    return Question(
      id: json['id'] as String,
      topicId: json['topic_id'] as String,
      text: json['text'] as String,
      correct: json['correct'] as String,
      wrong1: json['wrong1'] as String,
      wrong2: json['wrong2'] as String,
      wrong3: json['wrong3'] as String,
      explanation: json['explanation'] as String?,
      reference: json['reference'] as String?,
      difficulty: json['difficulty'] as int?,
      source: json['source'] as String?,
      year: json['year'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic_id': topicId,
      'text': text,
      'correct': correct,
      'wrong1': wrong1,
      'wrong2': wrong2,
      'wrong3': wrong3,
      'explanation': explanation,
      'reference': reference,
      'difficulty': difficulty,
      'source': source,
      'year': year,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
