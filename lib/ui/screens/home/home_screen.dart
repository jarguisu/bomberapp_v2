import 'package:flutter/material.dart';

import '../../../data/stats/stats_repository.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/kpi_panel.dart';
import '../../widgets/stats_panel.dart';
import '../../widgets/mode_card.dart';
import '../../widgets/app_footer.dart';
import '../topic_test/topic_test_config_screen.dart';
import '../custom_test/custom_test_config_screen.dart';
import '../simulacro/simulacro_config_screen.dart';
import '../failed_questions/failed_questions_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showComingSoon(BuildContext context, String modeName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$modeName aun no esta implementado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsRepository = StatsRepository();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 0,
        title: const AppHeader(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const StatsScreen(),
              ),
            );
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
          builder: (context, snapshot) {
            final stats = snapshot.data ?? StatsSummary.empty();
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HeroCard(),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KpiPanel(totalTests: stats.totalAttempts, label: 'en total'),
                      const SizedBox(height: 12),
                      StatsPanel(
                        questionsAnswered: stats.totalAnswered,
                        questionsCorrect: stats.totalCorrect,
                        questionsWrong: stats.totalWrong,
                      ),
                      if (isLoading) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(minHeight: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Modos de test', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ModeCard(
                    title: 'Test por tema',
                    description:
                        'Elige un tema concreto y practica preguntas especificas.',
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
                        'Selecciona libremente los temas y define cuantas preguntas quieres.',
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
                        '100 preguntas | 120 min | -0,33 por fallo | Distribucion proporcional.',
                    buttonLabel: 'Iniciar simulacro',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SimulacroConfigScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
              ModeCard(
                title: 'Preguntas falladas',
                description:
                    'Revisa tus errores acumulados y vuelve a intentarlo para mejorar tu puntuacion.',
                buttonLabel: 'Ver preguntas falladas',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FailedQuestionsScreen(),
                    ),
                  );
                },
              ),
                  const SizedBox(height: 16),
                  const AppFooter(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
