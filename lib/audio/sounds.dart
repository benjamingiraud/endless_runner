List<String> soundTypeToFilename(SfxType type) {
  switch (type) {
    case SfxType.hit:
      return const [
        'hitmarker.mp3',
      ];
    case SfxType.playerDamage:
      return const [
        'male_hurt.mp3',
      ];
    case SfxType.zombieHasTarget:
      return const [
        'growling_zombie.mp3',
      ];
    case SfxType.buttonTap:
      return const [
        'click1.mp3',
        'click2.mp3',
        'click3.mp3',
        'click4.mp3',
      ];
  }
}

/// Allows control over loudness of different SFX types.
double soundTypeToVolume(SfxType type) {
  switch (type) {
    case SfxType.playerDamage:
    case SfxType.zombieHasTarget:
    case SfxType.hit:
      return 0.4;
    case SfxType.buttonTap:
      return 1.0;
  }
}

enum SfxType { hit, buttonTap, playerDamage, zombieHasTarget }
