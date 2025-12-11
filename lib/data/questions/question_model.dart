class Question {
  final String id; // ID único de la pregunta
  final String blockId; // G, E o S
  final String topicCode; // G1, G2, E3, S1, etc.
  final String topicId; // ID único del tema en el temario
  final String topicName; // Nombre visible del tema
  final String entityId; // Código de la entidad (GEN, CONSVAL...)
  final String entityName; // Nombre largo de la entidad
  final String syllabusId; // ID del temario/convocatoria
  final String syllabusName; // Nombre del temario/convocatoria
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
    required this.blockId,
    required this.topicCode,
    required this.topicId,
    required this.topicName,
    required this.entityId,
    required this.entityName,
    required this.syllabusId,
    required this.syllabusName,
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
      blockId: map['block_id'] as String,
      topicCode: map['topic_code'] as String,
      topicId: map['topic_id'] as String,
      topicName: map['topic_name'] as String,
      entityId: map['entity_id'] as String,
      entityName: map['entity_name'] as String,
      syllabusId: map['syllabus_id'] as String,
      syllabusName: map['syllabus_name'] as String,
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

  factory Question.fromJson(Map<String, dynamic> json) => Question.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'block_id': blockId,
      'topic_code': topicCode,
      'topic_id': topicId,
      'topic_name': topicName,
      'entity_id': entityId,
      'entity_name': entityName,
      'syllabus_id': syllabusId,
      'syllabus_name': syllabusName,
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
