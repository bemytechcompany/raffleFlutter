import 'package:flutter/material.dart';

class AppColors {
  // Colores primarios
  static const Color primary = Colors.greenAccent;
  static const Color secondary = Colors.blueAccent;
  static const Color accent = Colors.tealAccent;
  
  // Colores de texto
  static const Color text = Colors.white;
  static const Color textBlack = Colors.black;
  static const Color textSecondary = Colors.white70;
  static const Color textHint = Colors.white54;
  static const Color textDisabled = Colors.white38;
  
  // Colores de fondo
  static const Color background = Colors.black;
  static const Color backgroundCard = Color(0xFF1e1e1e);
  static const Color backgroundModal = Color(0xFF2e2e2e);
  static const Color backgroundInput = Color(0xFF3e3e3e);
  
  // Estados de tickets/rifas
  static const Color statusSold = Color(0xFF00E676); // Verde para vendidos
  static const Color statusReserved = Color(0xFFFFD54F); // Amarillo para reservados
  static const Color statusAvailable = Color(0xFF9E9E9E); // Gris para disponibles
  
  // Estados de rifas
  static const Color raffleActive = Color(0xFF4CAF50); // Verde consistente
  static const Color raffleInactive = Colors.orange;
  static const Color raffleExpired = Colors.red;
  
  // Estados de sorteos
  static const Color giveawayCompleted = Color(0xFF4CAF50); // Verde consistente
  static const Color giveawayCancelled = Colors.red;
  static const Color giveawayPending = Colors.orange;
  
  // Colores de error y éxito
  static const Color error = Colors.redAccent;
  static const Color success = Color(0xFF4CAF50); // Verde consistente
  static const Color warning = Colors.orange;
  static const Color info = Colors.blueAccent;
  
  // Colores para premios
  static const Color awardGold = Colors.amber;
  static const Color awardSilver = Colors.grey;
  static const Color awardBronze = Colors.brown;
  static const Color awardSpecial = Colors.blueAccent;
  
  // Botones unificados - Verde Activo
  static const Color buttonGreenBackground = Colors.greenAccent; // Verde activo
  static const Color buttonGreenForeground = Colors.white; // Texto blanco
  static const Color buttonGreenBorder = Color(0xFF388E3C); // Verde más oscuro para borde
  
  // Gradientes comunes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFF9800), Color(0xFFE65100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Colores de bordes
  static const Color border = Color(0xFF424242);
  static const Color borderLight = Color(0xFF616161);
  static const Color borderFocus = primary;
  
  // Sombras
  static Color shadowLight = Colors.black.withOpacity(0.1);
  static Color shadowMedium = Colors.black.withOpacity(0.3);
  static Color shadowHeavy = Colors.black.withOpacity(0.5);
  
  // Colores con opacidad
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  static Color blackWithOpacity(double opacity) => Colors.black.withOpacity(opacity);
  static Color whiteWithOpacity(double opacity) => Colors.white.withOpacity(opacity);
}
