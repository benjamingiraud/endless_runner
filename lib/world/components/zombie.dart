import 'dart:math';
import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/geometry.dart';
import 'package:flame/palette.dart';
import 'package:flame/particles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:survival_zombie/audio/sounds.dart';
import 'package:survival_zombie/world/components/critical_hitbox.dart';
import 'package:survival_zombie/world/components/health_bar.dart';
import 'package:survival_zombie/world/components/player/player.dart';
import 'package:survival_zombie/world/game_main.dart';
import 'package:survival_zombie/world/mixins/health.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

class Zombie extends SpriteAnimationGroupComponent<ZombieState>
    with
        CollisionCallbacks,
        HasWorldReference<World>,
        HasGameReference<GameMain>,
        Health {
  Zombie({
    super.position,
    double? currentHealth,
    double? maxHealth,
  }) : super(
            anchor: Anchor.center,
            nativeAngle: pi / 2,
            priority: 1,
            scale: Vector2.all(0.75)) {
    initializeHealthMixin(maxHealth ?? 100.0,
        currentHealth: currentHealth ?? Random().nextDouble() * 100 + 50);
  }

  // @override
  // bool debugMode = true;

  double attackInterval = 1; // Intervalle d'attack en secondes
  Timer? attackTimer;
  double attackDamage = 20.0;
  bool hasAttacked = false;

  bool hasTarget() => target.value != null;
  final ValueNotifier<PositionComponent?> target = ValueNotifier(null);

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
      position: Vector2(size.x / 3 + size.x / 8, (size.y / 3 + size.y / 9)),
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

    target.addListener(() {
      game.audioController.playSfx(SfxType.zombieHasTarget);
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    attackTimer?.update(dt);

    if (hasTarget()) {
      idlePattern.reset();
      idlePattern.pause();

      lookAt(target.value!.position);
      // Calcule le vecteur de déplacement vers la position du joueur
      final targetPosition = target.value!.position;
      final direction = targetPosition - position;

      // Normalise le vecteur de direction pour obtenir une unité de vecteur de déplacement
      final unitDirection = direction.normalized();

      // Multiplie le vecteur de direction unitaire par la vitesse souhaitée pour obtenir le déplacement final
      const speed = 100.0; // Réglez la vitesse selon vos besoins
      final displacement = unitDirection * speed * dt;

      // Réglez la portée d'attaque selon vos besoins
      final attackRange = target.value!.scaledSize.x;
      // Vérifie si le zombie est suffisamment proche du joueur pour l'attaquer
      if (direction.length <= attackRange) {
        if (target.value is Health && !hasAttacked) {
          current = ZombieState.attack;
          hasAttacked = true;
          attackTimer =
              Timer(attackInterval - (attackInterval / 7), onTick: () {
            final attackDamageComputed = (target.value as Health).shield > 0
                ? attackDamage / 2
                : attackDamage;
            final double damageDealt =
                (target.value as Health).damage(attackDamageComputed);
            heal(damageDealt / 2);
            hasAttacked = false;
          });
        }
        // Sinon si le zombie est assez proche du joueur il le suit
      } else if (direction.length <= detectionHitbox.size.x * 2) {
        // Déplace le zombie selon le vecteur de déplacement calculé
        hasAttacked = false;
        position += displacement;
        if (!isColliding) {
        } else {
          // position -= displacement;
        }
        current = ZombieState.run;
        attackTimer?.stop();
        // Sinon le joueur a reussi a semer le zombie
      } else {
        hasAttacked = false;
        current = ZombieState.idle;
        target.value = null;
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
            target.value = collision.parent as Player;
          }
          if (collision.parent is Zombie &&
              (collision.parent as Zombie).target.value != null) {
            // timeout de 0.5 pour set la target
            Timer(1.0, onTick: () {
              target.value = (collision.parent as Zombie).target.value;
            });
          }
        }
      }
    }

    for (final child in children) {
      if (child is HealthBar) {
        // child.transform.angle = 0;
        // child.angle = 0;
      }
    }
  }

  void split() {
    final imagesAnimations = {
      'body': game.images.fromCache('enemies/zombie_dead_body.png'),
      'arm1': game.images.fromCache('enemies/zombie_dead_arm1.png'),
      'arm2': game.images.fromCache('enemies/zombie_dead_arm2.png'),
      'head': game.images.fromCache('enemies/zombie_dead_head.png'),
    };

    final positions = {
      'body': absolutePosition,
      'arm1': Vector2(58, 7),
      'arm2': Vector2(65, 74),
      'head': Vector2(30, 50),
    };

    final sizes = {
      'body': Vector2(61, 94),
      'arm1': Vector2(52, 23),
      'arm2': Vector2(47, 34),
      'head': Vector2(43, 30),
    };

    final moveEffects = {
      'arm1': Vector2(-40, -40),
      'arm2': Vector2(-40, 40),
      'head': Vector2(-60, 0),
    };

    SpriteComponent createComponent(String name) {
      final component = SpriteComponent(
        sprite: Sprite(imagesAnimations[name]!, srcSize: sizes[name]),
        anchor: Anchor.center,
        position: positions[name],
        angle: absoluteAngle,
        scale: scale,
        priority: 0,
      );

      if (moveEffects.containsKey(name)) {
        component.addAll([
          MoveByEffect(
            moveEffects[name]!,
            EffectController(duration: 0.25),
          ),
          RotateEffect.by(
            20,
            EffectController(duration: 0.25),
          )
        ]);
      }

      if (name == 'body') {
        component.add(OpacityEffect.fadeOut(
            EffectController(duration: 1, startDelay: 4), onComplete: () {
          component.removeFromParent();
        }));
      }

      return component;
    }

    final body = createComponent('body');
    final arm1 = createComponent('arm1');
    final arm2 = createComponent('arm2');
    final head = createComponent('head');

    body.addAll([arm1, arm2, head]);
    world.add(body);
  }

  void explode() {
    final particleComponent = ParticleSystemComponent(
      particle: Particle.generate(
        count: 200,
        lifespan: 1,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, Random().nextDouble() * 100 - 50),
          speed: Vector2(Random().nextDouble() * 100 - 50,
              Random().nextDouble() * 100 - 50),
          child: CircleParticle(
            radius: Random().nextDouble() * 2 + 1, // rayon de la particule
            paint: const PaletteEntry(Color.fromARGB(255, 156, 41, 33)).paint(),
          ),
        ),
      ),
      anchor: Anchor.center,
      position: absolutePosition,
    );
    split();
    removeFromParent();
    world.add(particleComponent);
  }
}

enum ZombieState { idle, attack, run }
