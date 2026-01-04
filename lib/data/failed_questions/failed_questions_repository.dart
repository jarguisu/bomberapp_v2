import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FailedQuestionWrite {
  final String questionId;
  final String selectedAnswer;

  const FailedQuestionWrite({
    required this.questionId,
    required this.selectedAnswer,
  });
}

class FailedQuestionRecord {
  final String questionId;
  final String selectedAnswer;
  final DateTime lastWrongAt;
  final int wrongCount;

  const FailedQuestionRecord({
    required this.questionId,
    required this.selectedAnswer,
    required this.lastWrongAt,
    required this.wrongCount,
  });

  factory FailedQuestionRecord.fromMap(Map<String, dynamic> data) {
    return FailedQuestionRecord(
      questionId: data['questionId'] as String? ?? '',
      selectedAnswer: data['selectedAnswer'] as String? ?? '',
      lastWrongAt:
          (data['lastWrongAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      wrongCount: (data['wrongCount'] as num?)?.toInt() ?? 1,
    );
  }
}

class FailedQuestionsRepository {
  FailedQuestionsRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No hay usuario autenticado.');
    }
    return user;
  }

  CollectionReference<Map<String, dynamic>> _collectionFor(User user) {
    return _db.collection('users').doc(user.uid).collection('failedQuestions');
  }

  Future<void> addFailedAttempts(List<FailedQuestionWrite> attempts) async {
    if (attempts.isEmpty) return;
    final user = _requireUser();
    final col = _collectionFor(user);

    final batch = _db.batch();
    for (final attempt in attempts) {
      final ref = col.doc(attempt.questionId);
      batch.set(ref, {
        'questionId': attempt.questionId,
        'selectedAnswer': attempt.selectedAnswer,
        'lastWrongAt': FieldValue.serverTimestamp(),
        'wrongCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Stream<List<FailedQuestionRecord>> streamFailedQuestions() {
    final user = _requireUser();
    return _collectionFor(user)
        .orderBy('lastWrongAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => FailedQuestionRecord.fromMap(d.data()))
              .toList(),
        );
  }

  Future<void> removeFailedQuestions(List<String> ids) async {
    if (ids.isEmpty) return;
    final user = _requireUser();
    final col = _collectionFor(user);
    final batch = _db.batch();
    for (final id in ids) {
      batch.delete(col.doc(id));
    }
    await batch.commit();
  }
}
