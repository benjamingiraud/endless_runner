import 'package:survival_zombie/audio/audio_controller.dart';
import 'package:survival_zombie/world/components/player/player.dart';
import 'package:survival_zombie/world/components/zombie.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:survival_zombie/world/game_screen.dart';

class GameMain extends FlameGame
    with
        HasCollisionDetection,
        CollisionCallbacks,
        HasTimeScale,
        ScrollDetector,
        ScaleDetector {
  GameMain(
      {required this.audioController,
      required this.screenWidth,
      required this.screenHeight});

  late final double screenWidth;
  late final double screenHeight;
  late final Player player;
  late final JoystickComponent joystickMove;
  late final JoystickComponent joystickAngle;

  late final TextComponent speedText;
  late final TextComponent directionText;
  late final TextComponent animationText;
  late final TextComponent ammoText;

  /// A helper for playing sound effects and background audio.
  final AudioController audioController;
  late TiledComponent mapComponent;

  // TimeManager timeManager = TimeManager();
  // DayNightManager dayNightCycle = DayNightManager();

  @override
  Color backgroundColor() => const Color(0xFFeeeeee);

  // @override
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

    await images.load('player/bullet.png');
    await images.load('effects/muzzle1.png');
    player = Player(joystickMove, joystickAngle, camera,
        position: Vector2(mapComponent.size.x / 2, mapComponent.size.y / 2));
    world.add(player);

    player.healthNotifier.addListener(() {
      if (player.healthNotifier.value <= 0) {
        pauseEngine();
      }
    });

    camera.viewport.add(joystickMove);
    camera.viewport.add(joystickAngle);

    camera.setBounds(
        Rectangle.fromLTWH(screenWidth / 2, screenHeight / 2,
            mapComponent.size.x, mapComponent.size.y),
        considerViewport: true);
    camera.follow(player, maxSpeed: 500, snap: false);

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
          top: 15 + 30,
          left: 15,
        ),
      )..add(speedText);

      final ammoWithMargin = HudMarginComponent(
        margin: const EdgeInsets.only(
          top: 60 + 30,
          left: 15,
        ),
      )..add(ammoText);

      add(FpsTextComponent(position: Vector2(15, 60), textRenderer: regular));
      camera.viewport.addAll([speedWithMargin, ammoWithMargin]);
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
    await images.load('enemies/zombie_dead_arm1.png');
    await images.load('enemies/zombie_dead_arm2.png');
    await images.load('enemies/zombie_dead_body.png');
    await images.load('enemies/zombie_dead_head.png');

    world.add(Zombie(
        position: Vector2(
            mapComponent.size.x / 2 + 200, mapComponent.size.y / 2 + 200),
        currentHealth: 100,
        maxHealth: 100));
    world.add(Zombie(
        position: Vector2(
            mapComponent.size.x / 2 + 400, mapComponent.size.y / 2 + 200),
        currentHealth: 100,
        maxHealth: 100));
    // world.add(Zombie(
    //     position: Vector2(200, 400), currentHealth: 100, maxHealth: 100));
  }

  @override
  void update(double dt) {
    super.update(dt);
    // timeManager.update(dt);

    speedText.text =
        'Speed: ${(joystickMove.intensity * player.maxSpeed).round()}';
    final direction =
        joystickMove.direction.toString().replaceAll('JoystickDirection.', '');
    directionText.text = 'Direction: $direction';
    animationText.text = 'Animation : ${(player.current)}';
    ammoText.text =
        'Munitions : ${(player.magazineAmmo.value)}/${(player.totalAmmo.value)}';
  }

  @override
  void onMount() {
    super.onMount();
    // When the world is mounted in the game we add a back button widget as an
    // overlay so that the player can go back to the previous screen.
    overlays.add(GameScreen.backButtonKey);
  }

  @override
  void onRemove() {
    overlays.remove(GameScreen.backButtonKey);
  }

  // Camera zoom
  void clampZoom() {
    camera.viewfinder.zoom = camera.viewfinder.zoom.clamp(1.0, 2.0);
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
  void onScaleStart(ScaleStartInfo info) {
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
