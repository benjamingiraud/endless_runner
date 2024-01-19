import 'package:endless_runner/world/components/player/player.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class World extends FlameGame with HasCollisionDetection, CollisionCallbacks {
  late final Player player;
  late final JoystickComponent joystick;
  late final TextComponent speedText;
  late final TextComponent directionText;

  @override
  Color backgroundColor() => const Color(0xFFeeeeee);

  @override
  // bool debugMode = kDebugMode ? true : false;

  @override
  Future<void> onLoad() async {
    final knobPaint = BasicPalette.black.withAlpha(150).paint();
    final backgroundPaint = BasicPalette.black.withAlpha(100).paint();

    world.add(ScreenHitbox());

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 15, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 15, bottom: 15),
    );

    player = Player(joystick, camera);
    world.add(player);

    camera.viewport.add(joystick);
    camera.setBounds(null, considerViewport: true);
    camera.follow(player, maxSpeed: 200, snap: true);

    final paint = BasicPalette.gray.paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    world.add(
      CircleComponent(
        position: Vector2(100, 100),
        radius: 50,
        paint: paint,
        children: [CircleHitbox(isSolid: true)],
      ),
    );
    world.add(
      CircleComponent(
        position: Vector2(150, 500),
        radius: 50,
        paint: paint,
        children: [CircleHitbox(isSolid: true)],
      ),
    );
    world.add(
      RectangleComponent(
        position: Vector2.all(300),
        size: Vector2.all(100),
        paint: paint,
        children: [RectangleHitbox(isSolid: true)],
      ),
    );
    world.add(
      RectangleComponent(
        position: Vector2.all(500),
        size: Vector2(100, 200),
        paint: paint,
        children: [RectangleHitbox(isSolid: true)],
      ),
    );
    world.add(
      RectangleComponent(
        position: Vector2(550, 200),
        size: Vector2(200, 150),
        paint: paint,
        children: [RectangleHitbox(isSolid: true)],
      ),
    );

    if (kDebugMode) {
      final regular = TextPaint(
        style: TextStyle(color: BasicPalette.black.color),
      );
      speedText = TextComponent(
        text: 'Speed: 0',
        textRenderer: regular,
      );
      directionText = TextComponent(
        text: 'Direction: idle',
        textRenderer: regular,
      );

      final speedWithMargin = HudMarginComponent(
        margin: const EdgeInsets.only(
          top: 15,
          left: 15,
        ),
      )..add(speedText);

      final directionWithMargin = HudMarginComponent(
        margin: const EdgeInsets.only(
          top: 30,
          left: 15,
        ),
      )..add(directionText);

      add(FpsTextComponent(position: Vector2(15, 0), textRenderer: regular));
      camera.viewport.addAll([speedWithMargin, directionWithMargin]);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    speedText.text = 'Speed: ${(joystick.intensity * player.maxSpeed).round()}';
    final direction =
        joystick.direction.toString().replaceAll('JoystickDirection.', '');
    directionText.text = 'Direction: $direction';

    // if (player.isColliding) {
    //   camera.stop();
    // } else {
    //   camera.follow(player, maxSpeed: 250, snap: true);
    // }
  }
}
