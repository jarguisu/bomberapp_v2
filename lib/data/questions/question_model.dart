class Question {
  final String id; // ID unico de la pregunta
  final String topicId; // Relacion con el tema en el catalogo
  final String text; // Enunciado de la pregunta
  final String correct; // Respuesta correcta
  final String wrong1; // Respuesta incorrecta 1
  final String wrong2; // Respuesta incorrecta 2
  final String wrong3; // Respuesta incorrecta 3
  final String? explanation; // Explicacion opcional
  final String? reference; // Referencia legal/articulo opcional
  final int? difficulty; // 1 = facil, 2 = media, 3 = dificil
  final String? source; // Origen (Oficial, Elaboracion propia...)
  final int? year; // Ano del examen si aplica

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

  static String _requiredString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _optionalInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: _requiredString(map['id']),
      topicId: _requiredString(map['topic_id']),
      text: _requiredString(map['text']),
      correct: _requiredString(map['correct']),
      wrong1: _requiredString(map['wrong1']),
      wrong2: _requiredString(map['wrong2']),
      wrong3: _requiredString(map['wrong3']),
      explanation: _optionalString(map['explanation']),
      reference: _optionalString(map['reference']),
      difficulty: _optionalInt(map['difficulty']),
      source: _optionalString(map['source']),
      year: _optionalInt(map['year']),
    );
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    // Permitimos JSON con campos extra; solo leemos los necesarios.
    return Question(
      id: _requiredString(json['id']),
      topicId: _requiredString(json['topic_id']),
      text: _requiredString(json['text']),
      correct: _requiredString(json['correct']),
      wrong1: _requiredString(json['wrong1']),
      wrong2: _requiredString(json['wrong2']),
      wrong3: _requiredString(json['wrong3']),
      explanation: _optionalString(json['explanation']),
      reference: _optionalString(json['reference']),
      difficulty: _optionalInt(json['difficulty']),
      source: _optionalString(json['source']),
      year: _optionalInt(json['year']),
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
