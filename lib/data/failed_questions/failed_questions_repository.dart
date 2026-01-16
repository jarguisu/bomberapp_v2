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
  final String lastSelectedAnswer;
  final DateTime lastWrongAt;
  final DateTime? lastCorrectAt;
  final int wrongCount;
  final bool isActive;

  const FailedQuestionRecord({
    required this.questionId,
    required this.lastSelectedAnswer,
    required this.lastWrongAt,
    required this.lastCorrectAt,
    required this.wrongCount,
    required this.isActive,
  });

  factory FailedQuestionRecord.fromMap(Map<String, dynamic> data) {
    return FailedQuestionRecord(
      questionId: data['questionId'] as String? ?? '',
      lastSelectedAnswer: data['lastSelectedAnswer'] as String? ??
          data['selectedAnswer'] as String? ??
          '',
      lastWrongAt:
          (data['lastWrongAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastCorrectAt: (data['lastCorrectAt'] as Timestamp?)?.toDate(),
      wrongCount: (data['wrongCount'] as num?)?.toInt() ?? 1,
      isActive: data['isActive'] as bool? ?? true,
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
        'lastSelectedAnswer': attempt.selectedAnswer,
        'lastWrongAt': FieldValue.serverTimestamp(),
        'wrongCount': FieldValue.increment(1),
        'isActive': true,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> markQuestionsCorrect(List<String> questionIds) async {
    if (questionIds.isEmpty) return;
    final user = _requireUser();
    final col = _collectionFor(user);

    const chunkSize = 10;
    for (var i = 0; i < questionIds.length; i += chunkSize) {
      final end = i + chunkSize < questionIds.length
          ? i + chunkSize
          : questionIds.length;
      final chunk = questionIds.sublist(i, end);
      final snap =
          await col.where(FieldPath.documentId, whereIn: chunk).get();
      if (snap.docs.isEmpty) continue;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.set(doc.reference, {
          'isActive': false,
          'lastCorrectAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  Stream<List<FailedQuestionRecord>> streamFailedQuestions() {
    final user = _requireUser();
    return _collectionFor(user)
        .orderBy('lastWrongAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => FailedQuestionRecord.fromMap(d.data()))
              .where((record) => record.isActive)
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
