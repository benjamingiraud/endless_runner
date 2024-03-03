import 'package:provider/provider.dart';
import 'package:survival_zombie/world/game_main.dart';

import '../audio/audio_controller.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// This widget defines the properties of the game screen.
///
/// It mostly sets up the overlays (widgets shown on top of the Flame game) and
/// the gets the [AudioController] from the context and passes it in to the
/// [World] class so that it can play audio.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  static const String backButtonKey = 'back_buttton';
  static const String switchWeaponButtonKey = 'switch_button';
  static const String dashButtonKey = 'dash_button';

  @override
  Widget build(BuildContext context) {
    final audioController = context.read<AudioController>();
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return Scaffold(
      body: GameWidget<GameMain>(
        key: const Key('play session'),
        game: GameMain(
            audioController: audioController,
            screenWidth: screenWidth,
            screenHeight: screenHeight),
        overlayBuilderMap: {
          backButtonKey: (BuildContext context, GameMain game) {
            return Positioned(
              top: 10,
              left: 10,
              child: IconButton.filled(
                icon: const Icon(Icons.menu),
                color: Colors.white,
                onPressed: GoRouter.of(context).pop,
              ),
            );
          },
          switchWeaponButtonKey: (BuildContext context, GameMain game) {
            return Positioned(
              bottom: 125,
              right: 10,
              child: IconButton.filled(
                icon: const Icon(Icons.switch_access_shortcut),
                color: Colors.white,
                onPressed: game.player.switchWeapon,
              ),
            );
          },
          dashButtonKey: (BuildContext context, GameMain game) {
            return Positioned(
              bottom: 125,
              right: 65,
              child: IconButton.filled(
                icon: const Icon(Icons.move_up),
                color: Colors.white,
                onPressed: game.player.canDash() ? game.player.dash : null,
              ),
            );
          },
        },
      ),
    );
  }
}
