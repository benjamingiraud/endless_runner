import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

class DamageIndicator extends PositionComponent {
  late TextComponent textComponent;

  DamageIndicator(String text, double damageAmount, {bool isCritical = false, Vector2? position})
      : super(scale: Vector2.all(0.25), position: position ?? Vector2(0, 0)) {
    const maxFontSize = 38.0;
    double fontSize = damageAmount.abs() * 0.75 * (isCritical ? 1.5 : 1);
    final TextRenderer textRenderer = TextPaint(
        style: TextStyle(
      color:
          damageAmount < 0 ? const Color(0xFFFF0000) : const Color(0xFF66BB6A),
      fontWeight: FontWeight.bold,
      fontSize: fontSize.clamp(12.0, maxFontSize),
      shadows: const [
        Shadow(
          color: Color.fromARGB(25, 0, 0, 0), // Couleur de l'ombre
          blurRadius: 2, // Rayon de flou de l'ombre
          offset: Offset(2, 2), // Décalage de l'ombre par rapport au texte
        ),
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
