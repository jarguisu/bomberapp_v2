import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../data/topics/topic_catalog.dart';
import '../../../logic/test_engine/test_engine.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/bomber_dropdown.dart';
import '../test_runner/test_runner_screen.dart';

class TopicTestConfigScreen extends StatefulWidget {
  const TopicTestConfigScreen({super.key});

  @override
  State<TopicTestConfigScreen> createState() => _TopicTestConfigScreenState();
}

class _TopicTestConfigScreenState extends State<TopicTestConfigScreen> {
  String? _selectedBlockId;
  String? _selectedTopicId;
  double _numQuestions = 20;
  bool _withTimer = false;

  TopicBlock? get _selectedBlock {
    if (_selectedBlockId == null) return null;
    return topicBlocks.firstWhere(
      (b) => b.id == _selectedBlockId,
      orElse: () => topicBlocks.first,
    );
  }

  List<TopicRef> get _topicsForSelectedBlock {
    final block = _selectedBlock;
    if (block == null) return const [];
    return block.topics;
  }

  TopicRef? get _selectedTopicRef {
    final block = _selectedBlock;
    if (block == null || _selectedTopicId == null) return null;
    return block.topics.firstWhere(
      (t) => t.topicId == _selectedTopicId,
      orElse: () => block.topics.first,
    );
  }

  void _onSubmit() {
    if (_selectedBlockId == null || _selectedTopicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona bloque y tema para continuar.'),
        ),
      );
      return;
    }

    final topic = _selectedTopicRef;
    if (topic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ha ocurrido un error con el tema seleccionado.'),
        ),
      );
      return;
    }

    final int n = _numQuestions.toInt();

    final config = TopicTestConfig(
      blockId: topic.blockId,
      topicCode: topic.topicCode,
      topicId: topic.topicId,
      topicName: topic.topicName,
      entityId: topic.entityId,
      syllabusId: topic.syllabusId,
      numQuestions: n,
      withTimer: _withTimer,
    );

    Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => TestRunnerScreen.forTopic(config: config),
  ),
);

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
                      content: Text(
                        'Ayuda: explicación rápida del modo por tema.',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroSection(theme),
              const SizedBox(height: 16),
              _buildFormCard(theme),
              const SizedBox(height: 16),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------
  // HERO
  // --------------------------
  Widget _buildHeroSection(ThemeData theme) {
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurar test por tema',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Selecciona bloque y tema, elige cuántas preguntas y si quieres cronómetro.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Text(
              'Penalización −0,33 activa',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Las erróneas restan 0,33. Las en blanco no penalizan.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------
  // FORM
  // --------------------------
  Widget _buildFormCard(ThemeData theme) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajustes',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

          // Bloque
          _buildField(
            label: 'Bloque',
            hint: 'Elige primero el bloque para filtrar los temas.',
            child: BomberDropdown<String>(
              value: _selectedBlockId,
              hint: 'Selecciona un bloque…',
              items: topicBlocks
                  .map(
                    (block) => DropdownMenuItem<String>(
                      value: block.id,
                      child: Text(block.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBlockId = value;
                  _selectedTopicId = null;
                });
              },
            ),
          ),

          const SizedBox(height: 12),

          // Tema
          _buildField(
            label: 'Tema',
            child: BomberDropdown<String>(
              value: _selectedTopicId,
              hint: 'Selecciona un tema…',
              items: _topicsForSelectedBlock
                  .map(
                    (topic) => DropdownMenuItem<String>(
                      value: topic.topicId,
                      child: Text(topic.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTopicId = value;
                });
              },
            ),
          ),

          const SizedBox(height: 12),

          // Número de preguntas
          _buildField(
            label: 'Número de preguntas',
            hint: 'De 5 a 50, en pasos de 5.',
            child: Row(
              children: [
                  Expanded(
                    child: Slider(
                      value: _numQuestions,
                      min: 5,
                      max: 50,
                      divisions: 9,
                      label: _numQuestions.toInt().toString(),
                      onChanged: (value) {
                        setState(() {
                          _numQuestions = value;
                        });
                      },
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                    color: AppColors.background,
                  ),
                  child: Text(
                    _numQuestions.toInt().toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Cronómetro
          _buildField(
            label: 'Cronómetro',
            hint: '72s por pregunta (1,2 min). Ejemplos: 5→6 min, 50→60 min.',
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                color: AppColors.background,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Con cronómetro automático',
                      overflow: TextOverflow.ellipsis,
                    ),
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
            ),
          ),

          const SizedBox(height: 16),

          // CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _onSubmit,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------
  // Helpers UI
  // --------------------------
  Widget _buildField({
    required String label,
    Widget? child,
    String? hint,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        if (child != null) child,
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
