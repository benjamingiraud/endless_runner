import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Collision extends ShapeComponent {
  Collision.rectangle({super.position, super.size, super.priority}) {
    add(RectangleHitbox()..isSolid = true..debugMode = true);
  }
  Collision.circle({super.position, required double radius, super.priority}) {
    add(CircleHitbox(radius: radius, collisionType: CollisionType.passive));
  }

  // Substituez la méthode render pour ne rien dessiner
  @override
  void render(Canvas canvas) {
    // Ne rien faire dans cette méthode
    // Cela empêchera le rectangle d'être dessiné
  }
}
