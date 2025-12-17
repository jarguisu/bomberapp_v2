import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../logic/test_engine/test_engine.dart';
import '../../../data/questions/question_repository.dart';
import '../../../data/topics/topic_catalog.dart';
import '../test_runner/test_runner_screen.dart';
import '../../widgets/app_footer.dart';

class CustomTestConfigScreen extends StatefulWidget {
  const CustomTestConfigScreen({super.key});

  @override
  State<CustomTestConfigScreen> createState() =>
      _CustomTestConfigScreenState();
}

class _CustomTestConfigScreenState extends State<CustomTestConfigScreen> {
  late final List<_CustomBlock> _blocks;

  // Estado
  final Set<String> _selectedTopicIds = {}; // ej: {'G1','G2'}
  String _searchText = '';
  double _numQuestions = 20;
  bool _withTimer = false;

  int get _selectedTopicsCount => _selectedTopicIds.length;

  int get _selectedBlocksCount {
    final blocks = <String>{};
    for (final block in _blocks) {
      final hasSelected = block.topics
          .any((t) => _selectedTopicIds.contains(t.topicId));
      if (hasSelected) blocks.add(block.id);
    }
    return blocks.length;
  }

  void _toggleTopic(_CustomTopic topic) {
    setState(() {
      if (_selectedTopicIds.contains(topic.topicId)) {
        _selectedTopicIds.remove(topic.topicId);
      } else {
        _selectedTopicIds.add(topic.topicId);
      }
    });
  }

  void _toggleBlock(String blockId) {
    final block =
        _blocks.firstWhere((b) => b.id == blockId, orElse: () => _blocks.first);
    if (block.topics.isEmpty) return;

    final allSelected =
        block.topics.every((t) => _selectedTopicIds.contains(t.topicId));

    setState(() {
      if (allSelected) {
        // Deseleccionar todo ese bloque
        for (final t in block.topics) {
          _selectedTopicIds.remove(t.topicId);
        }
      } else {
        // Seleccionar todo el bloque
        for (final t in block.topics) {
          _selectedTopicIds.add(t.topicId);
        }
      }
    });
  }

  void _quickSelectBlock(String blockId) {
    final block =
        _blocks.firstWhere((b) => b.id == blockId, orElse: () => _blocks.first);
    if (block.topics.isEmpty) return;

    setState(() {
      for (final t in block.topics) {
        _selectedTopicIds.add(t.topicId);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedTopicIds.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _blocks = topicBlocks
        .map(
          (block) => _CustomBlock(
            id: block.id,
            label: block.label,
            topics: block.topics
                .map((t) => _CustomTopic.fromTopicRef(t))
                .toList(),
          ),
        )
        .toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value.trim().toLowerCase();
    });
  }

  void _onSubmit() {
    if (_selectedTopicIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un tema.')),
      );
      return;
    }

    final selectedTopics = _blocks
        .expand((b) => b.topics)
        .where((t) => _selectedTopicIds.contains(t.topicId))
        .map((t) => t.toFilter())
        .toList();

    final config = CustomTestConfig(
      topics: selectedTopics,
      numQuestions: _numQuestions.toInt(),
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
              // Marca
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
                        'Ayuda: selecciona uno o varios temas y ajusta preguntas/cronómetro.',
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
              _buildHero(theme),
              const SizedBox(height: 16),
              _buildQuickActions(theme),
              const SizedBox(height: 12),
              _buildBlocks(theme),
              const SizedBox(height: 16),
              _buildConfigCard(theme),
              const SizedBox(height: 16),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(ThemeData theme) {
    final temas = _selectedTopicsCount;
    final bloques = _selectedBlocksCount;

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
            'Test personalizado',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Elige libremente temas de uno o varios bloques para crear tu propio test.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _pill(
                theme,
                label:
                    '$temas ${temas == 1 ? 'tema' : 'temas'} seleccionados',
              ),
              _pill(
                theme,
                label:
                    '$bloques ${bloques == 1 ? 'bloque' : 'bloques'}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(ThemeData theme, {required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
        color: AppColors.background,
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
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
            'Acciones rápidas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
          _quickButton(
            theme,
            label: 'Seleccionar Bloque general',
            onTap: () => _quickSelectBlock('G'),
          ),
          _quickButton(
            theme,
            label: 'Seleccionar Bloque específico',
            onTap: () => _quickSelectBlock('E'),
          ),
          _quickButton(
            theme,
            label: 'Seleccionar Bloque servicio',
            onTap: () => _quickSelectBlock('S'),
          ),
              _quickButton(
                theme,
                label: 'Limpiar selección',
                onTap: _clearAll,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar tema… (p. ej., Estatuto)',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickButton(ThemeData theme,
      {required String label, required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: const Size(0, 38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBlocks(ThemeData theme) {
    return Column(
      children: _blocks.map((block) {
        final filteredTopics = block.topics.where((t) {
          if (_searchText.isEmpty) return true;
          return t.label.toLowerCase().contains(_searchText);
        }).toList();

        final total = block.topics.length;
        final visibles = filteredTopics.length;

        final allSelected = block.topics.isNotEmpty &&
            block.topics.every(
                (t) => _selectedTopicIds.contains(t.topicId));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
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
              // Cabecera bloque
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: block.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '  (${total} temas)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed:
                        block.topics.isEmpty ? null : () => _toggleBlock(block.id),
                    child: Text(
                      allSelected ? 'Ninguno' : 'Seleccionar todo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (visibles == 0)
                Text(
                  'No hay temas que coincidan con la búsqueda.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filteredTopics.map((topic) {
                    final selected =
                        _selectedTopicIds.contains(topic.topicId);
                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _toggleTopic(topic),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.background,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              topic.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfigCard(ThemeData theme) {
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

          // Nº preguntas
          Text(
            'Número de preguntas',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _numQuestions,
                  min: 20,
                  max: 100,
                  divisions: 8,
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
          const SizedBox(height: 4),
          Text(
            'De 20 a 100, en pasos de 10.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 12),

          // Cronómetro
          Text(
            'Cronómetro',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
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
          const SizedBox(height: 4),
          Text(
            'Usamos ~1,2 min por pregunta (72 s). Ej.: 20→24 min, 100→120 min.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 16),

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
}

// ----------------- Helpers internos -----------------

class _CustomBlock {
  final String id; // G, E, S
  final String label;
  final List<_CustomTopic> topics;

  const _CustomBlock({
    required this.id,
    required this.label,
    required this.topics,
  });
}

class _CustomTopic {
  final String topicId; // Ej: GEN_CV_G2
  final String topicCode; // Ej: G2
  final String topicName; // Texto visible
  final String blockId; // G/E/S
  final String entityId;
  final String entityName;
  final String syllabusId;
  final String syllabusName;

  const _CustomTopic({
    required this.topicId,
    required this.topicCode,
    required this.topicName,
    required this.blockId,
    required this.entityId,
    required this.entityName,
    required this.syllabusId,
    required this.syllabusName,
  });

  String get label => '$topicCode - $topicName';

  QuestionTopicFilter toFilter() => QuestionTopicFilter(
        topicId: topicId,
      );

  factory _CustomTopic.fromTopicRef(TopicRef ref) {
    return _CustomTopic(
      topicId: ref.topicId,
      topicCode: ref.topicCode,
      topicName: ref.topicName,
      blockId: ref.blockId,
      entityId: ref.entityId,
      entityName: ref.entityName,
      syllabusId: ref.syllabusId,
      syllabusName: ref.syllabusName,
    );
  }
}
