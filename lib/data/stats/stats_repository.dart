import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatsSummary {
  final int totalAttempts;
  final int totalAnswered;
  final int totalCorrect;
  final int totalWrong;
  final double bestScore;
  final int streakDays;
  final DateTime? lastAttemptAt;

  const StatsSummary({
    required this.totalAttempts,
    required this.totalAnswered,
    required this.totalCorrect,
    required this.totalWrong,
    required this.bestScore,
    required this.streakDays,
    this.lastAttemptAt,
  });

  factory StatsSummary.fromMap(Map<String, dynamic> data) {
    final totalCorrect = (data['totalCorrect'] as num?)?.toInt() ?? 0;
    final totalWrong = (data['totalWrong'] as num?)?.toInt() ?? 0;

    return StatsSummary(
      totalAttempts: (data['totalAttempts'] as num?)?.toInt() ?? 0,
      totalAnswered:
          (data['totalAnswered'] as num?)?.toInt() ?? (totalCorrect + totalWrong),
      totalCorrect: totalCorrect,
      totalWrong: totalWrong,
      bestScore: (data['bestScore'] as num?)?.toDouble() ?? 0.0,
      streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
      lastAttemptAt: (data['lastAttemptAt'] as Timestamp?)?.toDate(),
    );
  }

  static StatsSummary empty() => const StatsSummary(
        totalAttempts: 0,
        totalAnswered: 0,
        totalCorrect: 0,
        totalWrong: 0,
        bestScore: 0.0,
        streakDays: 0,
        lastAttemptAt: null,
      );

  static Map<String, dynamic> initialData() => {
        'totalAttempts': 0,
        'totalAnswered': 0,
        'totalCorrect': 0,
        'totalWrong': 0,
        'bestScore': 0.0,
        'streakDays': 0,
        'lastAttemptAt': null,
      };
}

class StatsRepository {
  StatsRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
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

  DocumentReference<Map<String, dynamic>> _summaryRefFor(User user) {
    return _db.collection('users').doc(user.uid).collection('stats').doc('summary');
  }

  Future<StatsSummary> fetchSummary() async {
    final user = _requireUser();
    final snap = await _summaryRefFor(user).get();
    final data = snap.data();
    if (data == null) return StatsSummary.empty();
    return StatsSummary.fromMap(data);
  }

  Stream<StatsSummary> summaryStream() {
    final user = _requireUser();
    return _summaryRefFor(user).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return StatsSummary.empty();
      return StatsSummary.fromMap(data);
    });
  }

  Future<void> addTestResult({
    required int answered,
    required int correct,
    required int wrong,
  }) async {
    final user = _requireUser();
    final ref = _summaryRefFor(user);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        tx.set(ref, StatsSummary.initialData());
      }

      tx.update(ref, {
        'totalAttempts': FieldValue.increment(1),
        'totalAnswered': FieldValue.increment(answered),
        'totalCorrect': FieldValue.increment(correct),
        'totalWrong': FieldValue.increment(wrong),
        'lastAttemptAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
