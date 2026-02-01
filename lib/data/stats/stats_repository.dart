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

class TopicStatSummary {
  final String topicId;
  final int correct;
  final int wrong;
  final int answered;

  const TopicStatSummary({
    required this.topicId,
    required this.correct,
    required this.wrong,
    required this.answered,
  });

  TopicStatSummary copyWith({
    int? correct,
    int? wrong,
    int? answered,
  }) {
    return TopicStatSummary(
      topicId: topicId,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      answered: answered ?? this.answered,
    );
  }
}

class StatsRepository {
  StatsRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  User? _currentUser() => _auth.currentUser;

  DocumentReference<Map<String, dynamic>> _summaryRefFor(User user) {
    return _db.collection('users').doc(user.uid).collection('stats').doc('summary');
  }

  CollectionReference<Map<String, dynamic>> _attemptsRefFor(User user) {
    return _summaryRefFor(user).collection('attempts');
  }

  Future<StatsSummary> fetchSummary() async {
    final user = _currentUser();
    if (user == null) return StatsSummary.empty();
    final snap = await _summaryRefFor(user).get();
    final data = snap.data();
    if (data == null) return StatsSummary.empty();
    return StatsSummary.fromMap(data);
  }

  Future<int> fetchAnsweredToday() async {
    final user = _currentUser();
    if (user == null) return 0;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final since = Timestamp.fromDate(startOfDay);

    final snap = await _attemptsRefFor(user)
        .where('createdAt', isGreaterThanOrEqualTo: since)
        .get();

    var answered = 0;
    for (final doc in snap.docs) {
      answered += _asInt(doc.data()['answered']);
    }
    return answered;
  }

  Stream<StatsSummary> summaryStream() {
    final user = _currentUser();
    if (user == null) {
      return Stream.value(StatsSummary.empty());
    }
    return _summaryRefFor(user).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return StatsSummary.empty();
      return StatsSummary.fromMap(data);
    });
  }

  Stream<StatsSummary> windowSummaryStream({
    Duration window = const Duration(days: 30),
  }) {
    final user = _currentUser();
    if (user == null) {
      return Stream.value(StatsSummary.empty());
    }
    final since = Timestamp.fromDate(DateTime.now().subtract(window));

    return _attemptsRefFor(user)
        .where('createdAt', isGreaterThanOrEqualTo: since)
        .snapshots()
        .map(_aggregateAttempts);
  }

  Stream<List<TopicStatSummary>> topicStatsStream({
    Duration? window,
  }) {
    final user = _currentUser();
    if (user == null) {
      return Stream.value(const []);
    }
    Query<Map<String, dynamic>> query = _attemptsRefFor(user);

    if (window != null) {
      final since = Timestamp.fromDate(DateTime.now().subtract(window));
      query = query.where('createdAt', isGreaterThanOrEqualTo: since);
    }

    return query.snapshots().map((snap) {
      final Map<String, TopicStatSummary> aggregated = {};

      for (final doc in snap.docs) {
        final data = doc.data();
        final byTopic = data['byTopic'];
        if (byTopic is! Map<String, dynamic>) continue;

        for (final entry in byTopic.entries) {
          final topicId = entry.key;
          final raw = entry.value;
          if (raw is! Map<String, dynamic>) continue;

          final correct = _asInt(raw['correct']);
          final wrong = _asInt(raw['wrong']);
          final answered = _asInt(raw['answered']);

          final current = aggregated[topicId];
          if (current == null) {
            aggregated[topicId] = TopicStatSummary(
              topicId: topicId,
              correct: correct,
              wrong: wrong,
              answered: answered,
            );
          } else {
            aggregated[topicId] = current.copyWith(
              correct: current.correct + correct,
              wrong: current.wrong + wrong,
              answered: current.answered + answered,
            );
          }
        }
      }

      return aggregated.values.toList(growable: false);
    });
  }

  Future<void> addTestResult({
    required int answered,
    required int correct,
    required int wrong,
    required int totalQuestions,
    required double score,
    required Map<String, TopicStatSummary> byTopic,
  }) async {
    final user = _currentUser();
    if (user == null) {
      throw StateError('No hay usuario autenticado.');
    }
    final ref = _summaryRefFor(user);
    final attemptsRef = _attemptsRefFor(user);
    final attemptDoc = attemptsRef.doc();

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        tx.set(ref, StatsSummary.initialData());
      }

      final currentBest = _asDouble(snap.data()?['bestScore']);
      final nextBest = score > currentBest ? score : currentBest;

      tx.update(ref, {
        'totalAttempts': FieldValue.increment(1),
        'totalAnswered': FieldValue.increment(answered),
        'totalCorrect': FieldValue.increment(correct),
        'totalWrong': FieldValue.increment(wrong),
        'bestScore': nextBest,
        'lastAttemptAt': FieldValue.serverTimestamp(),
      });

      tx.set(attemptDoc, {
        'createdAt': FieldValue.serverTimestamp(),
        'answered': answered,
        'correct': correct,
        'wrong': wrong,
        'totalQuestions': totalQuestions,
        'score': score,
        'byTopic': _serializeTopicStats(byTopic),
      });
    });
  }

  StatsSummary _aggregateAttempts(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    var answered = 0;
    var correct = 0;
    var wrong = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      answered += _asInt(data['answered']);
      correct += _asInt(data['correct']);
      wrong += _asInt(data['wrong']);
    }

    return StatsSummary(
      totalAttempts: snapshot.docs.length,
      totalAnswered: answered,
      totalCorrect: correct,
      totalWrong: wrong,
      bestScore: 0,
      streakDays: 0,
      lastAttemptAt: null,
    );
  }

  Map<String, dynamic> _serializeTopicStats(
    Map<String, TopicStatSummary> byTopic,
  ) {
    final Map<String, dynamic> result = {};

    for (final entry in byTopic.entries) {
      final item = entry.value;
      result[entry.key] = {
        'correct': item.correct,
        'wrong': item.wrong,
        'answered': item.answered,
      };
    }

    return result;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return 0.0;
  }
}
