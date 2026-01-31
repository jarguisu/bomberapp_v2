import 'dart:math';

import 'package:flutter/material.dart';

import '../../../data/stats/stats_repository.dart';
import '../../../data/topics/topic_catalog.dart';
import '../../../theme/app_colors.dart';
import '../settings/settings_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _TopicFilter _topicFilter = _TopicFilter.total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsRepository = StatsRepository();
    final topicLabelById = {
      for (final block in topicBlocks)
        for (final topic in block.topics) topic.topicId: topic.topicName,
    };
    final Map<String, int> topicOrderIndex = {};
    var topicIndex = 0;
    for (final block in topicBlocks) {
      for (final topic in block.topics) {
        topicOrderIndex[topic.topicId] = topicIndex;
        topicIndex++;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Estadisticas'),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            );
          }
        },
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: '',
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<StatsSummary>(
          stream: statsRepository.summaryStream(),
          builder: (context, totalSnapshot) {
            final totalStats = totalSnapshot.data ?? StatsSummary.empty();
            final isTotalLoading =
                totalSnapshot.connectionState == ConnectionState.waiting &&
                    !totalSnapshot.hasData;

            return StreamBuilder<StatsSummary>(
              stream: statsRepository.windowSummaryStream(),
              builder: (context, monthSnapshot) {
                final monthStats = monthSnapshot.data ?? StatsSummary.empty();
                final isMonthLoading =
                    monthSnapshot.connectionState == ConnectionState.waiting &&
                        !monthSnapshot.hasData;

                final topicStream = _topicFilter == _TopicFilter.total
                    ? statsRepository.topicStatsStream()
                    : statsRepository.topicStatsStream(
                        window: const Duration(days: 30),
                      );

                return StreamBuilder<List<TopicStatSummary>>(
                  stream: topicStream,
                  builder: (context, topicSnapshot) {
                    final topicStats = topicSnapshot.data ?? const [];
                    final isTopicLoading =
                        topicSnapshot.connectionState ==
                                ConnectionState.waiting &&
                            !topicSnapshot.hasData;

                    final totalCorrect = totalStats.totalCorrect;
                    final totalWrong = totalStats.totalWrong;
                    final totalAnswered = totalStats.totalAnswered;

                    final monthCorrect = monthStats.totalCorrect;
                    final monthWrong = monthStats.totalWrong;
                    final monthAnswered = monthStats.totalAnswered;

                    final topicsUi = _TopicStats.fromSummaries(
                      topicStats,
                      labels: topicLabelById,
                      orderIndex: topicOrderIndex,
                    );

                    final isLoading =
                        isTotalLoading || isMonthLoading || isTopicLoading;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionCard(
                            title: 'Acertadas vs falladas',
                            trailing: 'Total',
                            child: Column(
                              children: [
                                const SizedBox(height: 6),
                                DonutChart(
                                  correct: totalCorrect,
                                  wrong: totalWrong,
                                  size: 180,
                                ),
                                const SizedBox(height: 12),
                                _LegendRow(
                                  correctLabel: 'Acertadas',
                                  wrongLabel: 'Falladas',
                                ),
                                const SizedBox(height: 16),
                                _CountRow(
                                  label: 'Preguntas contestadas (total)',
                                  total: totalAnswered,
                                  correct: totalCorrect,
                                  wrong: totalWrong,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Acertadas vs falladas',
                            trailing: 'Ultimos 30 dias',
                            child: Column(
                              children: [
                                const SizedBox(height: 6),
                                DonutChart(
                                  correct: monthCorrect,
                                  wrong: monthWrong,
                                  size: 180,
                                ),
                                const SizedBox(height: 12),
                                _LegendRow(
                                  correctLabel: 'Acertadas',
                                  wrongLabel: 'Falladas',
                                ),
                                const SizedBox(height: 16),
                                _CountRow(
                                  label:
                                      'Preguntas contestadas (ultimos 30 dias)',
                                  total: monthAnswered,
                                  correct: monthCorrect,
                                  wrong: monthWrong,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Estadisticas por tema',
                            trailing: 'Acertadas/falladas',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _TopicFilterTabs(
                                  value: _topicFilter,
                                  onChanged: (value) {
                                    if (value == _topicFilter) return;
                                    setState(() => _topicFilter = value);
                                  },
                                ),
                                const SizedBox(height: 12),
                                if (topicsUi.isEmpty)
                                  Text(
                                    'Aun no hay datos por tema.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  )
                                else
                                  ...topicsUi.map(
                                    (item) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _TopicStatCard(
                                        theme: theme,
                                        item: item,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isLoading) ...[
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(minHeight: 6),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.trailing,
    required this.child,
  });

  final String title;
  final String trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                trailing,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

enum _TopicFilter { total, last30 }

class _TopicFilterTabs extends StatelessWidget {
  const _TopicFilterTabs({
    required this.value,
    required this.onChanged,
  });

  final _TopicFilter value;
  final ValueChanged<_TopicFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTotal = value == _TopicFilter.total;
    final isLast30 = value == _TopicFilter.last30;

    return Row(
      children: [
        Expanded(
          child: _FilterButton(
            label: 'Total',
            isSelected: isTotal,
            onTap: () => onChanged(_TopicFilter.total),
            theme: theme,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FilterButton(
            label: 'Ultimos 30 dias',
            isSelected: isLast30,
            onTap: () => onChanged(_TopicFilter.last30),
            theme: theme,
          ),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.18) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.correct,
    required this.wrong,
    this.size = 180,
  });

  final int correct;
  final int wrong;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          correct: correct,
          wrong: wrong,
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.correct, required this.wrong});

  final int correct;
  final int wrong;

  @override
  void paint(Canvas canvas, Size size) {
    final total = max(1, correct + wrong);
    final strokeWidth = size.width * 0.18;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.width - strokeWidth) / 2;

    final basePaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, basePaint);

    double startAngle = -pi / 2;
    final correctSweep = (correct / total) * 2 * pi;
    final wrongSweep = (wrong / total) * 2 * pi;

    final correctPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    final wrongPaint = Paint()
      ..color = AppColors.error
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      correctSweep,
      false,
      correctPaint,
    );
    startAngle += correctSweep;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      wrongSweep,
      false,
      wrongPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.correct != correct || oldDelegate.wrong != wrong;
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.correctLabel,
    required this.wrongLabel,
  });

  final String correctLabel;
  final String wrongLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: AppColors.success,
          label: correctLabel,
        ),
        const SizedBox(width: 12),
        _LegendItem(
          color: AppColors.error,
          label: wrongLabel,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.label,
    required this.total,
    required this.correct,
    required this.wrong,
  });

  final String label;
  final int total;
  final int correct;
  final int wrong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSafe = max(1, correct + wrong);
    final correctPct = (correct / totalSafe * 100).round();
    final wrongPct = (wrong / totalSafe * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          total.toString(),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                label: 'Acertadas',
                value: correct,
                percent: correctPct,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStatCard(
                label: 'Falladas',
                value: wrong,
                percent: wrongPct,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  final String label;
  final int value;
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                '$percent%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value.toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  label == 'Acertadas' ? 'OK' : 'KO',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicStats {
  const _TopicStats({
    required this.topicId,
    required this.title,
    required this.correct,
    required this.wrong,
  });

  final String topicId;
  final String title;
  final int correct;
  final int wrong;

  int get total => correct + wrong;
  int get percent => total == 0 ? 0 : ((correct / total) * 100).round();

  static List<_TopicStats> fromSummaries(
    List<TopicStatSummary> summaries, {
    required Map<String, String> labels,
    required Map<String, int> orderIndex,
  }) {
    final items = summaries
        .map(
          (item) => _TopicStats(
            topicId: item.topicId,
            title: labels[item.topicId] ?? item.topicId,
            correct: item.correct,
            wrong: item.wrong,
          ),
        )
        .toList();

    items.sort((a, b) {
      final indexA = orderIndex[a.topicId] ?? 9999;
      final indexB = orderIndex[b.topicId] ?? 9999;
      return indexA.compareTo(indexB);
    });

    return items;
  }
}

class _TopicStatCard extends StatelessWidget {
  const _TopicStatCard({
    required this.theme,
    required this.item,
  });

  final ThemeData theme;
  final _TopicStats item;

  @override
  Widget build(BuildContext context) {
    final total = max(1, item.total);
    final correctFraction = item.correct / total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.total} preguntas · ${item.percent}% acierto',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _Pill(
                    label: '${item.correct} OK',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _Pill(
                    label: '${item.wrong} KO',
                    color: AppColors.error,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: correctFraction,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DotLabel(
                color: AppColors.success,
                label: 'Acertadas',
              ),
              _DotLabel(
                color: AppColors.error,
                label: 'Falladas',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DotLabel extends StatelessWidget {
  const _DotLabel({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
