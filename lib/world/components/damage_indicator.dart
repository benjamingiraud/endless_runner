import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

class DamageIndicator extends PositionComponent {
  late TextComponent textComponent;

  DamageIndicator(String text, double damageAmount,
      {bool isCritical = false, Vector2? position})
      : super(scale: Vector2.all(0.25), position: position ?? Vector2(0, 0)) {
    const maxFontSize = 38.0;
    double fontSize = damageAmount.abs() * 0.75 * (isCritical ? 1.5 : 1);
    final TextRenderer textRenderer = TextPaint(
        style: TextStyle(
      color:
          damageAmount < 0 ? const Color(0xFFFF0000) : const Color(0xFF66BB6A),
      fontWeight: FontWeight.bold,
      fontSize: fontSize.clamp(12.0, maxFontSize),
      fontFamily: 'Babas Neue',
      shadows: const [
        Shadow(
            // bottomLeft
            offset: Offset(-1.0, -1.0),
            color: Colors.black),
        Shadow(
            // bottomRight
            offset: Offset(1.0, -1.0),
            color: Colors.black),
        Shadow(
            // topRight
            offset: Offset(1.0, 1.0),
            color: Colors.black),
        Shadow(
            // topLeft
            offset: Offset(-1.0, 1.0),
            color: Colors.black),
      ],
    ));

    // Créer un composant de texte avec le texte fourni
    textComponent = TextComponent(text: text, textRenderer: textRenderer);

    // Ajouter le composant de texte à ce composant
    add(textComponent);
    addAll([
      ScaleEffect.to(Vector2.all(1.5), EffectController(duration: 0.5)),
      MoveEffect.by(Vector2(0, -50), EffectController(duration: 1)),
      RemoveEffect(delay: 1),
    ]);
  }
}
