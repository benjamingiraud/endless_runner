import 'dart:math';

import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';
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
  final currentWeapon = ValueNotifier("handgun");
  final totalAmmo = ValueNotifier(9999);
  final magazineAmmo = ValueNotifier(8);

  double bulletSpeed = 2000.0;
  double bulletDamage = 12.5;
  double bulletLifeTime = 5.0;
  double shootingInterval = 0.5; // Intervalle de tir en secondes
  double reloadInterval = 2.0; // Intervalle de réchargement en secondes
  Timer? shootingTimer;
  Timer? reloadTimer;

  double dashInterval = 5.0;
  Timer? dashTimer;

  // Pixels/s
  double endurance = 100.0;
  double speed = 300.0;
  double maxSpeed = 300.0;
  double relativeAngle = -80.0;
  late final Vector2 _lastSize = size.clone();
  late final Transform2D _lastTransform = transform.clone();
  late double _lastX = position.x;
  late double _lastY = position.y;
  late double _lastAngle = angle;

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
        showText: false,
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
      PlayerState.shotgunIle: await game.loadSpriteAnimation(
        'player/shotgun_idle.png',
        SpriteAnimationData.sequenced(
          amount: 20,
          textureSize: Vector2(157, 104),
          stepTime: 0.1,
        ),
      ),
      PlayerState.shotgunMove: await game.loadSpriteAnimation(
        'player/shotgun_move.png',
        SpriteAnimationData.sequenced(
          amount: 20,
          textureSize: Vector2(157, 103),
          stepTime: 0.1,
        ),
      ),
      PlayerState.shotgunShoot: await game.loadSpriteAnimation(
        'player/shotgun_shoot.png',
        SpriteAnimationData.sequenced(
          amount: 3,
          textureSize: Vector2(156, 103),
          stepTime: shootingInterval / 3,
        ),
      ),
      PlayerState.shotgunReload: await game.loadSpriteAnimation(
        'player/shotgun_reload.png',
        SpriteAnimationData.sequenced(
          amount: 20,
          textureSize: Vector2(161, 109),
          stepTime: reloadInterval / 20,
        ),
      ),
    };
    // The starting state will be that the player is idle with handgun.
    current = getIdle();

    add(CircleHitbox(radius: size.x / 4, position: size / 4)..debugMode = true);

    final healthBarHud = HudMarginComponent(
      margin: const EdgeInsets.only(
        bottom: 100,
        left: 125,
      ),
    )..add(healthBar);
    camera.viewport.add(healthBarHud);

    magazineAmmo.addListener(() {
      if (magazineAmmo.value == 0) {
        if (currentWeapon.value == 'shotgun') {
          shotgunReload();
        } else {
          current = getReload();
          reloadTimer = Timer(reloadInterval, onTick: () {
            const int reloadAmmount = 8;
            if (totalAmmo.value >= reloadAmmount) {
              totalAmmo.value -= reloadAmmount;
              magazineAmmo.value = reloadAmmount;
            }
          });
        }
      }
    });

    currentWeapon.addListener(() {
      if (currentWeapon.value == 'handgun') {
        size = Vector2(127, 108);
        bulletSpeed = 2000.0;
        bulletDamage = 12.5;
        bulletLifeTime = 5.0;
        shootingInterval = 0.5; // Intervalle de tir en secondes
        reloadInterval = 2.0; // Intervalle de réchargement en secondes
      } else if (currentWeapon.value == 'shotgun') {
        size = Vector2(157, 104);
        bulletSpeed = 1500.0;
        bulletDamage = 15.0;
        bulletLifeTime = 0.125;
        shootingInterval = 1.0; // Intervalle de tir en secondes
        reloadInterval = 1.0; // Intervalle de réchargement en secondes
      }
    });
    currentWeapon.value = 'shotgun';
  }

  bool isShooting() => !joystickAngle.delta.isZero();
  bool isMoving() => !joystickMove.delta.isZero();
  bool canShoot() => magazineAmmo.value > 0 && !hasShot;
  bool hasShot = false;

  bool canDash() => dashTimer == null;

  void shotgunReload() {
    current = getReload();
    const int reloadAmmount = 8;
    if (totalAmmo.value >= reloadAmmount &&
        magazineAmmo.value < reloadAmmount) {
      totalAmmo.value -= 1;
      magazineAmmo.value += 1;
      reloadTimer = Timer(reloadInterval, onTick: shotgunReload);
    }
  }

  void switchWeapon() {
    if (currentWeapon.value == 'handgun') {
      currentWeapon.value = 'shotgun';
    } else {
      currentWeapon.value = 'handgun';
    }
  }

  void dash() {
    dashTimer = Timer(dashInterval, onTick: () => dashTimer = null);

    final bloodSpriteImg = game.images.fromCache('effects/dash.png');
    final bloodSpriteSheet = SpriteSheet(
      image: bloodSpriteImg,
      srcSize: Vector2(64, 64),
    );

    final dashAnimation = bloodSpriteSheet.createAnimation(
        row: 0, stepTime: 0.1, to: 6, loop: false);
    world.add(SpriteAnimationComponent(
        animation: dashAnimation,
        removeOnFinish: true,
        scale: Vector2.all(2.5),
        position: absolutePosition - Vector2(size.x, size.y),
        priority: 1));

    if (isMoving()) {
      position.add(joystickMove.relativeDelta * 200.0);
    } else {
      position.add(Vector2(200.0, 0.0)..rotate(angle));
    }
  }

  // Player States
  PlayerState getIdle() {
    switch (currentWeapon.value) {
      case 'handgun':
        return PlayerState.handgunIdle;
      case 'shotgun':
        return PlayerState.shotgunIle;
      default:
        return PlayerState.handgunIdle;
    }
  }

  PlayerState getMove() {
    switch (currentWeapon.value) {
      case 'handgun':
        return PlayerState.handgunMove;
      case 'shotgun':
        return PlayerState.shotgunMove;
      default:
        return PlayerState.handgunMove;
    }
  }

  PlayerState getShoot() {
    switch (currentWeapon.value) {
      case 'handgun':
        return PlayerState.handgunShoot;
      case 'shotgun':
        return PlayerState.shotgunShoot;
      default:
        return PlayerState.handgunShoot;
    }
  }

  PlayerState getReload() {
    switch (currentWeapon.value) {
      case 'handgun':
        return PlayerState.handgunReload;
      case 'shotgun':
        return PlayerState.shotgunReload;
      default:
        return PlayerState.handgunReload;
    }
  }

  // Guns
  String shootMuzzle() {
    switch (currentWeapon.value) {
      case 'handgun':
        return 'muzzle1';
      case 'shotgun':
        return 'muzzle2';
      default:
        return 'muzzle1';
    }
  }

  Vector2 shootMuzzlePosition() {
    switch (currentWeapon.value) {
      case 'handgun':
        return Vector2(135, 80);
      case 'shotgun':
        return Vector2(170, 75);
      default:
        return Vector2(135, 80);
    }
  }

  Vector2 shootMuzzleScale() {
    switch (currentWeapon.value) {
      case 'handgun':
        return Vector2(.25, .25);
      case 'shotgun':
        return Vector2(.5, .5);
      default:
        return Vector2(.25, .25);
    }
  }

  String shootBulletSprite() {
    switch (currentWeapon.value) {
      case 'handgun':
        return 'bullet';
      case 'shotgun':
        return 'shotgun_bullet';
      default:
        return 'bullet';
    }
  }

  SfxType shootSfx() {
    switch (currentWeapon.value) {
      case 'handgun':
        return SfxType.shoot;
      case 'shotgun':
        return SfxType.shotgun;
      default:
        return SfxType.shoot;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    shootingTimer?.update(dt);
    reloadTimer?.update(dt);
    dashTimer?.update(dt);

    if (isMoving()) {
      _lastSize.setFrom(size);
      _lastTransform.setFrom(transform);
      _lastX = position.x;
      _lastY = position.y;
      position.x += joystickMove.relativeDelta.x * speed * dt;
      if (activeCollisions.isNotEmpty) {
        position.x = _lastX;
      }

      position.y += joystickMove.relativeDelta.y * speed * dt;
      if (activeCollisions.isNotEmpty) {
        position.y = _lastY;
      }

      // if (activeCollisions.isEmpty) {
      // position.add(joystickMove.relativeDelta * speed * dt);
      // }
      if (!isShooting()) {
        _lastAngle = angle;
        angle = joystickMove.delta.screenAngle() - relativeAngle;
        // if (activeCollisions.isNotEmpty) {
        //   angle = _lastAngle;
        // }
        current = getMove();
      }
    } else if (!isShooting()) {
      current = getIdle();
    }

    if (isShooting()) {
      angle = joystickAngle.delta.screenAngle() - relativeAngle;

      if (canShoot()) {
        current = getShoot();
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
    final muzzleImg = game.images.fromCache('effects/${shootMuzzle()}.png');
    final muzzle = SpriteComponent(
        sprite: Sprite(muzzleImg, srcSize: Vector2(165, 165)),
        anchor: Anchor.center,
        position: shootMuzzlePosition(),
        scale: shootMuzzleScale(),
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
      angle: angle,
      spriteImage: game.images.fromCache('player/${shootBulletSprite()}.png'),
      speed: bulletDirection,
      lifeTime: bulletLifeTime,
      damage: bulletDamage,
    );

    world.add(bullet);
    game.audioController.playSfx(shootSfx());
    magazineAmmo.value -= 1;

    // if shotgun add 7 other bullets with different direction
    if (currentWeapon.value == 'shotgun') {
      const spreadAngle = 0.5; // angle of spread in degrees
      const numBullets = 7;

      for (var i = 0; i < numBullets; i++) {
        final spread = (spreadAngle / (numBullets - 1)) * i - spreadAngle / 2;
        final bulletDirectionWithSpread = Vector2.copy(bulletDirection);
        bulletDirectionWithSpread.rotate(spread);

        final bullet = Bullet(
          position: Vector2(bulletX, bulletY),
          player: this,
          angle: angle + spread,
          spriteImage: game.images.fromCache('player/shotgun_bullet.png'),
          speed: bulletDirectionWithSpread,
          lifeTime: bulletLifeTime,
          damage: bulletDamage,
        );
        world.add(bullet);
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is! CriticalHitbox) {
      super.onCollisionStart(intersectionPoints, other);
      // transform.setFrom(_lastTransform);
      // size.setFrom(_lastSize);
    }
  }

  String getDirection() {
    return joystickMove.direction
        .toString()
        .replaceAll('JoystickDirection.', '');
  }
}

enum PlayerState {
  handgunIdle,
  handgunMove,
  handgunShoot,
  handgunReload,

  shotgunIle,
  shotgunMove,
  shotgunShoot,
  shotgunReload
}
