import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CriticalHitbox extends RectangleComponent {
  final double critacalMultiplier;
  CriticalHitbox(this.critacalMultiplier,
      {super.position, super.size, super.priority}) {
    add(RectangleHitbox());
  }
  // Substituez la méthode render pour ne rien dessiner
  @override
  void render(Canvas canvas) {
    // Ne rien faire dans cette méthode
    // Cela empêchera le rectangle d'être dessiné
  }
}
