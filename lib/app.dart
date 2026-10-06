import 'package:flutter/material.dart';

import 'core/theme/kito_theme.dart';
import 'features/home/presentation/home_page.dart';

class KitoApp extends StatelessWidget {
  const KitoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kito',
      debugShowCheckedModeBanner: false,
      theme: KitoTheme.light,
      home: const HomePage(),
    );
  }
}
