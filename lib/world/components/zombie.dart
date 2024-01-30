import 'dart:math';

import 'package:endless_runner/world/mixins/health.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Zombie extends SpriteAnimationGroupComponent<ZombieState>
    with HasGameRef, CollisionCallbacks, HasWorldReference<World>, Health {
  Zombie({super.position, double? currentHealth, double? maxHealth})
      : super(anchor: Anchor.center, nativeAngle: pi / 2) {
    initializeHealthMixin(maxHealth ?? 100.0, 0,
        currentHealth: currentHealth ?? Random().nextDouble() * 100 + 50);
  }

  PositionComponent? target;
  // PositionComponent get target => _target;
  // void set target(PositionComponent target) {
  //   _target = target;
  // }

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
    if (target != null) {
      lookAt(target!.position);

      // Calcule le vecteur de déplacement vers la position du joueur
      final targetPosition = target!.position;
      final direction = targetPosition - position;

      // Normalise le vecteur de direction pour obtenir une unité de vecteur de déplacement
      final unitDirection = direction.normalized();

      // Multiplie le vecteur de direction unitaire par la vitesse souhaitée pour obtenir le déplacement final
      const speed = 100.0; // Réglez la vitesse selon vos besoins
      final displacement = unitDirection * speed * dt;

      // Vérifie si le zombie est suffisamment proche du joueur pour l'attaquer
      const attackRange = 20.0; // Réglez la portée d'attaque selon vos besoins
      if (direction.length <= target!.size.x) {
        // Attaquer le joueur
        //...
      } else if (direction.length <= 800.0) {
        // Déplace le zombie selon le vecteur de déplacement calculé
        position += displacement;
      } else {
        target = null;
      }
    }
    // int count = 0;
    // for (var child in children) {
    //   if (child is ColorEffect) {
    //     count++;
    //     if (child.controller.completed) {
    //       child.removeFromParent();
    //     }
    //   }
    // }
    // print(count);
  }
}

enum ZombieState { idle }
