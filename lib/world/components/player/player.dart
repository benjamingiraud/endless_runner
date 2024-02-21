import 'dart:math';

import 'package:flame/effects.dart';
import 'package:survival_zombie/audio/sounds.dart';
import 'package:survival_zombie/world/components/bullet.dart';
import 'package:survival_zombie/world/components/critical_hitbox.dart';
import 'package:survival_zombie/world/game_main.dart';
import 'package:survival_zombie/world/mixins/health.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class Player extends SpriteAnimationGroupComponent<PlayerState>
    with
        CollisionCallbacks,
        HasWorldReference<World>,
        HasGameReference<GameMain>,
        Health {
  final totalAmmo = ValueNotifier(9999);
  final magazineAmmo = ValueNotifier(8);
  double bulletSpeed = 2000.0;
  double bulletDamage = 12.5;
  double shootingInterval = 0.5; // Intervalle de tir en secondes
  double reloadInterval = 2.0; // Intervalle de réchargement en secondes
  Timer? shootingTimer;
  Timer? reloadTimer;

  // Pixels/s
  double endurance = 100.0;
  double speed = 300.0;
  double maxSpeed = 300.0;
  double relativeAngle = -80.0;
  late final Vector2 _lastSize = size.clone();
  late final Transform2D _lastTransform = transform.clone();

  final JoystickComponent joystickMove;
  final JoystickComponent joystickAngle;
  final CameraComponent camera;

  Player(this.joystickMove, this.joystickAngle, this.camera, {super.position})
      : super(
            anchor: Anchor.center,
            priority: 1,
            nativeAngle: pi / 2,
            scale: Vector2.all(0.75)) {
    initializeHealthMixin(100,
        maxShield: 100,
        currentShield: 50,
        showText: true,
        shouldRender: false,
        barWidth: 200,
        barHeight: 20,
        barCentered: false);
  }

  @override
  Future<void> onLoad() async {
    // load all images here ?
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

    add(CircleHitbox(radius: size.x / 3, position: size / 6)
      ..renderShape = false);

    final healthBarHud = HudMarginComponent(
      margin: const EdgeInsets.only(
        bottom: 100,
        left: 125,
      ),
    )..add(healthBar);
    camera.viewport.add(healthBarHud);

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
        position.add(joystickMove.relativeDelta * speed * dt);
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
  }

  void shootBullet() {
    // add a flash/glow animation
    final muzzleImg = game.images.fromCache('effects/muzzle1.png');
    final muzzle = SpriteComponent(
        sprite: Sprite(muzzleImg, srcSize: Vector2(165, 165)),
        anchor: Anchor.center,
        position: Vector2(135, 80),
        scale: Vector2(.25, .25),
        priority: 2);

    add(muzzle);
    muzzle.addAll([
      OpacityEffect.fadeIn(EffectController(duration: 0.1, startDelay: 0)),
      OpacityEffect.fadeOut(EffectController(duration: 0.1, startDelay: 0.1),
          onComplete: () {
        muzzle.removeFromParent();
      })
    ]);

    final ajustedAngle = absoluteAngle + 0.4;
    final offsetX = cos(ajustedAngle) * (size.x / 2);
    final bulletX = absolutePosition.x + offsetX;

    final offsetY = sin(ajustedAngle) * (size.x / 2);
    final bulletY = absolutePosition.y + offsetY;

    final bulletDirection = Vector2(
      cos(absoluteAngle) * bulletSpeed,
      sin(absoluteAngle) * bulletSpeed,
    );

    final bullet = Bullet(
      position: Vector2(bulletX, bulletY),
      player: this,
      speed: bulletDirection,
      angle: angle,
      spriteImage: game.images.fromCache('player/bullet.png'),
      lifeTime: 5.0,
      damage: bulletDamage,
    );
    // Ajoutez la balle à votre jeu
    world.add(bullet);
    game.audioController.playSfx(SfxType.shoot);
    magazineAmmo.value -= 1;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is! CriticalHitbox) {
      super.onCollisionStart(intersectionPoints, other);
      transform.setFrom(_lastTransform);
      size.setFrom(_lastSize);
    }
  }

  String getDirection() {
    return joystickMove.direction
        .toString()
        .replaceAll('JoystickDirection.', '');
  }
}

enum PlayerState { handgunIdle, handgunMove, handgunShoot, handgunReload }
