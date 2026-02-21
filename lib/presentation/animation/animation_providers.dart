import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'battle_animation_controller.dart';

final battleAnimationControllerProvider =
    ChangeNotifierProvider.autoDispose<BattleAnimationController>((ref) {
  return BattleAnimationController();
});
