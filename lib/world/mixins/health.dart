import 'dart:math';

import 'package:survival_zombie/audio/sounds.dart';
import 'package:survival_zombie/world/components/bullet.dart';
import 'package:survival_zombie/world/components/damage_indicator.dart';
import 'package:survival_zombie/world/components/health_bar.dart';
import 'package:survival_zombie/world/components/player/player.dart';
import 'package:survival_zombie/world/components/zombie.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/palette.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:survival_zombie/world/game_main.dart';

mixin Health on Component {
  late double _maxHealth;
  late double _maxShield;
  late ValueNotifier<double> _health;
  late ValueNotifier<double> _shield;

  late HealthBar healthBar;
  late final GameMain _gameRef = findGame() as GameMain;

  initializeHealthMixin(double maxHealth,
      {double? currentHealth,
      double maxShield = 0,
      double currentShield = 0,
      bool showText = false,
      double barWidth = 100,
      double barHeight = 10,
      bool barCentered = true,
      bool shouldRender = true}) {
    _maxHealth = maxHealth;
    _maxShield = maxShield;
    _health = ValueNotifier(currentHealth ?? maxHealth);
    _shield = ValueNotifier(currentShield);

    _health.addListener(() {
      healthBar.updateHealth(_health.value);
      if (_health.value <= 0) {
        // for (var child in children) {
        //   child.removeFromParent();
        // }
        // add(RemoveEffect(delay: 1.0));
        if (this is Zombie) {
          add(ScaleEffect.to(Vector2(0, 0),
              EffectController(duration: 0.5, curve: Curves.easeOutSine),
              onComplete: removeFromParent));
          (this as Zombie).explode();
          if ((this as Zombie).hasTarget()) {
            // ((this as Zombie).target as Player).game.timeScale = 0.25;
          }
        } else {
          removeFromParent();
        }
      }
      if (this is Player) {
        _gameRef.audioController.playSfx(SfxType.playerDamage);
      }
    });

    _shield.addListener(() {
      healthBar.updateShield(_shield.value);
      if (_shield.value <= 0) {
        // crack shield sound ??
      }
    });

    healthBar = HealthBar(maxHealth, _health.value, maxShield, _shield.value,
        showText: showText,
        width: barWidth,
        height: barHeight,
        centered: barCentered)
      ..debugMode = true;

    if (shouldRender) {
      add(healthBar);
    }
  }

  double get maxHealth => _maxHealth;
  double get health => _health.value;

  double get maxShield => _maxShield;
  double get shield => _shield.value;

  ValueNotifier<double> get healthNotifier => _health;
  ValueNotifier<double> get shieldNotifier => _shield;

  double damage(double amount,
      {PositionComponent? damager,
      bool isCritical = false,
      Set<Vector2>? intersectionPoints}) {
    // if current entity has paint, color overlay sprite in red
    if (amount > 0) {
      if (amount > health) {
        if (health > 0) {
          amount = health;
        } else {
          return 0;
        }
      }
      if (this is HasPaint) {
        final effect = ColorEffect(
          const Color.fromARGB(255, 156, 41, 33),
          EffectController(
            duration: 0.5,
            alternate: true,
          ),
          opacityFrom: 0,
          opacityTo: 0.5,
        );
        add(effect);
      }

      _gameRef.world.add(DamageIndicator(
        "-${amount.toStringAsFixed(0)}",
        -amount,
        isCritical: isCritical,
        position: (this as PositionComponent).position,
        isPlayer: this is Player ? true : false,
      ));

      if (_shield.value > 0) {
        _shield.value = (_shield.value - amount).clamp(0.0, _maxShield);
      } else {
        _health.value = (_health.value - amount).clamp(0.0, _maxHealth);
      }
    }

    if (this is Zombie) {
      if (damager is Bullet) {
        add(
          ParticleSystemComponent(
            particle: Particle.generate(
              count: 120,
              lifespan: 1.25,
              generator: (i) => AcceleratedParticle(
                acceleration: Vector2(0, 100),
                speed: Vector2(Random().nextDouble() * 100 - 50,
                    Random().nextDouble() * 100 - 50),
                child: CircleParticle(
                  radius: 1,
                  paint: const PaletteEntry(Color.fromARGB(255, 156, 41, 33))
                      .paint(),
                ),
              ),
            ),
            anchor: Anchor.center,
            position: (this as PositionComponent).scaledSize / 2,
          ),
        );

        // check if the zombie is not already rotating and then rotate it
        if (!(this as Zombie).hasTarget()) {
          bool shouldRotate = true;
          for (var child in children) {
            if (child is RotateEffect) {
              shouldRotate = false;
            }
          }
          if (shouldRotate) {
            add(
              RotateEffect.by(
                (this as PositionComponent)
                    .angleTo(damager.player.absolutePosition),
                LinearEffectController(0.25),
                onComplete: () {
                  (this as Zombie).target.value = damager.player;
                },
              ),
            );
          }
        }
      }
    }

    return amount;
  }

  void heal(double amount) {
    if (amount > 0) {
      _health.value = (_health.value + amount).clamp(0.0, _maxHealth);
      findGame()!.world.add(DamageIndicator(
          "+${amount.toStringAsFixed(0)}", amount,
          isCritical: false, position: (this as PositionComponent).position));
    }
  }

  void restoreShield(double amount) {
    // play sound effect ?
    _shield.value = (_shield.value + amount).clamp(0.0, _maxShield);
  }
}
