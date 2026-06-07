import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class ProSubscriptionsScreen extends StatefulWidget {
  const ProSubscriptionsScreen({super.key});

  @override
  State<ProSubscriptionsScreen> createState() => _ProSubscriptionsScreenState();
}

class _ProSubscriptionsScreenState extends State<ProSubscriptionsScreen> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Suscripciones PRO'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionCard(
                title: 'Ventajas PRO',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _BenefitRow(text: 'Estadisticas completas'),
                    _BenefitRow(text: 'Test por tema sin limite'),
                    _BenefitRow(text: 'Test personalizados sin limite'),
                    _BenefitRow(text: 'Simulacros oficiales sin limite'),
                    _BenefitRow(
                      text:
                          'Newsletter con las ultimas noticias sobre oposiciones',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Planes de suscripcion',
                child: Column(
                  children: [
                    _PlanGrid(
                      selectedIndex: _selectedIndex,
                      onChanged: (index) {
                        if (index == _selectedIndex) return;
                        setState(() => _selectedIndex = index);
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Probar gratis + Suscripcion'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
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
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.primary),
            ),
            child: const Icon(Icons.check, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanGrid extends StatelessWidget {
  const _PlanGrid({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const plans = [
      _PlanOption(
        label: '1 mes',
        pricePerMonth: '7,99 €/mes',
        note: '(7d gratis, despues 7,99 €)',
      ),
      _PlanOption(
        label: '3 meses',
        pricePerMonth: '6,99 €/mes',
        note: '(7d gratis, despues 20,99 €)',
      ),
      _PlanOption(
        label: '6 meses',
        pricePerMonth: '5,99 €/mes',
        note: '(7d gratis, despues 35,99 €)',
      ),
    ];

    return Column(
      children: List.generate(plans.length, (index) {
        final plan = plans[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == plans.length - 1 ? 0 : 12,
          ),
          child: _PlanCard(
            plan: plan,
            isSelected: index == selectedIndex,
            onTap: () => onChanged(index),
          ),
        );
      }),
    );
  }
}

class _PlanOption {
  final String label;
  final String pricePerMonth;
  final String note;

  const _PlanOption({
    required this.label,
    required this.pricePerMonth,
    required this.note,
  });
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  final _PlanOption plan;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _PlanRadio(isSelected: isSelected),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan.pricePerMonth,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              plan.note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRadio extends StatelessWidget {
  const _PlanRadio({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
        color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : null,
      ),
      child: isSelected
          ? Icon(Icons.check, color: AppColors.primary, size: 14)
          : null,
    );
  }
}
