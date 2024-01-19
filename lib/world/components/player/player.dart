import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flutter/foundation.dart';

class Player extends RectangleComponent
    with HasGameRef, CollisionCallbacks, HasWorldReference<World> {
  /// Pixels/s
  double maxSpeed = 300.0;
  late final Vector2 _lastSize = size.clone();
  late final Transform2D _lastTransform = transform.clone();

  final JoystickComponent joystick;
  final CameraComponent camera;

  String getDirection() {
    return joystick.direction.toString().replaceAll('JoystickDirection.', '');
  }

  Player(this.joystick, this.camera)
      : super(
            position: Vector2(10.0, 15.0),
            angle: pi / 2,
            size: Vector2.all(30),
            anchor: Anchor.center,
            priority: 50,
            children: [
              RectangleHitbox(isSolid: true)..renderShape = kDebugMode,
            ],
            paint: BasicPalette.black.paint());

  @override
  void update(double dt) {
    if (!joystick.delta.isZero()) {
      _lastSize.setFrom(size);
      _lastTransform.setFrom(transform);
      angle = joystick.delta.screenAngle();
      if (activeCollisions.isEmpty) {
        position.add(joystick.relativeDelta * maxSpeed * dt);
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    transform.setFrom(_lastTransform);
    size.setFrom(_lastSize);
    if (kDebugMode) {
      print(intersectionPoints);
    }
  }

  // @override
  // bool debugMode = true;
}
