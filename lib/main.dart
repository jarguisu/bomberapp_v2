import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home/home_screen.dart';
import 'data/seed/question_seed_loader.dart';

Future<void> main() async {
  // Necesario para poder cargar assets y usar SQLite antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar preguntas de temas desde JSON a SQLite (solo si no existen)
  await QuestionSeedLoader.seedFromJsonAsset(
    'assets/data/questions_g1.json',
  );
  await QuestionSeedLoader.seedFromJsonAsset(
    'assets/data/questions_g2.json',
  );

  runApp(const BomberApp());
}

class BomberApp extends StatelessWidget {
  const BomberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BomberAPP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
