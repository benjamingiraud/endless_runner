import 'dart:math';

import 'package:endless_runner/world/components/bullet.dart';
import 'package:endless_runner/world/mixins/health.dart';
import 'package:flame/cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

class Player extends SpriteAnimationGroupComponent<PlayerState>
    with HasGameRef, CollisionCallbacks, HasWorldReference<World>, Health {
  final totalAmmo = ValueNotifier(9999);
  final magazineAmmo = ValueNotifier(8);
  double bulletSpeed = 2000.0;
  double bulletDamage = 25.0;
  double shootingInterval = 0.5; // Intervalle de tir en secondes
  double reloadInterval = 2.0; // Intervalle de réchargement en secondes
  Timer? shootingTimer;
  Timer? reloadTimer;

  /// Pixels/s
  double maxSpeed = 300.0;
  double relativeAngle = -80.0;
  late final Vector2 _lastSize = size.clone();
  late final Transform2D _lastTransform = transform.clone();

  final JoystickComponent joystickMove;
  final JoystickComponent joystickAngle;
  final CameraComponent camera;
  final images = Images();

  String getDirection() {
    return joystickMove.direction
        .toString()
        .replaceAll('JoystickDirection.', '');
  }

  Player(this.joystickMove, this.joystickAngle, this.camera)
      : super(anchor: Anchor.center, nativeAngle: pi/2) {
    initializeHealthMixin(100, 50);
  }

  @override
  Future<void> onLoad() async {
    // load all images here ?
    await images.load('player/bullet.png');

    animations = {
      PlayerState.handgunIdle: await game.loadSpriteAnimation(
        'player/handgun_idle.png',
        SpriteAnimationData.sequenced(
          amount: 20,
          textureSize: Vector2(127, 108),
          stepTime: 0.1,
        ),
      ),
      PlayerState.handgunMove: await game.loadSpriteAnimation(
        'player/handgun_move.png',
        SpriteAnimationData.sequenced(
          amount: 20,
          textureSize: Vector2(129, 110),
          stepTime: 0.05,
        ),
      ),
      PlayerState.handgunShoot: await game.loadSpriteAnimation(
        'player/handgun_shoot.png',
        SpriteAnimationData.sequenced(
          amount: 3,
          textureSize: Vector2(128, 108),
          stepTime: shootingInterval / 3,
        ),
      ),
      PlayerState.handgunReload: await game.loadSpriteAnimation(
        'player/handgun_reload.png',
        SpriteAnimationData.sequenced(
          amount: 15,
          textureSize: Vector2(130, 115),
          stepTime: reloadInterval / 15,
        ),
      ),
    };
    // The starting state will be that the player is idle with handgun.
    current = PlayerState.handgunIdle;

    add(CircleHitbox()..renderShape = false);

    magazineAmmo.addListener(() {
      if (magazineAmmo.value == 0) {
        current = PlayerState.handgunReload;
        reloadTimer = Timer(reloadInterval, onTick: () {
          const int reloadAmmount = 8;
          if (totalAmmo.value >= reloadAmmount) {
            totalAmmo.value -= reloadAmmount;
            magazineAmmo.value = reloadAmmount;
          }
        });
      }
    });
  }

  bool isShooting() => !joystickAngle.delta.isZero();
  bool isMoving() => !joystickMove.delta.isZero();
  bool canShoot() => magazineAmmo.value > 0 && !hasShot;
  bool hasShot = false;

  @override
  void update(double dt) {
    super.update(dt);
    shootingTimer?.update(dt);
    reloadTimer?.update(dt);

    if (isMoving()) {
      _lastSize.setFrom(size);
      _lastTransform.setFrom(transform);
      if (activeCollisions.isEmpty) {
        position.add(joystickMove.relativeDelta * maxSpeed * dt);
      }
      if (!isShooting()) {
        angle = joystickMove.delta.screenAngle() - relativeAngle;
        current = PlayerState.handgunMove;
      }
    } else if (!isShooting()) {
      current = PlayerState.handgunIdle;
    }

    if (isShooting()) {
      angle = joystickAngle.delta.screenAngle() - relativeAngle;

      if (canShoot()) {
        current = PlayerState.handgunShoot;
        shootBullet();
        hasShot = true;
        shootingTimer = Timer(shootingInterval, onTick: () {
          hasShot = false;
        });
      }
    }

    if (health < maxHealth) {
      heal(1 + (1 * dt));
    }
  }

  void shootBullet() {
    final ajustedAngle = angle + 0.4;
    final offsetX = cos(ajustedAngle) * (size.x / 2 + 10);
    final bulletX = position.x + offsetX;

    final offsetY = sin(ajustedAngle) * (size.x / 2 + 10);
    final bulletY = position.y + offsetY;

    final bulletDirection = Vector2(
      cos(angle) * bulletSpeed,
      sin(angle) * bulletSpeed,
    );

    final bullet = Bullet(
      // position: Vector2(position.x + 117, position.y + 79),
      position: Vector2(bulletX, bulletY),
      player: this,
      speed: bulletDirection,
      angle: angle,
      spriteImage: images.fromCache('player/bullet.png'),
      lifeTime: 5.0,
      damage: bulletDamage,
    );
    // Ajoutez la balle à votre jeu
    world.add(bullet);
    magazineAmmo.value -= 1;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    transform.setFrom(_lastTransform);
    size.setFrom(_lastSize);

    // if (other is Zombie) {
    //   damage(20);
    // }
  }

  @override
  bool debugMode = true;
}

enum PlayerState { handgunIdle, handgunMove, handgunShoot, handgunReload }
