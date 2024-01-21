import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/palette.dart';

class HealthBar extends PositionComponent {
  double maxHealth;
  double currentHealth;

  HealthBar(this.maxHealth, this.currentHealth) {
    width = 50;
    height = 5;
  }

  void updateHealth(double newHealth) {
    currentHealth = newHealth;
  }

  @override
  void render(Canvas canvas) {
    // Dessinez la barre de vie
    final double percentage = currentHealth / maxHealth;
    final double barWidth = width * percentage;

    // Dessinez le contour de la barre de vie
    final Paint borderPaint = BasicPalette.black.paint();
    canvas.drawRect(
        Rect.fromLTWH(x - x * (-0.5), y - 15, width, height), borderPaint);
    final Paint barPaint = BasicPalette.green.paint();
    canvas.drawRect(
        Rect.fromLTWH(x - x * (-0.5), y - 15, barWidth, height), barPaint);
  }
}
