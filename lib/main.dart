import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home/home_screen.dart';

void main() {
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
