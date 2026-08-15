import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pregunta a Google Play si hay una versión más nueva publicada y, si el
/// usuario acepta, la descarga e instala sin salir de la app.
///
/// Es exclusivo de Android y solo responde en una copia instalada desde Play:
/// en debug, en un APK de lado o en cualquier otra plataforma el plugin lanza
/// `PlatformException`. Por eso cada método se traga el error y responde «no
/// hay nada que hacer» en vez de tumbar el arranque.
class AppUpdateService {
  const AppUpdateService();

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// `null` cuando no hay actualización, cuando ya se está instalando una o
  /// cuando la consulta no se pudo hacer.
  Future<AppUpdateInfo?> check() async {
    if (!_isSupported) return null;
    try {
      final info = await InAppUpdate.checkForUpdate();
      return info.updateAvailability == UpdateAvailability.updateAvailable
          ? info
          : null;
    } catch (_) {
      return null;
    }
  }

  /// Pantalla bloqueante de Play: descarga, instala y reinicia la app sin
  /// devolver el control. Solo se vuelve de aquí si el usuario se echa atrás
  /// (`userDeniedUpdate`) o si algo falló; `null` cuando ni se pudo lanzar.
  Future<AppUpdateResult?> installNow() async {
    if (!_isSupported) return null;
    try {
      return await InAppUpdate.performImmediateUpdate();
    } catch (_) {
      return null;
    }
  }

  /// Último recurso cuando el flujo de Play no está disponible: abrir la ficha
  /// de la tienda para que el usuario actualice a mano.
  ///
  /// `market://` la abre en la app de Play; si el dispositivo no la tiene
  /// (algunos sin servicios de Google), se cae al enlace web.
  Future<void> openStoreListing(String packageName) async {
    if (!_isSupported) return;
    try {
      final opened = await launchUrl(
        Uri.parse('market://details?id=$packageName'),
        mode: LaunchMode.externalApplication,
      );
      if (opened) return;
    } catch (_) {
      // Sigue al enlace web.
    }
    try {
      await launchUrl(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=$packageName',
        ),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Sin tienda alcanzable no queda nada por intentar.
    }
  }
}
