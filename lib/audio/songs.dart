const List<Song> songs = [
  Song('main_menu.mp3', 'Fear and Horror', artist: 'stratkat'),
];

class Song {
  final String filename;
  final String name;
  final String? artist;
  const Song(this.filename, this.name, {this.artist});

  @override
  String toString() => 'Song<$filename>';
}
