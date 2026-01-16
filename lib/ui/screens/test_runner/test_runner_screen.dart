import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../data/questions/question_repository.dart';
import '../../../data/questions/question_model.dart';
import '../../../data/stats/stats_repository.dart';
import '../../../data/failed_questions/failed_questions_repository.dart';
import '../../../logic/test_engine/test_engine.dart';
import '../../../logic/test_engine/test_session.dart';
import '../../widgets/app_footer.dart';

class TestRunnerScreen extends StatefulWidget {
  final String title;
  final bool withTimer;

  /// FunciÃ³n que, dado un [TestEngine], construye la sesiÃ³n de test.
  final Future<TestSession> Function(TestEngine engine) sessionBuilder;

  const TestRunnerScreen({
    super.key,
    required this.title,
    required this.withTimer,
    required this.sessionBuilder,
  });

  /// Named constructor para â€œtest por temaâ€.
  factory TestRunnerScreen.forTopic({required TopicTestConfig config}) {
    return TestRunnerScreen(
      title: config.topicName,
      withTimer: config.withTimer,
      sessionBuilder: (engine) => engine.startTopicTest(config),
    );
  }

  /// Named constructor para â€œtest personalizadoâ€ (varios temas).
  factory TestRunnerScreen.forCustom({required CustomTestConfig config}) {
    return TestRunnerScreen(
      title: 'Test personalizado',
      withTimer: config.withTimer,
      sessionBuilder: (engine) => engine.startCustomTest(config),
    );
  }

  /// Named constructor para test de preguntas falladas.
  factory TestRunnerScreen.forFailedQuestions({
    required List<Question> questions,
  }) {
    return TestRunnerScreen(
      title: 'Preguntas falladas',
      withTimer: false,
      sessionBuilder: (_) => Future.value(
        TestSession(
          questions: questions,
          failedQuestionIds: questions.map((q) => q.id).toSet(),
        ),
      ),
    );
  }

  @override
  State<TestRunnerScreen> createState() => _TestRunnerScreenState();
}

class _TestRunnerScreenState extends State<TestRunnerScreen> {
  late final TestEngine _engine;
  final StatsRepository _statsRepository = StatsRepository();
  final FailedQuestionsRepository _failedQuestionsRepository =
      FailedQuestionsRepository();
  Set<String> _failedQuestionIds = {};

  bool _isLoading = true;
  String? _errorMessage;

  // Datos del test
  List<Question> _questions = [];
  List<List<AnswerOption>> _optionsPerQuestion = [];
  List<int?> _selectedOptionIndices = [];
  List<bool> _marked = [];
  int _currentIndex = 0;

  // Resultado final (solo se rellenan al finalizar)
  bool _isFinished = false;
  int _finalCorrect = 0;
  int _finalWrong = 0;
  double _finalScore = 0.0;

  // Timer
  Timer? _timer;
  Duration? _remaining;
  static const int _secondsPerQuestion = 72;

