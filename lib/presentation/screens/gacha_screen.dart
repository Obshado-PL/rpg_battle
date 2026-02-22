import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/character.dart';
import '../../data/models/hero_template.dart';
import '../../domain/gacha_system.dart';
import '../providers/game_providers.dart';
import '../widgets/common/animated_hero_sprite.dart';

class GachaScreen extends ConsumerStatefulWidget {
  const GachaScreen({super.key});

  @override
  ConsumerState<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends ConsumerState<GachaScreen>
    with SingleTickerProviderStateMixin {
  final GachaSystem _gacha = GachaSystem();
  List<GachaResult>? _results;
  int _revealIndex = 0;
  bool _isRevealing = false;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _singlePull() {
    final gold = ref.read(goldProvider);
    if (gold < GachaSystem.pullCost) return;

    final gameData = ref.read(gameDataProvider);
    final ownedIds = ref.read(ownedHeroIdsProvider);

    ref.read(goldProvider.notifier).state -= GachaSystem.pullCost;

    final result = _gacha.pull(
      heroTemplates: gameData.heroTemplates,
      ownedHeroIds: ownedIds,
    );

    _processResult(result);
    setState(() {
      _results = [result];
      _revealIndex = 0;
    });
  }

  void _multiPull() {
    final gold = ref.read(goldProvider);
    if (gold < GachaSystem.multiPullCost) return;

    final gameData = ref.read(gameDataProvider);
    final ownedIds = ref.read(ownedHeroIdsProvider);

    ref.read(goldProvider.notifier).state -= GachaSystem.multiPullCost;

    final results = <GachaResult>[];
    // Track IDs as we pull to correctly detect duplicates within the multi-pull
    final currentOwned = {...ownedIds};
    for (var i = 0; i < 10; i++) {
      final result = _gacha.pull(
        heroTemplates: gameData.heroTemplates,
        ownedHeroIds: currentOwned,
      );
      results.add(result);
      if (!result.isDuplicate) {
        currentOwned.add(result.hero.id);
      }
      _processResult(result);
    }

    setState(() {
      _results = results;
      _revealIndex = 0;
      _isRevealing = true;
    });
    _revealNext();
  }

  void _processResult(GachaResult result) {
    if (result.isDuplicate) {
      // Give compensation gold
      ref.read(goldProvider.notifier).state += result.compensationGold;
    } else {
      // Add hero to owned set and create character on roster
      ref.read(ownedHeroIdsProvider.notifier).add(result.hero.id);
      final gameData = ref.read(gameDataProvider);
      final character = gameData.createCharacterFromTemplate(result.hero.id);
      ref.read(rosterProvider.notifier).addHero(character);
    }
    collectAndSave(ref);
  }

  void _revealNext() async {
    if (_results == null) return;
    for (var i = 0; i < _results!.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _revealIndex = i);
    }
    setState(() => _isRevealing = false);
  }

  @override
  Widget build(BuildContext context) {
    final gold = ref.watch(goldProvider);
    final canSingle = gold >= GachaSystem.pullCost;
    final canMulti = gold >= GachaSystem.multiPullCost;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SUMMON',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.amber,
                              ),
                    ),
                    const Spacer(),
                    const Icon(Icons.monetization_on,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '$gold',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.amber,
                          ),
                    ),
                  ],
                ),
              ),

              // Reveal area
              Expanded(
                child: _results != null
                    ? _buildRevealArea()
                    : _buildSummonPrompt(),
              ),

              // Pull buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            canSingle && !_isRevealing ? _singlePull : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canSingle
                              ? Colors.amber.withValues(alpha: 0.2)
                              : Colors.grey[900],
                          foregroundColor:
                              canSingle ? Colors.amber : Colors.grey,
                          side: BorderSide(
                            color: canSingle
                                ? Colors.amber.withValues(alpha: 0.5)
                                : Colors.grey[800]!,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Column(
                          children: [
                            const Text('Single Pull',
                                style: TextStyle(fontSize: 13)),
                            Text('${GachaSystem.pullCost}g',
                                style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            canMulti && !_isRevealing ? _multiPull : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canMulti
                              ? Colors.deepPurple.withValues(alpha: 0.3)
                              : Colors.grey[900],
                          foregroundColor:
                              canMulti ? Colors.purpleAccent : Colors.grey,
                          side: BorderSide(
                            color: canMulti
                                ? Colors.purpleAccent.withValues(alpha: 0.5)
                                : Colors.grey[800]!,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Column(
                          children: [
                            const Text('10x Pull',
                                style: TextStyle(fontSize: 13)),
                            Text('${GachaSystem.multiPullCost}g',
                                style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummonPrompt() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.amber
                        .withValues(alpha: _glowAnimation.value * 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber
                          .withValues(alpha: _glowAnimation.value * 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: Colors.amber
                      .withValues(alpha: 0.4 + _glowAnimation.value * 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Summon a Hero',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white54,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '60% Common / 30% Rare / 10% Epic',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white24,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRevealArea() {
    if (_results == null) return const SizedBox.shrink();

    // Single pull: show large reveal
    if (_results!.length == 1) {
      return _buildSingleReveal(_results!.first);
    }

    // Multi pull: show grid
    return _buildMultiReveal();
  }

  Widget _buildSingleReveal(GachaResult result) {
    final rarityColor = _rarityColor(result.hero.rarity);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rarity glow
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: rarityColor.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: AnimatedHeroSprite(
              spriteId: result.hero.spriteId,
              animation: SpriteAnimation.idle,
              size: 96,
            ),
          ),
          const SizedBox(height: 16),
          // Hero info
          Text(
            result.hero.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _rarityBadge(result.hero.rarity),
              const SizedBox(width: 8),
              Text(
                result.hero.heroClass.name.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _classColor(result.hero.heroClass),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (result.isDuplicate)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Duplicate! +${result.compensationGold}g',
                style: const TextStyle(color: Colors.amber, fontSize: 13),
              ),
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'NEW!',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMultiReveal() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.65,
      ),
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        if (index > _revealIndex) {
          // Not yet revealed
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Center(
              child: Icon(Icons.help_outline, color: Colors.white12, size: 24),
            ),
          );
        }

        final result = _results![index];
        final rarityColor = _rarityColor(result.hero.rarity);

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: rarityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: rarityColor.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedHeroSprite(
                spriteId: result.hero.spriteId,
                animation: SpriteAnimation.idle,
                size: 36,
              ),
              const SizedBox(height: 2),
              Text(
                result.hero.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              if (result.isDuplicate)
                Text(
                  '+${result.compensationGold}g',
                  style: const TextStyle(color: Colors.amber, fontSize: 7),
                )
              else
                const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _rarityBadge(HeroRarity rarity) {
    final (label, color) = switch (rarity) {
      HeroRarity.common => ('Common', Colors.white54),
      HeroRarity.rare => ('Rare', Colors.blue),
      HeroRarity.epic => ('Epic', Colors.amber),
      HeroRarity.legendary => ('Legendary', Colors.redAccent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _rarityColor(HeroRarity rarity) {
    return switch (rarity) {
      HeroRarity.common => Colors.white54,
      HeroRarity.rare => Colors.blue,
      HeroRarity.epic => Colors.amber,
      HeroRarity.legendary => Colors.redAccent,
    };
  }

  Color _classColor(HeroClass heroClass) {
    return switch (heroClass) {
      HeroClass.warrior => Colors.orange,
      HeroClass.mage => Colors.purple,
      HeroClass.healer => Colors.green,
      HeroClass.rogue => Colors.amber,
    };
  }
}
