import 'package:flutter/material.dart';

import '../../../data/failed_questions/failed_questions_repository.dart';
import '../../../data/questions/question_model.dart';
import '../../../data/questions/question_repository.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/app_footer.dart';
import '../test_runner/test_runner_screen.dart';

class FailedQuestionsScreen extends StatefulWidget {
  const FailedQuestionsScreen({super.key});

  @override
  State<FailedQuestionsScreen> createState() => _FailedQuestionsScreenState();
}

class _FailedQuestionsScreenState extends State<FailedQuestionsScreen> {
  final _failedRepo = FailedQuestionsRepository();
  final _questionRepo = SqliteQuestionRepository();

  void _startFailedTest(List<Question> questions) {
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay preguntas falladas disponibles para el test.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TestRunnerScreen.forFailedQuestions(questions: questions),
      ),
    );
  }

  Future<Map<String, Question>> _loadQuestionsByIds(List<String> ids) async {
    final questions = await _questionRepo.getQuestionsByIds(ids);
    return {for (final q in questions) q.id: q};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: AppColors.card,
        elevation: 4,
        shadowColor: AppColors.shadowColor,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const SweepGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryVariant,
                          AppColors.primary,
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowColor,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield,
                      size: 22,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'BomberAPP',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ayuda: repasa tus preguntas falladas y practica sobre ellas.',
                      ),
                    ),
                  );
                },
                child: const Text('Ayuda'),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<FailedQuestionRecord>>(
          stream: _failedRepo.streamFailedQuestions(),
          builder: (context, snapshot) {
            final records = snapshot.data ?? [];

            if (snapshot.connectionState == ConnectionState.waiting &&
                records.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (records.isEmpty) {
              return _EmptyState(theme: theme);
            }

            final ids = records.map((r) => r.questionId).toList();

            return FutureBuilder<Map<String, Question>>(
              future: _loadQuestionsByIds(ids),
              builder: (context, qSnap) {
                final questionsById = qSnap.data ?? {};
                final questions = ids
                    .map((id) => questionsById[id])
                    .whereType<Question>()
                    .toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderCard(theme: theme),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _startFailedTest(questions),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Hacer test de preguntas falladas'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(records.length, (index) {
                        final record = records[index];
                        final question = questionsById[record.questionId];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _FailedQuestionCard(
                            theme: theme,
                            position: index + 1,
                            record: record,
                            question: question,
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      const AppFooter(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preguntas falladas',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Repasa tus errores acumulados de todos los tests.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FailedQuestionCard extends StatelessWidget {
  const _FailedQuestionCard({
    required this.theme,
    required this.position,
    required this.record,
    required this.question,
  });

  final ThemeData theme;
  final int position;
  final FailedQuestionRecord record;
  final Question? question;

  @override
  Widget build(BuildContext context) {
    final q = question;
    final lastDate = record.lastWrongAt;
    final lastDateStr =
        '${lastDate.day.toString().padLeft(2, '0')}/${lastDate.month.toString().padLeft(2, '0')}/${lastDate.year}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  color: AppColors.background,
                ),
                child: Center(
                  child: Text(
                    '$position',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (q != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.background,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    q.topicId,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                'Fallada ${record.wrongCount} vez${record.wrongCount > 1 ? 'es' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            q?.text ?? 'Pregunta no encontrada (id ${record.questionId})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Incorrecta (ultima vez: $lastDateStr)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu respuesta: ${record.selectedAnswer}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          if (q != null)
            Text(
              'Correcta: ${q.correct}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (q != null && q.explanation != null && q.explanation!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Pista: ${q.explanation}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No tienes preguntas falladas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando falles una pregunta, aparecera aqui para que puedas repasarla.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
