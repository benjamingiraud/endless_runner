import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HealthBar extends PositionComponent {
  double previousHealth = 0;
  double maxHealth;
  double currentHealth;
  double previousShield = 0;
  double maxShield;
  double currentShield;
  final bool showText;

  @override
  final double width;
  @override
  final double height;

  final bool centered;

  HealthBar(
      this.maxHealth, this.currentHealth, this.maxShield, this.currentShield,
      {required this.showText,
      required this.width,
      required this.height,
      required this.centered});

  void updateHealth(double newHealth) {
    currentHealth = newHealth;
  }

  void updateShield(double newShield) {
    currentShield = newShield;
  }

  @override
  void render(Canvas canvas) {
    renderHealthBar(canvas);
    renderShieldBar(canvas);
    previousHealth = currentHealth;
    previousShield = currentShield;
  }

  void renderHealthBar(Canvas canvas) {
    final double percentage = currentHealth / maxHealth;
    final double barWidth = width * percentage;
    const barRadius = Radius.circular(10.0);

    final barPosition = getBarPosition(centered);

    if (currentHealth < previousHealth) {
      renderLostHealthBar(canvas, barPosition);
    }

    renderBackgroundBar(
        canvas, barPosition, width, height, barRadius, Colors.grey);
    renderBorder(canvas, barPosition, width, height, barRadius);

    renderFilledBar(
      canvas,
      barPosition,
      barWidth,
      height,
      barRadius,
      [const Color(0xFF66BB6A), const Color(0xFF4CAF50)],
    );

    if (showText) {
      renderText(canvas, barPosition, currentHealth, maxHealth);
    }
  }

  void renderLostHealthBar(Canvas canvas, Offset barPosition) {
    final lostHealthWidth = (previousHealth / maxHealth) * width;

    final lostHealthRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        barPosition.dx,
        barPosition.dy,
        lostHealthWidth,
        height,
      ),
      const Radius.circular(10.0),
    );
    final paint = Paint()..color = Colors.red;
    canvas.drawRRect(lostHealthRect, paint);
  }

  void renderShieldBar(Canvas canvas) {
    if (maxShield > 0) {
      final shieldPercentage = currentShield / maxShield;
      final shieldBarWidth = width * shieldPercentage;
      const shieldBarRadius = Radius.circular(10.0);
      final shieldBarHeight = height - (height / 3);
      final shieldBarPosition =
          getBarPosition(centered, yOffset: -shieldBarHeight);

      renderBackgroundBar(
        canvas,
        shieldBarPosition,
        width,
        shieldBarHeight,
        shieldBarRadius,
        Colors.grey,
      );
      renderBorder(
          canvas, shieldBarPosition, width, shieldBarHeight, shieldBarRadius);
      renderFilledBar(
        canvas,
        shieldBarPosition,
        shieldBarWidth,
        shieldBarHeight,
        shieldBarRadius,
        [
          const Color.fromARGB(255, 102, 122, 187),
          const Color.fromARGB(255, 76, 83, 175)
        ],
      );

      if (showText) {
        renderText(canvas, shieldBarPosition, currentShield, maxShield,
            textH: shieldBarHeight);
      }
    }
  }

  void renderBackgroundBar(
    Canvas canvas,
    Offset position,
    double width,
    double height,
    Radius radius,
    Color color,
  ) {
    final backgroundPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx, position.dy, width, height),
        radius,
      ),
      backgroundPaint,
    );
  }

  void renderBorder(Canvas canvas, Offset position, double width, double height,
      Radius radius) {
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx, position.dy, width, height),
        radius,
      ),
      borderPaint,
    );
  }

  void renderFilledBar(
    Canvas canvas,
    Offset position,
    double barWidth,
    double height,
    Radius radius,
    List<Color> colors,
  ) {
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
          Rect.fromLTWH(position.dx, position.dy, barWidth, height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx, position.dy, barWidth, height),
        radius,
      ),
      fillPaint,
    );
  }

  void renderText(Canvas canvas, Offset position, double current, double max,
      {double? textH}) {
    const textStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w300,
      fontSize: 12.0,
    );
    final textSpan = TextSpan(
      text: '${(current)} / ${(max)}',
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        position.dx + (width - textPainter.width) / 2,
        position.dy + ((textH ?? height) - textPainter.height) / 2,
      ),
    );
  }

  Offset getBarPosition(bool centered, {double yOffset = 0}) {
    final x =
        centered ? (parent as PositionComponent).scaledSize.x / 2 - width / 2 : 0.0;
    return Offset(x, yOffset);
  }
}
