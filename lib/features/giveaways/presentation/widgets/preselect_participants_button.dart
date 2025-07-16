import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/keyboard_dismissible.dart';

class PreselectParticipantsButton extends StatelessWidget {
  final void Function(int count) onPreselect;

  const PreselectParticipantsButton({super.key, required this.onPreselect});

  void _showPreselectDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Preseleccionar Participantes'),
        content: KeyboardDismissible(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Número a preseleccionar',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final count = int.tryParse(controller.text.trim());
              if (count != null && count > 0) {
                Navigator.pop(context);
                onPreselect(count);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonGreenBackground,
              foregroundColor: AppColors.buttonGreenForeground,
              side: BorderSide(color: AppColors.buttonGreenBorder),
            ),
            child: const Text('Preseleccionar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showPreselectDialog(context),
      icon: const Icon(Icons.how_to_reg),
      label: const Text('Preseleccionar'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonGreenBackground,
        foregroundColor: AppColors.buttonGreenForeground,
        side: BorderSide(color: AppColors.buttonGreenBorder),
      ),
    );
  }
}
