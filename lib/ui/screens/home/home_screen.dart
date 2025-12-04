import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/kpi_panel.dart';
import '../../widgets/stats_panel.dart';
import '../../widgets/mode_card.dart';
import '../../widgets/app_footer.dart';
import '../topic_test/topic_test_config_screen.dart';
import '../custom_test/custom_test_config_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showComingSoon(BuildContext context, String modeName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$modeName aún no está implementado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 0,
        title: const AppHeader(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HeroCard(),
              const SizedBox(height: 16),
              // Aside con KPI y estadísticas
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  KpiPanel(totalTests: 12, label: 'en total'),
                  SizedBox(height: 12),
                  StatsPanel(
                    questionsAnswered: 320,
                    questionsCorrect: 228,
                    questionsWrong: 92,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Modos de test', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              // Cards de modos
              ModeCard(
                title: 'Test por tema',
                description:
                    'Elige un tema concreto y practica preguntas específicas.',
                buttonLabel: 'Empezar',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TopicTestConfigScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
              ModeCard(
                title: 'Test personalizado',
                description:
                    'Selecciona libremente los temas y define cuántas preguntas quieres.',
                buttonLabel: 'Configurar',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CustomTestConfigScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              ModeCard(
                title: 'Simulacro oficial',
                description:
                    '100 preguntas · 120 min · −0,33 por fallo · Distribución proporcional.',
                buttonLabel: 'Iniciar simulacro',
                onPressed: () => _showComingSoon(context, 'Simulacro oficial'),
              ),
              const SizedBox(height: 12),
              ModeCard(
                title: 'Preguntas falladas',
                description:
                    'Revisa tus errores acumulados y vuelve a intentarlo para mejorar tu puntuación.',
                buttonLabel: 'Ver preguntas falladas',
                onPressed: () => _showComingSoon(context, 'Preguntas falladas'),
              ),
              const SizedBox(height: 16),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
