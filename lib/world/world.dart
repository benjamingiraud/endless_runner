import 'dart:math';

import 'package:endless_runner/world/components/player/player.dart';
import 'package:endless_runner/world/components/zombie.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flame/experimental.dart';

class World extends FlameGame
    with
        HasCollisionDetection,
        CollisionCallbacks,
        ScrollDetector,
        ScaleDetector {
  late final Player player;
  late final JoystickComponent joystickMove;
  late final JoystickComponent joystickAngle;

  late final TextComponent speedText;
  late final TextComponent directionText;
  late final TextComponent animationText;
  late final TextComponent ammoText;

  late TiledComponent mapComponent;

  @override
  Color backgroundColor() => const Color(0xFFeeeeee);

  @override
  // bool debugMode = kDebugMode ? true : false;

  @override
  Future<void> onLoad() async {
    mapComponent = await TiledComponent.load('test.tmx', Vector2.all(32));
    world.add(mapComponent);

    final knobPaint = BasicPalette.black.withAlpha(150).paint();
    final backgroundPaint = BasicPalette.black.withAlpha(100).paint();

    world.add(ScreenHitbox());

    joystickMove = JoystickComponent(
      knob: CircleComponent(radius: 15, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 15, bottom: 15),
    );
    joystickAngle = JoystickComponent(
      knob: CircleComponent(radius: 15, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(right: 15, bottom: 15),
    );

    player = Player(joystickMove, joystickAngle, camera);
    world.add(player);

    camera.viewport.add(joystickMove);
    camera.viewport.add(joystickAngle);
    camera.setBounds(null, considerViewport: true);
    camera.follow(player, maxSpeed: 200, snap: true);

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
      animationText = TextComponent(
        text: 'Aniamtion: idle',
        textRenderer: regular,
      );
      ammoText = TextComponent(
        text: 'Munitions : ${(player.magazineAmmo)}/${(player.totalAmmo)}',
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

      final animationWithMargin = HudMarginComponent(
        margin: const EdgeInsets.only(
          top: 45,
          left: 15,
        ),
      )..add(animationText);

      final ammoWithMargin = HudMarginComponent(
        margin: const EdgeInsets.only(
          top: 60,
          left: 15,
        ),
      )..add(ammoText);

      add(FpsTextComponent(position: Vector2(15, 0), textRenderer: regular));
      camera.viewport.addAll([
        speedWithMargin,
        directionWithMargin,
        animationWithMargin,
        ammoWithMargin
      ]);
    }

    // world.add(
    //   SpawnComponent.periodRange(
    //     factory: (_) => Zombie(),
    //     minPeriod: 1.0,
    //     maxPeriod: 2.0,
    //     area: Rectangle.fromPoints(
    //       Vector2(0, 1200),
    //       Vector2(1200, 0),
    //     ),
    //     random: Random(),
    //     // selfPositioning: true,
    //   ),
    // );

    world.add(Zombie(
        position: Vector2(200, 200), currentHealth: 1000, maxHealth: 1000));
  }

  @override
  void update(double dt) {
    super.update(dt);

    speedText.text =
        'Speed: ${(joystickMove.intensity * player.maxSpeed).round()}';
    final direction =
        joystickMove.direction.toString().replaceAll('JoystickDirection.', '');
    directionText.text = 'Direction: $direction';
    animationText.text = 'Animation : ${(player.current)}';
    ammoText.text =
        'Munitions : ${(player.magazineAmmo.value)}/${(player.totalAmmo.value)}';
  }

  // Camera zoom
  void clampZoom() {
    camera.viewfinder.zoom = camera.viewfinder.zoom.clamp(0.5, 2.0);
  }

  static const zoomPerScrollUnit = 0.1;

  @override
  void onScroll(PointerScrollInfo info) {
    camera.viewfinder.zoom +=
        info.scrollDelta.global.y.sign * zoomPerScrollUnit;
    clampZoom();
  }

  late double startZoom;

  @override
  void onScaleStart(_) {
    startZoom = camera.viewfinder.zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    final currentScale = info.scale.global;
    if (!currentScale.isIdentity()) {
      camera.viewfinder.zoom = startZoom * currentScale.y;
      clampZoom();
    } else {
      final delta = info.delta.global;
      camera.viewfinder.position.translate(-delta.x, -delta.y);
    }
  }
}