  @override
  void initState() {
    super.initState();
    _engine = TestEngine(questionRepository: SqliteQuestionRepository());
    _loadSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isFinished = false;
    });

    try {
      final session = await widget.sessionBuilder(_engine);

      final questions = session.questions;
      _failedQuestionIds = session.failedQuestionIds;
      final optionsPerQuestion = questions
          .map((q) => session.getShuffledOptions(question: q))
          .toList();

      setState(() {
        _questions = questions;
        _optionsPerQuestion = optionsPerQuestion;
        _selectedOptionIndices = List<int?>.filled(
          questions.length,
          null,
          growable: false,
        );
        _marked = List<bool>.filled(questions.length, false, growable: false);
        _currentIndex = 0;
        _isLoading = false;
      });

      if (widget.withTimer) {
        _startTimer();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();

    final totalSeconds = (_questions.length * _secondsPerQuestion).clamp(
      600,
      120 * 60,
    );
    _remaining = Duration(seconds: totalSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remaining == null) return;
        final left = _remaining! - const Duration(seconds: 1);
        if (left.isNegative || left.inSeconds == 0) {
          _remaining = Duration.zero;
          _timer?.cancel();
          _finishTest(auto: true);
        } else {
          _remaining = left;
        }
      });
    });
  }

  // --- LÃ³gica de selecciÃ³n de opciones ---

  void _onSelectOption(int optionIndex) {
    if (_isFinished) return;
    setState(() {
      _selectedOptionIndices[_currentIndex] = optionIndex;
    });
  }

  void _onToggleMark() {
    if (_isFinished) return;
    setState(() {
      _marked[_currentIndex] = !_marked[_currentIndex];
    });
  }

  void _goToIndex(int index) {
    if (_isFinished) return;
    if (index < 0 || index >= _questions.length) return;
    setState(() {
      _currentIndex = index;
    });
  }

  void _goPrev() => _goToIndex(_currentIndex - 1);
  void _goNext() => _goToIndex(_currentIndex + 1);

  void _clearCurrentAnswer() {
    if (_isFinished) return;
    setState(() {
      _selectedOptionIndices[_currentIndex] = null;
    });
  }

  int get _answeredCount =>
      _selectedOptionIndices.where((i) => i != null).length;

  double get _progressPct =>
      _questions.isEmpty ? 0 : _answeredCount / _questions.length;

  // --- Finalizar test y corregir ---

  Future<void> _finishTest({bool auto = false}) async {
    if (_isFinished) return;

    final responded = _answeredCount;
    if (!auto) {
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Finalizar test'),
              content: Text(
                'Has contestado $responded de ${_questions.length} preguntas.\n'
                'Una vez finalizado, veras la correccion.\n\n'
                'Quieres finalizar el test?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Finalizar'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) return;
    }

    _timer?.cancel();

    int correct = 0;
    int wrong = 0;
    final List<FailedQuestionWrite> failedAttempts = [];
    final List<String> resolvedFailed = [];

    for (var i = 0; i < _questions.length; i++) {
      final selectedIndex = _selectedOptionIndices[i];
      if (selectedIndex == null) continue;
      final option = _optionsPerQuestion[i][selectedIndex];
      if (option.isCorrect) {
        correct++;
        if (_failedQuestionIds.contains(_questions[i].id)) {
          resolvedFailed.add(_questions[i].id);
        }
      } else {
        wrong++;
        failedAttempts.add(
          FailedQuestionWrite(
            questionId: _questions[i].id,
            selectedAnswer: option.text,
          ),
        );
      }
    }

    final pointsPerQuestion = _questions.isEmpty ? 0 : 10 / _questions.length;
    final rawScore = correct * pointsPerQuestion - wrong * 0.33;
    final score = rawScore.clamp(0, 10).toDouble();
    final answered = correct + wrong;

    setState(() {
      _isFinished = true;
      _finalCorrect = correct;
      _finalWrong = wrong;
      _finalScore = score;
    });

    unawaited(
      _statsRepository
          .addTestResult(answered: answered, correct: correct, wrong: wrong)
          .catchError((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No se pudieron guardar las estadisticas del test.',
                ),
              ),
            );
          }),
    );

    if (failedAttempts.isNotEmpty) {
      unawaited(
        _failedQuestionsRepository.addFailedAttempts(failedAttempts).catchError(
          (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No se pudieron registrar las preguntas falladas.',
                ),
              ),
            );
          },
        ),
      );
    }

    if (resolvedFailed.isNotEmpty) {
      unawaited(
        _failedQuestionsRepository
            .removeFailedQuestions(resolvedFailed)
            .catchError((_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No se pudieron limpiar las preguntas acertadas.',
                  ),
                ),
              );
            }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildError(theme)
            : _buildContent(theme),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 40),
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
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isFinished) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: _buildResults(theme),
      );
    }

    final question = _questions[_currentIndex];
    final options = _optionsPerQuestion[_currentIndex];
    final selectedIndex = _selectedOptionIndices[_currentIndex];
    final isMarked = _marked[_currentIndex];

    return Column(
      children: [
        _buildHeader(theme),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta de pregunta
                Container(
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera pregunta
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Pregunta ${_currentIndex + 1}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _onToggleMark,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              backgroundColor: isMarked
                                  ? AppColors.error.withValues(alpha: 0.06)
                                  : AppColors.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isMarked
                                      ? AppColors.error
                                      : AppColors.border,
                                ),
                              ),
                            ),
                            icon: Icon(
                              Icons.flag_rounded,
                              size: 18,
                              color: isMarked
                                  ? AppColors.error
                                  : AppColors.textPrimary,
                            ),
                            label: Text(
                              isMarked ? 'Marcada' : 'Marcar para revisar',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        question.text,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Opciones
                      Column(
                        children: List.generate(options.length, (index) {
                          final option = options[index];
                          final bool isSelected = selectedIndex == index;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _onSelectOption(index),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(
                                          alpha: 0.12,
                                        )
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.border,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? AppColors.primary.withValues(
                                                alpha: 0.2,
                                              )
                                            : Colors.transparent,
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        option.text,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Indice de preguntas
                Container(
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
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Indice de preguntas',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.1,
                            ),
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          final answered =
                              _selectedOptionIndices[index] != null;
                          final marked = _marked[index];
                          final active = index == _currentIndex;

                          Color bg = AppColors.background;
                          Color textColor = AppColors.textMuted;
                          Color border = AppColors.border;

                          if (answered) {
                            bg = AppColors.primary.withValues(alpha: 0.12);
                            textColor = AppColors.textPrimary;
                          }

                          if (marked) {
                            bg = const Color(0xFFFFF3C4); // amarillo suave
                            border = AppColors.error;
                          }

                          if (active) {
                            border = AppColors.primary;
                          }

                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _goToIndex(index),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: bg,
                                border: Border.all(color: border),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _legendDot(
                            theme,
                            label: 'Sin contestar',
                            color: const Color(0xFFE3E6EC),
                          ),
                          _legendDot(
                            theme,
                            label: 'Contestada',
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                          _legendDot(
                            theme,
                            label: 'Marcada',
                            color: const Color(0xFFFFF3C4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildFinishButton(theme),

                const SizedBox(height: 80),
                const AppFooter(),
              ],
            ),
          ),
        ),
        _buildBottomNav(theme),
      ],
    );
  }

  Widget _legendDot(
    ThemeData theme, {
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final minutes = _remaining != null
        ? _remaining!.inMinutes.remainder(60)
        : null;
    final seconds = _remaining != null
        ? _remaining!.inSeconds.remainder(60)
        : null;

    final hasTimer = widget.withTimer && _remaining != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Marca
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
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
                child: const Icon(Icons.shield, size: 18, color: Colors.black),
              ),
              const SizedBox(width: 8),
              Text(
                'BomberAPP',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Progreso
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: _progressPct,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '$_answeredCount / ${_questions.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (hasTimer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
                color: AppColors.background,
              ),
              child: Text(
                '${minutes!.toString().padLeft(2, '0')}:${seconds!.toString().padLeft(2, '0')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isFirst ? null : _goPrev,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.arrow_back),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: _clearCurrentAnswer,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.backspace_outlined),
                label: const Text('Limpiar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: isLast ? null : _goNext,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.arrow_forward),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishButton(ThemeData theme) {
    final isLast = _currentIndex == _questions.length - 1;

    final child = isLast
        ? ElevatedButton(
            onPressed: () => _finishTest(auto: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Finalizar test',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          )
        : OutlinedButton(
            onPressed: () => _finishTest(auto: false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Finalizar'),
          );

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: child,
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
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
                value: _questions.length.toString(),
              ),
              const SizedBox(height: 8),
              _resultRow(
                theme,
                label: 'Contestadas',
                value: _answeredCount.toString(),
              ),
              const SizedBox(height: 8),
              _resultRow(
                theme,
                label: 'Aciertos',
                value: _finalCorrect.toString(),
                valueColor: AppColors.success,
              ),
              const SizedBox(height: 8),
              _resultRow(
                theme,
                label: 'Fallos',
                value: _finalWrong.toString(),
                valueColor: AppColors.error,
              ),
              const SizedBox(height: 8),
              _resultRow(
                theme,
                label: 'Puntuacion sobre 10 (-0,33 por fallo)',
                value: _finalScore.toStringAsFixed(2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Finalizar'),
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
