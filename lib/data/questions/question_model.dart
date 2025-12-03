class Question {
  final int id;                // PK interna (1, 2, 3...)
  final String topicId;        // G1, G2, E1...
  final String topicName;      // Nombre del tema (por redundancia, si quieres)
  final String text;           // La pregunta
  final String correctAnswer;
  final String wrong1;
  final String wrong2;
  final String wrong3;

  const Question({
    required this.id,
    required this.topicId,
    required this.topicName,
    required this.text,
    required this.correctAnswer,
    required this.wrong1,
    required this.wrong2,
    required this.wrong3,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int,
      topicId: map['topic_id'] as String,
      topicName: map['topic_name'] as String,
      text: map['text'] as String,
      correctAnswer: map['correct'] as String,
      wrong1: map['wrong1'] as String,
      wrong2: map['wrong2'] as String,
      wrong3: map['wrong3'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic_id': topicId,
      'topic_name': topicName,
      'text': text,
      'correct': correctAnswer,
      'wrong1': wrong1,
      'wrong2': wrong2,
      'wrong3': wrong3,
    };
  }
}
