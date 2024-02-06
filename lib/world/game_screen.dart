import 'package:endless_runner/world/game_main.dart';

import '../audio/audio_controller.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nes_ui/nes_ui.dart';

/// This widget defines the properties of the game screen.
///
/// It mostly sets up the overlays (widgets shown on top of the Flame game) and
/// the gets the [AudioController] from the context and passes it in to the
/// [World] class so that it can play audio.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  static const String winDialogKey = 'win_dialog';
  static const String backButtonKey = 'back_buttton';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<GameMain>(
        key: const Key('play session'),
        game: GameMain(),
        overlayBuilderMap: {
          backButtonKey: (BuildContext context, GameMain game) {
            return Positioned(
              top: 20,
              right: 10,
              child: NesButton(
                type: NesButtonType.normal,
                onPressed: GoRouter.of(context).pop,
                child: NesIcon(iconData: NesIcons.leftArrowIndicator),
              ),
            );
          },
        },
      ),
    );
  }
}
