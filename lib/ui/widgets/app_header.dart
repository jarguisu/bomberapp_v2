import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../screens/settings/settings_screen.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Marca
          Row(
            children: [
              // Logo tipo casco dentro de un gradiente
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
          // Acciones
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  // TODO: Navegar a estadisticas
                },
                child: const Text('Estadisticas'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                child: const Text('Ajustes'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
