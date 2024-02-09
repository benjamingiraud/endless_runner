import 'package:flutter/material.dart';

class DayNightManager {
  Color getBackgroundColor(double currentTime) {
    // Utilisez currentTime (valeur entre 0.0 et 1.0) pour déterminer le dégradé de couleur
    const startColor = Color.fromARGB(0, 0, 0, 0); // Couleur du jour
    const endColor = Color.fromARGB(50, 0, 0, 0); // Couleur de la nuit

    // Interpolation linéaire entre les couleurs de début et de fin en fonction du temps
    final interpolatedColor = Color.lerp(startColor, endColor, currentTime);

    return interpolatedColor ??
        Colors
            .black; // Utilisez la couleur interpolée ou la couleur de la nuit par défaut
  }
}
