import 'package:flutter/material.dart';

Future<bool?> showWelcomeTutorialDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _WelcomeTutorialDialog(),
  );
}

class _WelcomeTutorialDialog extends StatefulWidget {
  const _WelcomeTutorialDialog();

  @override
  State<_WelcomeTutorialDialog> createState() => _WelcomeTutorialDialogState();
}

class _WelcomeTutorialDialogState extends State<_WelcomeTutorialDialog> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_TutorialStep> _steps = [
    _TutorialStep(
      icon: Icons.home_rounded,
      title: 'Bienvenido a BomberAPP',
      description:
          'Practica tipo test, sigue tu progreso y prepara la oposicion con una rutina clara.',
    ),
    _TutorialStep(
      icon: Icons.menu_book_rounded,
      title: 'Test por tema',
      description:
          'Entrena un tema concreto para reforzar puntos debiles con preguntas especificas.',
    ),
    _TutorialStep(
      icon: Icons.tune_rounded,
      title: 'Test personalizado',
      description:
          'Combina temas y numero de preguntas para crear sesiones a tu medida.',
    ),
    _TutorialStep(
      icon: Icons.fact_check_rounded,
      title: 'Simulacro oficial',
      description:
          'Haz un examen completo en condiciones reales para medir tu nivel actual.',
    ),
    _TutorialStep(
      icon: Icons.bar_chart_rounded,
      title: 'Estadisticas completas',
      description:
          'Consulta resultados por test, rendimiento por tema, aciertos, fallos y evolucion para saber donde mejorar.',
    ),
    _TutorialStep(
      icon: Icons.replay_rounded,
      title: 'Preguntas falladas y estadisticas',
      description:
          'Repasa tus errores acumulados y vuelve a practicar justo lo que mas te cuesta.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index >= _steps.length - 1) {
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _back() async {
    if (_index <= 0) return;
    await _controller.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Guia inicial',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _steps.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (_, i) {
                    final current = _steps[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(current.icon, size: 48),
                          const SizedBox(height: 14),
                          Text(
                            current.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            current.description,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  TextButton(
                    onPressed: _index > 0 ? _back : null,
                    child: const Text('Atras'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(
                      _index == _steps.length - 1 ? 'Empezar' : 'Siguiente',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialStep {
  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
