import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/save_data.dart';

class SaveManager {
  static const _saveKey = 'rpg_battle_save';

  final SharedPreferences _prefs;

  SaveManager(this._prefs);

  Future<void> save(SaveData data) async {
    final jsonStr = json.encode(data.toJson());
    await _prefs.setString(_saveKey, jsonStr);
  }

  SaveData? load() {
    final jsonStr = _prefs.getString(_saveKey);
    if (jsonStr == null) return null;
    try {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return SaveData.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteSave() async {
    await _prefs.remove(_saveKey);
  }

  bool get hasSave => _prefs.containsKey(_saveKey);
}
