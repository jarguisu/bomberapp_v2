import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../data/questions/question_repository.dart';
import '../../../logic/test_engine/test_engine.dart';
import '../../../logic/test_engine/test_session.dart';
import '../../widgets/app_footer.dart';

class TestRunnerScreen extends StatefulWidget {
  final TopicTestConfig config;

  const TestRunnerScreen({
    super.key,
    required this.config,
  });

  @override
  State<TestRunnerScreen> createState() => _TestRunnerScreenState();
}

class _TestRunnerScreenState extends State<TestRunnerScreen> {
  late final TestEngine _engine;
  TestSession? _session;
  List<AnswerOption> _currentOptions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _engine = TestEngine(
      questionRepository: SqliteQuestionRepository(),
    );
    _loadSession();
  }

  Future<void> _loadSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await _engine.startTopicTest(widget.config);
      setState(() {
        _session = session;
        _currentOptions = session.getShuffledOptions();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onAnswer(AnswerOption option) {
    final session = _session;
    if (session == null) return;

    // Registramos respuesta solo si aún no estaba contestada
    if (!session.isCurrentAnswered) {
      session.answerCurrent(isCorrect: option.isCorrect);
    }

    if (session.isFinished) {
      setState(() {});
    } else {
      session.goToNext();
      setState(() {
        _currentOptions = session.getShuffledOptions();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.config.topicName,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _errorMessage != null
                  ? _buildError(theme)
                  : _buildContent(theme),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          color: AppColors.error,
          size: 40,
        ),
        const SizedBox(height: 12),
        Text(
          'No se ha podido cargar el test.',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? 'Error desconocido',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadSession,
          child: const Text('Reintentar'),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    final session = _session!;
    if (session.isFinished) {
      return _buildResults(theme, session);
    }

    final question = session.currentQuestion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info superior (progreso)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pregunta ${session.currentIndex + 1} de ${session.questions.length}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Aciertos: ${session.correctCount}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Enunciado
        Container(
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
          child: Text(
            question.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Opciones
        Expanded(
          child: ListView.separated(
            itemCount: _currentOptions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final option = _currentOptions[index];
              return _buildOptionButton(theme, option);
            },
          ),
        ),

        const SizedBox(height: 8),
        const AppFooter(),
      ],
    );
  }

  Widget _buildOptionButton(ThemeData theme, AnswerOption option) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _onAnswer(option),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.card,
          foregroundColor: AppColors.textPrimary,
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            option.text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildResults(ThemeData theme, TestSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Resultados del test',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
              _resultRow(
                theme,
                label: 'Preguntas totales',
                value: session.questions.length.toString(),
              ),
              const SizedBox(height: 8),
              _resultRow(
                theme,
                label: 'Aciertos',
                value: session.correctCount.toString(),
                valueColor: AppColors.success,
              ),
              const SizedBox(height: 8),
              _resultRow(
                theme,
                label: 'Fallos',
                value: session.wrongCount.toString(),
                valueColor: AppColors.error,
              ),
              const SizedBox(height: 8),
              _resultRow(
                theme,
                label: 'Puntuación (−0,33 por fallo)',
                value: session.scoreWithPenalty.toStringAsFixed(2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop(); // Volver atrás
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Volver'),
        ),
        const SizedBox(height: 8),
        const AppFooter(),
      ],
    );
  }

  Widget _resultRow(
    ThemeData theme, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
