import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';

/// Quién hace la app y dónde están sus términos legales.
///
/// Las tiendas exigen que la política de privacidad se pueda abrir desde
/// dentro de la app, no solo desde la ficha de la tienda, así que esta
/// pantalla cuelga del menú principal y no de un ajuste escondido.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _privacyUrl = 'https://bemytech.io/privacy-policy';
  static const String _termsUrl = 'https://bemytech.io/terms';
  static const String _siteUrl = 'https://bemytech.io';

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(url);

    // `externalApplication` para que salga al navegador del sistema: dentro de
    // una webview embebida el usuario no ve la barra de direcciones y no puede
    // comprobar que el dominio es el nuestro.
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo abrir $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          Center(
            child: Image.asset(
              'assets/images/logo_bemytech.png',
              width: 200,
              // Si el asset no llegara al bundle, mejor un hueco discreto que
              // una excepción de render en la pantalla legal.
              errorBuilder: (_, __, ___) => const SizedBox(height: 8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Rifas y Sorteos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Desarrollada por BeMyTech',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 32),
          _LinkTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Política de privacidad',
            onTap: () => _open(context, _privacyUrl),
          ),
          const SizedBox(height: 12),
          _LinkTile(
            icon: Icons.description_outlined,
            label: 'Términos y condiciones',
            onTap: () => _open(context, _termsUrl),
          ),
          const SizedBox(height: 12),
          _LinkTile(
            icon: Icons.language,
            label: 'bemytech.io',
            onTap: () => _open(context, _siteUrl),
          ),
          const SizedBox(height: 32),
          const Text(
            'Los datos de tus rifas y sorteos se guardan solo en este '
            'dispositivo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(color: AppColors.text)),
        trailing: const Icon(Icons.open_in_new, size: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
