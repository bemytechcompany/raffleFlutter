import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/giveaway.dart';
import '../bloc/giveaway_bloc.dart';
import '../../../../core/theme/app_colors.dart';

class UpdateGiveawayStatusButton extends StatelessWidget {
  final Giveaway giveaway;

  const UpdateGiveawayStatusButton({super.key, required this.giveaway});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle),
          label: const Text('Marcar como Completado'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonGreenBackground,
            foregroundColor: AppColors.buttonGreenForeground,
            side: BorderSide(color: AppColors.buttonGreenBorder),
          ),
          onPressed: () {
            context.read<GiveawayBloc>().add(
                  UpdateGiveawayStatusEvent(
                    giveawayId: giveaway.id!,
                    newStatus: 'completed',
                  ),
                );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Giveaway marcado como completado'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.cancel),
          label: const Text('Cancelar Giveaway'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            context.read<GiveawayBloc>().add(
                  UpdateGiveawayStatusEvent(
                    giveawayId: giveaway.id!,
                    newStatus: 'cancelled',
                  ),
                );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Giveaway cancelado'),
                backgroundColor: Colors.redAccent,
              ),
            );
          },
        ),
      ],
    );
  }
}
