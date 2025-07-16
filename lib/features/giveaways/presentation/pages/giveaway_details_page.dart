import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/keyboard_dismissible.dart';
import '../../domain/entities/giveaway.dart';
import '../bloc/participant_bloc.dart';
import '../widgets/giveaway_description_widget.dart';
import '../widgets/giveaway_stats_widget.dart';
import '../widgets/giveaway_status_widget.dart';
import '../widgets/participant_list_widget.dart';
import '../widgets/preselect_participants_button.dart';

class GiveawayDetailsPage extends StatelessWidget {
  final Giveaway giveaway;

  const GiveawayDetailsPage({super.key, required this.giveaway});

  @override
  Widget build(BuildContext context) {
    context
        .read<ParticipantBloc>()
        .add(LoadParticipants(giveawayId: giveaway.id!));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(giveaway.name),
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showAddParticipantDialog(context),
            icon: const Icon(
              Icons.person_add,
              color: AppColors.primary,
            ),
            tooltip: 'Nuevo Participante',
          )
        ],
      ),
      body: BlocListener<ParticipantBloc, ParticipantState>(
        listener: (context, state) {
          if (state is WinnerSelected) {
            _showWinnerDialog(context, state.winner.name, state.winner.contact,
                state.winner.award);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🏆 ¡Ganador seleccionado exitosamente!'),
                backgroundColor: AppColors.buttonGreenBorder,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GiveawayDescriptionWidget(description: giveaway.description),
              const SizedBox(height: 16),
              GiveawayStatsWidget(giveawayId: giveaway.id!),
              const SizedBox(height: 16),
              GiveawayStatusWidget(giveaway: giveaway),
              const SizedBox(height: 16),
              const Text(
                "Participantes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200, width: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade50.withOpacity(0.05),
                  ),
                  child: ParticipantListWidget(giveawayId: giveaway.id!),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PreselectParticipantsButton(
                      onPreselect: (count) {
                        context.read<ParticipantBloc>().add(
                              PreselectParticipantsEvent(
                                giveawayId: giveaway.id!,
                                count: count,
                              ),
                            );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '🎯 Se preseleccionaron $count participantes'),
                            backgroundColor: Colors.blueAccent,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<ParticipantBloc>().add(
                              DrawWinnerEvent(giveawayId: giveaway.id!),
                            );
                      },
                      icon: const Icon(Icons.casino),
                      label: const Text('Sortear Ganador'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonGreenBackground,
                        foregroundColor: AppColors.buttonGreenForeground,
                        side: BorderSide(color: AppColors.buttonGreenBorder),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWinnerDialog(BuildContext context, String winnerName,
      String winnerContact, String? award) {
    String awardTitle;
    Icon awardIcon;

    switch (award?.toLowerCase()) {
      case 'oro':
        awardTitle = '🏆 Ganador de Oro';
        awardIcon =
            const Icon(Icons.emoji_events, color: Colors.amber, size: 48);
        break;
      case 'plata':
        awardTitle = '🥈 Ganador de Plata';
        awardIcon =
            const Icon(Icons.emoji_events, color: Colors.grey, size: 48);
        break;
      case 'bronce':
        awardTitle = '🥉 Ganador de Bronce';
        awardIcon =
            const Icon(Icons.emoji_events, color: Colors.brown, size: 48);
        break;
      case 'reconocimiento':
        awardTitle = '🎖️ Reconocimiento Especial';
        awardIcon = const Icon(Icons.star, color: Colors.blueAccent, size: 48);
        break;
      default:
        awardTitle = '🎉 ¡Ganador!';
        awardIcon =
            const Icon(Icons.emoji_events, color: AppColors.primary, size: 48);
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            awardIcon,
            const SizedBox(width: 10),
            Flexible(child: Text(awardTitle)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              winnerName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              winnerContact,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cerrar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showAddParticipantDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController contactController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '👤 Agregar Participante',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: KeyboardDismissible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: Colors.greenAccent.shade100.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactController,
                decoration: InputDecoration(
                  labelText: 'Contacto',
                  prefixIcon: const Icon(Icons.phone),
                  filled: true,
                  fillColor: Colors.greenAccent.shade100.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final name = nameController.text.trim();
              final contact = contactController.text.trim();

              if (name.isEmpty || contact.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        const Text('⚠️ Por favor completa todos los campos'),
                    backgroundColor: Colors.red.shade400,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else {
                context.read<ParticipantBloc>().add(
                      AddParticipantEvent(
                        giveawayId: giveaway.id!,
                        name: name,
                        contact: contact,
                      ),
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                                                    content: const Text('✅ Participante agregado exitosamente'),
                                backgroundColor: AppColors.buttonGreenBorder,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Agregar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonGreenBackground,
              foregroundColor: AppColors.buttonGreenForeground,
              side: BorderSide(color: AppColors.buttonGreenBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
