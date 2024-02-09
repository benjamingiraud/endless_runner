import 'package:flame/flame.dart';

class TimeManager {
  double _currentTime = 0.0;
  double _elapsedTime = 0.0;
  final double _dayNightCycleDuration = (5 * 60.0); // 5 minutes

  double get currentTime => _currentTime;

  void update(double dt) {
    _elapsedTime += dt;
    // Mise à jour de la logique du temps ici
    // Par exemple, mettre à jour la luminosité en fonction du temps
    _currentTime =
        _elapsedTime % _dayNightCycleDuration / _dayNightCycleDuration;
  }
}
