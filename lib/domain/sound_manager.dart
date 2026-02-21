import 'package:audioplayers/audioplayers.dart';

enum SfxType {
  attackHit,
  criticalHit,
  magicCast,
  heal,
  miss,
  enemyDeath,
  heroDeath,
  defend,
  victory,
  defeat,
  uiTap,
}

enum BgmType { title, battle }

class SoundManager {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  double _volume = 0.7;
  bool _muted = false;
  BgmType? _currentBgm;

  double get volume => _volume;
  bool get muted => _muted;

  static const _sfxPaths = {
    SfxType.attackHit: 'audio/sfx/attack_hit.wav',
    SfxType.criticalHit: 'audio/sfx/critical_hit.wav',
    SfxType.magicCast: 'audio/sfx/magic_cast.wav',
    SfxType.heal: 'audio/sfx/heal.wav',
    SfxType.miss: 'audio/sfx/miss.wav',
    SfxType.enemyDeath: 'audio/sfx/enemy_death.wav',
    SfxType.heroDeath: 'audio/sfx/hero_death.wav',
    SfxType.defend: 'audio/sfx/defend.wav',
    SfxType.victory: 'audio/sfx/victory.wav',
    SfxType.defeat: 'audio/sfx/defeat.wav',
    SfxType.uiTap: 'audio/sfx/ui_tap.wav',
  };

  static const _bgmPaths = {
    BgmType.title: 'audio/bgm/title.wav',
    BgmType.battle: 'audio/bgm/battle.wav',
  };

  Future<void> playSfx(SfxType type) async {
    if (_muted) return;
    final path = _sfxPaths[type];
    if (path == null) return;
    try {
      await _sfxPlayer.setVolume(_volume);
      await _sfxPlayer.play(AssetSource(path));
    } catch (_) {
      // Gracefully ignore missing audio files
    }
  }

  Future<void> playBgm(BgmType type) async {
    if (_currentBgm == type) return;
    _currentBgm = type;
    final path = _bgmPaths[type];
    if (path == null) return;
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_muted ? 0 : _volume * 0.5);
      await _bgmPlayer.play(AssetSource(path));
    } catch (_) {
      // Gracefully ignore missing audio files
    }
  }

  Future<void> stopBgm() async {
    _currentBgm = null;
    try {
      await _bgmPlayer.stop();
    } catch (_) {}
  }

  void setVolume(double v) {
    _volume = v.clamp(0, 1);
    if (!_muted) {
      _bgmPlayer.setVolume(_volume * 0.5);
    }
  }

  void toggleMute() {
    _muted = !_muted;
    _bgmPlayer.setVolume(_muted ? 0 : _volume * 0.5);
  }

  void setMuted(bool value) {
    _muted = value;
    _bgmPlayer.setVolume(_muted ? 0 : _volume * 0.5);
  }

  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
