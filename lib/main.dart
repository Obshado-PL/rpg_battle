import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/game_data.dart';
import 'presentation/providers/game_providers.dart';
import 'presentation/screens/title_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for mobile RPG experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Load game data
  final gameData = GameData();
  await gameData.load();

  runApp(
    ProviderScope(
      overrides: [
        gameDataProvider.overrideWithValue(gameData),
      ],
      child: const RpgBattleApp(),
    ),
  );
}

class RpgBattleApp extends StatelessWidget {
  const RpgBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPG Battle',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const TitleScreen(),
    );
  }
}
