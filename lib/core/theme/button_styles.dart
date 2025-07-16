import 'package:flutter/material.dart';
import 'app_colors.dart';

class ButtonStyles {
  // Estilo para botones verde activo (confirmación, crear, éxito)
  static ButtonStyle get greenActiveButton => ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonGreenBackground,
        foregroundColor: AppColors.buttonGreenForeground,
        side: BorderSide(color: AppColors.buttonGreenBorder),
        elevation: 2, // Añadir elevación para efecto más activo
      );

  // Estilo para botones verde activo con border radius personalizado
  static ButtonStyle greenActiveButtonWithRadius(double radius) =>
      ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonGreenBackground,
        foregroundColor: AppColors.buttonGreenForeground,
        side: BorderSide(color: AppColors.buttonGreenBorder),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  // Estilo para botones verde activo con padding personalizado
  static ButtonStyle greenActiveButtonWithPadding(EdgeInsets padding) =>
      ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonGreenBackground,
        foregroundColor: AppColors.buttonGreenForeground,
        side: BorderSide(color: AppColors.buttonGreenBorder),
        elevation: 2,
        padding: padding,
      );

  // Estilo verde activo completo personalizable
  static ButtonStyle greenActiveButtonCustom({
    double? radius,
    EdgeInsets? padding,
    double elevation = 2,
  }) =>
      ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonGreenBackground,
        foregroundColor: AppColors.buttonGreenForeground,
        side: BorderSide(color: AppColors.buttonGreenBorder),
        elevation: elevation,
        shape: radius != null
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              )
            : null,
        padding: padding,
      );
} 