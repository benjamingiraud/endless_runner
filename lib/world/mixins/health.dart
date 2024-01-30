import 'dart:math';

import 'package:endless_runner/world/components/bullet.dart';
import 'package:endless_runner/world/components/health_bar.dart';
import 'package:endless_runner/world/components/zombie.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

mixin Health on Component {
  late double _maxHealth;
  late double _maxShield;
  late ValueNotifier<double> _health;
  late ValueNotifier<double> _shield;
  late HealthBar healthBar;

  void initializeHealthMixin(double maxHealth, double maxShield,
      {double? currentHealth}) {
    _maxHealth = maxHealth;
    _maxShield = maxShield;
    _health = ValueNotifier(currentHealth ?? maxHealth);
    _shield = ValueNotifier(_maxShield);
    healthBar = HealthBar(maxHealth, _health.value);
    add(healthBar);

    _health.addListener(() {
      healthBar.updateHealth(_health.value);
      if (_health.value <= 0) {
        removeFromParent();
      }
    });
  }

  double get maxHealth => _maxHealth;
  double get health => _health.value;

  double get maxShield => _maxShield;
  double get shield => _shield.value;

  ValueNotifier<double> get healthNotifier => _health;
  ValueNotifier<double> get shieldNotifier => _shield;

  void damage(double amount, {PositionComponent? damager}) {
    // if current entity has paint, color overlay sprite in red
    if (this is HasPaint) {
      final effect = ColorEffect(
        Colors.red,
        EffectController(
          duration: 0.5,
          alternate: true,
        ),
        opacityFrom: 0,
        opacityTo: 0.32,
      );
      add(effect);
    }

    if (this is Zombie) {
      if (damager is Bullet) {
        // check if the zombie is not already rotating and then rotate it
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
              onComplete: () => {
                // add(MoveToEffect(
                //     damager.player.position, LinearEffectController(5),
                //     target: damager.player))
                (this as Zombie).target = damager.player
              },
            ),
          );
        }
        // MoveEffect.to(damager.player.position, LinearEffectController(5), );
      }
    }

    if (_shield.value > 0) {
      _shield.value = (_shield.value - amount).clamp(0.0, _maxShield);
    } else {
      _health.value = (_health.value - amount).clamp(0.0, _maxHealth);
    }
  }

  // addShield

  void heal(double amount) {
    _health.value = (_health.value + amount).clamp(0.0, _maxHealth);
  }

  void restoreShield(double amount) {
    _shield.value = (_shield.value + amount).clamp(0.0, _maxShield);
  }
}
