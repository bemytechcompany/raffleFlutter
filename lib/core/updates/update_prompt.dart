import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import 'app_update_service.dart';

/// Obliga a actualizar cuando Play anuncia una versión más nueva.
///
/// El aviso no se puede descartar: no lleva botón de «ahora no», ignora el
/// toque fuera del diálogo y bloquea el gesto de volver. La única salida es
/// actualizar, para que nadie se quede en una versión vieja.
///
/// Dos escapes deliberados, sin los cuales la app quedaría inservible por algo
/// ajeno al usuario:
///  - Si la consulta a Play falla (sin conexión, copia no instalada desde la
///    tienda, otra plataforma), `check()` responde `null` y no se muestra nada.
///  - Si el flujo de actualización de Play no arranca o revienta, se manda al
///    usuario a la ficha de la tienda y se le devuelve la app; el siguiente
///    arranque volverá a insistir.
///
/// Ojo con el alcance: esto lo ejecuta la versión ya instalada en el teléfono,
/// así que solo lo verán quienes tengan esta versión o una posterior. A quien
/// siga en una anterior lo actualiza Play por su cuenta.
Future<void> maybePromptForUpdate(
  BuildContext context, {
  AppUpdateService service = const AppUpdateService(),
}) async {
  final info = await service.check();
  if (info == null) return;

  while (true) {
    if (!context.mounted) return;
    await _showBlockingNotice(context);

    // Sin flujo inmediato disponible solo queda la ficha de la tienda.
    if (!info.immediateUpdateAllowed) {
      await service.openStoreListing(info.packageName);
      return;
    }

    final result = await service.installNow();

    // Con `success` Play ya reinició la app y no se llega hasta aquí; se
    // contempla por si el control vuelve igualmente.
    if (result == AppUpdateResult.success) return;

    // Echarse atrás en la pantalla de Play repite el aviso. Cualquier otro
    // desenlace es un fallo del flujo, no una negativa: ahí se abre la tienda
    // en vez de dejar al usuario encerrado en un bucle que no puede resolver.
    if (result != AppUpdateResult.userDeniedUpdate) {
      await service.openStoreListing(info.packageName);
      return;
    }
  }
}

Future<void> _showBlockingNotice(BuildContext context) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Actualización necesaria'),
          content: const Text(
            'Hay una versión nueva de la app. Actualiza para continuar y '
            'tener los últimos cambios.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
