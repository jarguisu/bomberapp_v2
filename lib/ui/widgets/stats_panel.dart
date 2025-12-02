import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class StatsPanel extends StatelessWidget {
  final int questionsAnswered;
  final int questionsCorrect;
  final int questionsWrong;

  const StatsPanel({
    super.key,
    required this.questionsAnswered,
    required this.questionsCorrect,
    required this.questionsWrong,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget statItem(String label, String value, {Color? valueColor}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

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
          Text('Últimos 7 días', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Column(
            children: [
              statItem('Preguntas contestadas', '$questionsAnswered'),
              const SizedBox(height: 8),
              statItem(
                'Acertadas',
                '$questionsCorrect',
                valueColor: AppColors.success,
              ),
              const SizedBox(height: 8),
              statItem(
                'Falladas',
                '$questionsWrong',
                valueColor: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
