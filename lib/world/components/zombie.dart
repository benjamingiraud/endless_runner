import 'dart:math';

import 'package:endless_runner/world/components/bullet.dart';
import 'package:endless_runner/world/mixins/health.dart';
import 'package:flame/cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

class Zombie extends SpriteAnimationGroupComponent<ZombieState>
    with HasGameRef, CollisionCallbacks, HasWorldReference<World>, Health {
  Zombie({super.position}) : super(anchor: Anchor.center) {
    double currentHealth = Random().nextDouble() * 100 + 50;
    initializeHealthMixin(100, 0, currentHealth: currentHealth);
  }

  @override
  Future<void> onLoad() async {
    animations = {
      ZombieState.idle: await game.loadSpriteAnimation(
        'enemies/zombie_idle.png',
        SpriteAnimationData.sequenced(
          amount: 17,
          textureSize: Vector2(121, 111),
          stepTime: 0.1,
        ),
      ),
    };
    current = ZombieState.idle;

    add(CircleHitbox()..renderShape = false);
  }

  @override
  void update(double dt) {
    super.update(dt);
  }
}

enum ZombieState { idle }
