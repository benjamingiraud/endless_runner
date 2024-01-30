import 'package:endless_runner/world/mixins/health.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart';

class Bullet extends SpriteComponent with CollisionCallbacks {
  final Vector2 speed;
  @override
  final double angle;
  final Image spriteImage;
  final double lifeTime;
  final PositionComponent player;
  final double damage;
  Timer? lifeTimeTimer;

  Bullet({
    required Vector2 position,
    required this.speed,
    required this.angle,
    required this.spriteImage,
    required this.player,
    this.lifeTime = 0.2,
    this.damage = 0,
  }) : super(
            sprite: Sprite(spriteImage),
            position: position,
            angle: angle,
            anchor: Anchor.center) {
    // To avoid performance issues, remove bullet in desired time
    lifeTimeTimer = Timer(lifeTime, onTick: () {
      removeFromParent();
    });
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifeTimeTimer?.update(dt);
    // Mettez à jour la position de la balle en fonction de la vitesse et de l'angle
    position.add(speed * dt);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Health) {
      (other as Health).damage(damage, damager: this);
    }
    super.onCollisionStart(intersectionPoints, other);
    lifeTimeTimer?.stop();
    removeFromParent();
  }
}
