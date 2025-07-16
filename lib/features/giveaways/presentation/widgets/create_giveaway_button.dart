import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../pages/giveaway_create_page.dart';

class CreateGiveawayButton extends StatelessWidget {
  const CreateGiveawayButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      foregroundColor: AppColors.buttonGreenForeground,
      backgroundColor: AppColors.buttonGreenBackground,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GiveawayCreatePage()),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Nuevo sorteo'),
    );
  }
}
