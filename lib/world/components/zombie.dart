import 'dart:math';

import 'package:endless_runner/world/components/critical_hitbox.dart';
import 'package:endless_runner/world/components/player/player.dart';
import 'package:endless_runner/world/mixins/health.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

class Zombie extends SpriteAnimationGroupComponent<ZombieState>
    with HasGameRef, CollisionCallbacks, HasWorldReference<World>, Health {
  Zombie({super.position, double? currentHealth, double? maxHealth,})
      : super(anchor: Anchor.center, nativeAngle: pi / 2, scale: Vector2.all(0.75)) {
    initializeHealthMixin(maxHealth ?? 100.0,
        currentHealth: currentHealth ?? Random().nextDouble() * 100 + 50);
  }

  // @override
  // bool debugMode = true;

  double attackInterval = 1; // Intervalle d'attack en secondes
  Timer? attackTimer;
  double attackDamage = 20.0;
  bool hasAttacked = false;

  bool hasTarget() => target != null ? true : false;
  PositionComponent? target;
  late final SequenceEffect idlePattern;

  late final CircleHitbox detectionHitbox;

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
      ZombieState.run: await game.loadSpriteAnimation(
        'enemies/zombie_move.png',
        SpriteAnimationData.sequenced(
          amount: 17,
          textureSize: Vector2(144, 156),
          stepTime: 0.07,
        ),
      ),
      ZombieState.attack: await game.loadSpriteAnimation(
        'enemies/zombie_attack.png',
        SpriteAnimationData.sequenced(
          amount: 9,
          textureSize: Vector2(159, 147),
          stepTime: attackInterval / 9,
        ),
      ),
    };
    current = ZombieState.run;

    add(CircleHitbox(
      radius: size.x / 3,
      position: size / 6,
    ));
    add(CriticalHitbox(
      1.5,
      size: Vector2(size.x / 3 + size.x / 8, size.y / 6),
      position: Vector2(size.x / 2, (size.y / 3 + size.y / 9)),
      priority: 2,
    ));

    detectionHitbox = CircleHitbox(
        radius: size.x * 1.25,
        position: Vector2(size.x * 1.5 / 2, -(size.y * 1.5 / 2)))
      ..triggersParentCollision = false;
    add(detectionHitbox);

    idlePattern = SequenceEffect(
      [
        // Avance de 150
        MoveEffect.by(
          Vector2(150, 0),
          EffectController(
            duration: 5,
            curve: Curves.linear,
          ),
        ),
        // Se retourne
        RotateEffect.by(-180 * (pi / 180), EffectController(duration: 0.5)),
        // Recule de 150
        MoveEffect.by(
          Vector2(-150, 0),
          EffectController(duration: 5, curve: Curves.linear),
        ),
        RotateEffect.by(-180 * (pi / 180), EffectController(duration: 0.5)),
      ],
      infinite: true,
    );
    add(idlePattern);
  }

  @override
  void update(double dt) {
    super.update(dt);
    attackTimer?.update(dt);

    if (target != null) {
      idlePattern.reset();
      idlePattern.pause();

      lookAt(target!.position);
      // Calcule le vecteur de déplacement vers la position du joueur
      final targetPosition = target!.position;
      final direction = targetPosition - position;

      // Normalise le vecteur de direction pour obtenir une unité de vecteur de déplacement
      final unitDirection = direction.normalized();

      // Multiplie le vecteur de direction unitaire par la vitesse souhaitée pour obtenir le déplacement final
      const speed = 100.0; // Réglez la vitesse selon vos besoins
      final displacement = unitDirection * speed * dt;

      // Réglez la portée d'attaque selon vos besoins
      final attackRange = target!.scaledSize.x;
      // Vérifie si le zombie est suffisamment proche du joueur pour l'attaquer
      if (direction.length <= attackRange) {
        if (target is Health && !hasAttacked) {
          current = ZombieState.attack;
          hasAttacked = true;
          attackTimer =
              Timer(attackInterval - (attackInterval / 7), onTick: () {
            final attackDamageComputed =
                (target as Health).shield > 0 ? attackDamage / 2 : attackDamage;
            final double damageDealt =
                (target as Health).damage(attackDamageComputed);
            heal(damageDealt / 2);
            hasAttacked = false;
          });
        }
        // Sinon si le zombie est assez proche du joueur il le suit
      } else if (direction.length <= detectionHitbox.size.x * 2) {
        // Déplace le zombie selon le vecteur de déplacement calculé
        hasAttacked = false;
        position += displacement;
        current = ZombieState.run;
        attackTimer?.stop();
        // Sinon le joueur a reussi a semer le zombie
      } else {
        hasAttacked = false;
        current = ZombieState.idle;
        target = null;
      }
    } else {
      if (attackTimer != null) {
        attackTimer?.stop();
      }
      if (idlePattern.isPaused) {
        idlePattern.resume();
        current = ZombieState.run;
        // RotateEffect.to(0 * (pi / 180), EffectController(duration: 0.5), onComplete: () {});
      }
      if (detectionHitbox.isColliding) {
        for (var collision in detectionHitbox.activeCollisions) {
          if (collision.parent is Player) {
            target = collision.parent as Player;
          }
          if (collision.parent is Zombie &&
              (collision.parent as Zombie).target != null) {
            // timeout de 0.5 pour set la target
            Timer(1.5, onTick: () {
              target = (collision.parent as Zombie).target;
            });
          }
        }
      }
    }
  }
}

enum ZombieState { idle, attack, run }
