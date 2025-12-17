import 'package:flutter/material.dart';

import '../../../data/questions/question_repository.dart';
import '../../../data/topics/topic_catalog.dart';
import '../../../logic/test_engine/test_engine.dart';
import '../../../theme/app_colors.dart';
import '../test_runner/test_runner_screen.dart';
import '../../widgets/app_footer.dart';

class SimulacroConfigScreen extends StatefulWidget {
  const SimulacroConfigScreen({super.key});

  @override
  State<SimulacroConfigScreen> createState() => _SimulacroConfigScreenState();
}

class _SimulacroConfigScreenState extends State<SimulacroConfigScreen> {
  TopicRef? _selectedServiceTopic;
  bool _withTimer = true;

  List<TopicRef> get _serviceTopics => topicBlocks
      .where((b) => b.id == 'S')
      .expand((b) => b.topics)
      .toList();

  List<TopicRef> get _nonServiceTopics => topicBlocks
      .where((b) => b.id != 'S')
      .expand((b) => b.topics)
      .toList();

  int get _serviceQuestions => _selectedServiceTopic == null ? 0 : 20;
  int get _totalQuestions => _selectedServiceTopic == null ? 80 : 100;
  int get _generalQuestions => _totalQuestions - _serviceQuestions;

  void _startSimulacro() {
    final filters = <QuestionTopicFilter>[
      ..._nonServiceTopics.map(
        (t) => QuestionTopicFilter(topicId: t.topicId),
      ),
    ];

    if (_selectedServiceTopic != null) {
      filters.add(QuestionTopicFilter(topicId: _selectedServiceTopic!.topicId));
    }

    final config = CustomTestConfig(
      topics: filters,
      numQuestions: _totalQuestions,
      withTimer: _withTimer,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TestRunnerScreen.forCustom(config: config),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasService = _serviceTopics.isNotEmpty;

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
              // Marca + título
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowColor,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                      gradient: const SweepGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryVariant,
                          AppColors.primary,
                        ],
                      ),
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
                      content: Text('Ayuda: modo simulacro.'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(theme),
              const SizedBox(height: 14),
              _buildParameters(theme),
              const SizedBox(height: 12),
              _buildDistribution(theme, hasService),
              const SizedBox(height: 12),
              _buildServiceSelector(theme, hasService),
              const SizedBox(height: 12),
              _buildTip(theme),
              const SizedBox(height: 16),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
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
            'Simulacro oficial',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '100 preguntas (80 si no añades Servicio) · 120 minutos · -0,33 por fallo · distribución A/B/C proporcional.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameters(ThemeData theme) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parámetros del simulacro',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _bullet(theme, 'Preguntas: $_totalQuestions'),
          _bullet(
            theme,
            _withTimer ? 'Tiempo: 120 min (cronómetro activo)' : 'Sin cronómetro',
          ),
          _bullet(theme, 'Penalización: -0,33 por respuesta incorrecta'),
          _bullet(theme, 'En blanco: 0 puntos (no penaliza)'),
        ],
      ),
    );
  }

  Widget _buildDistribution(ThemeData theme, bool hasService) {
    final serviceText =
        hasService ? '~20 preguntas (si eliges bloque C)' : '0 preguntas (no disponible)';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución por bloques',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _bullet(theme, 'A — General: ~${(_generalQuestions * 0.25).round()} preguntas'),
          _bullet(theme, 'B — Específico: ~${(_generalQuestions * 0.75).round()} preguntas'),
          _bullet(theme, 'C — Servicio: $serviceText'),
          const SizedBox(height: 6),
          Text(
            'La selección se ajusta a los temas disponibles de cada bloque.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelector(ThemeData theme, bool hasService) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bloque C (Servicio)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedServiceTopic = null;
                  });
                },
                child: const Text('Quitar selección'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Convocatoria/Servicio disponible',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TopicRef>(
                value: _selectedServiceTopic,
                hint: const Text('Selecciona bloque C (opcional)'),
                isExpanded: true,
                items: _serviceTopics
                    .map(
                      (t) => DropdownMenuItem<TopicRef>(
                        value: t,
                        child: Text(t.label),
                      ),
                    )
                    .toList(),
                onChanged: hasService
                    ? (value) {
                        setState(() {
                          _selectedServiceTopic = value;
                        });
                      }
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _startSimulacro(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Iniciar simulacro'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Modo cronometrado',
                style: theme.textTheme.bodyMedium,
              ),
              Switch.adaptive(
                value: _withTimer,
                onChanged: (value) {
                  setState(() {
                    _withTimer = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTip(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Consejo: trátalo como examen real. Cierra notificaciones, respeta el tiempo y al acabar verás nota y desglose.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 6, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
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
      child: child,
    );
  }
}
