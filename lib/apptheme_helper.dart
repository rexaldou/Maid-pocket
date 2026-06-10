import "package:flutter/material.dart";

class Temapp {

  static Color getBgColor(bool isDarkMode) => 
      isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);

  static Color getTextColor(bool isDarkMode) => 
      isDarkMode ? Colors.white : Colors.black87;

  static Color getCardColor(bool isDarkMode) => 
      isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

  static int getStatus(double saldo, double lKuning, double lHijau) {
    if (saldo <= 0) return 0; // Merah
    if (saldo <= lKuning) return 1; // Kuning
    if (saldo <= lHijau) return 2; // Hijau
    return 3; // Biru
  }

  static String getQuotes(int status) {
    if (status == 0) return "Uhee~ dompetnya kering banget... 😭";
    if (status == 1) return "Hati-hati kamu, saldo menipis! ⚠️";
    if (status == 2) return "Aman terkendali, Jangan boros! 🌿";
    return "Widih kaya nich,bagi dong~";
  }

  static IconData getQuoteIcon(int status) {
    if (status == 0) return Icons.error_outline;
    if (status == 1) return Icons.warning_amber_rounded;
    if (status == 2) return Icons.eco_outlined;
    return Icons.diamond_outlined;
  }

  static List<Color> getAdaptiveGradient(int status, int tema, bool isDarkMode) {
    if (isDarkMode) {
      if (tema == 0) {
        return [
          [const Color(0xFFFF5252), const Color(0xFFD50000)],
          [const Color(0xFFFFD740), const Color(0xFFFFAB00)],
          [const Color(0xFF69F0AE), const Color(0xFF00E676)],
          [const Color(0xFF40C4FF), const Color(0xFF0091EA)],
        ][status];
      }
      if (tema == 1) {
        return [
          [const Color(0xFF4A148C), const Color(0xFF311B92)],
          [const Color(0xFF880E4F), const Color(0xFF4A148C)],
          [const Color(0xFFC2185B), const Color(0xFF7B1FA2)],
          [const Color(0xFFFF4081), const Color(0xFFE040FB)],
        ][status];
      }
      if (tema == 2) {
        return [
          [const Color(0xFF00102A), const Color(0xFF001F4D)],
          [const Color(0xFF003C8F), const Color(0xFF005CB2)],
          [const Color(0xFF1976D2), const Color(0xFF1E88E5)],
          [const Color(0xFF448AFF), const Color(0xFF40C4FF)],
        ][status];
      }
      if (tema == 3) {
        return [
          [const Color(0xFF3E2723), const Color(0xFF4E342E)],
          [const Color(0xFFBF360C), const Color(0xFFD84315)],
          [const Color(0xFFE64A19), const Color(0xFFF4511E)],
          [const Color(0xFFFF6D00), const Color(0xFFFF9100)],
        ][status];
      }
      if (tema == 4) {
        return [
          [const Color(0xFF1B5E20), const Color(0xFF004D40)],
          [const Color(0xFF2E7D32), const Color(0xFF00695C)],
          [const Color(0xFF43A047), const Color(0xFF00897B)],
          [const Color(0xFF00E676), const Color(0xFF1DE9B6)],
        ][status];
      }
      if (tema == 5) {
        return [
          [const Color(0xFF1A237E), const Color(0xFF12185B)],
          [const Color(0xFF311B92), const Color(0xFF1A237E)],
          [const Color(0xFF5E35B1), const Color(0xFF3949AB)],
          [const Color(0xFFAA00FF), const Color(0xFF536DFE)],
        ][status];
      }
    } else {
      if (tema == 0) {
        return [
          [Colors.red.shade300, Colors.red.shade600],
          [Colors.orange.shade300, Colors.orange.shade600],
          [Colors.green.shade400, Colors.green.shade600],
          [Colors.blue.shade300, Colors.blue.shade600],
        ][status];
      }
      if (tema == 1) {
        return [
          [Colors.pink.shade900, Colors.purple.shade900],
          [Colors.pink.shade700, Colors.purple.shade700],
          [Colors.pink.shade400, Colors.purple.shade400],
          [Colors.pinkAccent.shade100, Colors.purpleAccent.shade100],
        ][status];
      }
      if (tema == 2) {
        return [
          [Colors.indigo.shade900, Colors.blue.shade900],
          [Colors.indigo.shade600, Colors.blue.shade700],
          [Colors.blue.shade400, Colors.cyan.shade600],
          [Colors.lightBlueAccent.shade100, Colors.cyanAccent.shade200],
        ][status];
      }
      if (tema == 3) {
        return [
          [Colors.brown.shade800, Colors.deepOrange.shade900],
          [Colors.deepOrange.shade600, Colors.orange.shade700],
          [Colors.orange.shade400, Colors.amber.shade600],
          [Colors.amberAccent.shade200, Colors.yellowAccent.shade200],
        ][status];
      }
      if (tema == 4) {
        return [
          [Colors.green.shade900, Colors.teal.shade900],
          [Colors.green.shade700, Colors.teal.shade700],
          [Colors.green.shade400, Colors.teal.shade400],
          [Colors.lightGreenAccent.shade200, Colors.tealAccent.shade200],
        ][status];
      }
      if (tema == 5) {
        return [
          [Colors.deepPurple.shade900, Colors.indigo.shade900],
          [Colors.deepPurple.shade600, Colors.indigo.shade700],
          [Colors.purple.shade400, Colors.deepPurple.shade400],
          [Colors.purpleAccent.shade100, Colors.deepPurpleAccent.shade100],
        ][status];
      }
    }
    return [Colors.grey, Colors.blueGrey];
  }
}