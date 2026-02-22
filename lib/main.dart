import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/game_data.dart';
import 'data/datasources/save_manager.dart';
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

  // Load save manager
  final prefs = await SharedPreferences.getInstance();
  final saveManager = SaveManager(prefs);
  final savedData = saveManager.load();

  runApp(
    ProviderScope(
      overrides: [
        gameDataProvider.overrideWithValue(gameData),
        saveManagerProvider.overrideWithValue(saveManager),
        // Restore saved state if available
        if (savedData != null) ...[
          partyProvider.overrideWith(
            (ref) => PartyNotifier(savedData.party,
                equipmentData: gameData.equipment),
          ),
          rosterProvider.overrideWith(
            (ref) => RosterNotifier.fromList(savedData.roster),
          ),
          ownedHeroIdsProvider.overrideWith(
            (ref) => OwnedHeroIdsNotifier.fromSet(
              savedData.ownedHeroIds.isNotEmpty
                  ? savedData.ownedHeroIds
                  : savedData.party.map((c) => c.id).toSet(),
            ),
          ),
          inventoryProvider.overrideWith(
            (ref) => InventoryNotifier.fromList(savedData.inventory),
          ),
          goldProvider.overrideWith(
            (ref) => savedData.gold,
          ),
          clearedEncountersProvider.overrideWith(
            (ref) => savedData.clearedEncounters,
          ),
          ownedEquipmentProvider.overrideWith(
            (ref) =>
                OwnedEquipmentNotifier.fromSet(savedData.ownedEquipment),
          ),
          difficultyProvider.overrideWith(
            (ref) => savedData.difficulty,
          ),
          bestiaryProvider.overrideWith(
            (ref) =>
                BestiaryNotifier.fromMap(savedData.bestiaryDefeats),
          ),
          skillTreeChoicesProvider.overrideWith(
            (ref) =>
                SkillTreeChoicesNotifier.fromMap(savedData.skillTreeChoices),
          ),
        ],
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
