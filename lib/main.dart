import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme/app_theme.dart';
import 'data/seed/question_seed_loader.dart';
import 'ui/screens/login/login_screen.dart';

Future<void> main() async {
  // Necesario para poder usar Firebase, assets y SQLite antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  // Cargar preguntas de temas desde JSON a SQLite (solo si no existen)
  await QuestionSeedLoader.seedFromJsonAsset('assets/data/questions_g1.json');
  await QuestionSeedLoader.seedFromJsonAsset('assets/data/questions_g2.json');
  await QuestionSeedLoader.seedFromJsonAsset('assets/data/questions_g3.json');
  await QuestionSeedLoader.seedFromJsonAsset('assets/data/questions_g4.json');
  await QuestionSeedLoader.seedFromJsonAsset('assets/data/questions_s1.json');

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
      home: const LoginScreen(), // luego aquí pondremos AuthGate
    );
  }
}
