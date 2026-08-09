import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/keyboard_dismissible.dart';
import '../../domain/entities/giveaway.dart';
import '../bloc/giveaway_bloc.dart';
import '../bloc/participant_bloc.dart';
import '../widgets/giveaway_description_widget.dart';
import '../widgets/giveaway_stats_widget.dart';
import '../widgets/giveaway_status_widget.dart';
import '../widgets/participant_list_widget.dart';
import '../widgets/preselect_participants_button.dart';
import 'giveaway_edit_page.dart';

class GiveawayDetailsPage extends StatefulWidget {
  final Giveaway giveaway;

  const GiveawayDetailsPage({super.key, required this.giveaway});

  @override
  State<GiveawayDetailsPage> createState() => _GiveawayDetailsPageState();
}

class _GiveawayDetailsPageState extends State<GiveawayDetailsPage> {
  /// Copia local del sorteo, para reflejar una edición sin salir de la
  /// pantalla.
  late Giveaway _giveaway;

  int get _giveawayId => _giveaway.id!;

  @override
  void initState() {
    super.initState();
    _giveaway = widget.giveaway;
    // La carga va aquí y no en `build`: dentro de `build` se relanzaba en cada
    // repintado —y cada respuesta provocaba otro repintado—, así que la
    // pantalla se pasaba la vida recargando participantes.
    context
        .read<ParticipantBloc>()
        .add(LoadParticipants(giveawayId: _giveawayId));
  }

  Future<void> _openEditPage() async {
    final updated = await Navigator.of(context).push<Giveaway>(
      MaterialPageRoute(
        builder: (_) => GiveawayEditPage(giveaway: _giveaway),
      ),
    );
    if (updated != null && mounted) setState(() => _giveaway = updated);
  }

  /// Pide confirmación y deshace el sorteo.
  ///
  /// El bloc se resuelve antes de abrir el diálogo: `showDialog` monta en el
  /// Navigator raíz, que no desciende del `BlocProvider` de esta ruta.
  Future<void> _confirmReset() async {
    final bloc = context.read<ParticipantBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reiniciar Sorteo'),
        content: const Text(
          'Se borrarán los ganadores, los premios y la preselección. '
          'Los participantes se conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    bloc.add(ResetGiveawayDrawEvent(giveawayId: _giveawayId));
    _reloadGiveaways();
  }

  /// El estado del sorteo lo mueve la propia transacción del sorteo, no el
  /// `GiveawayBloc`, así que hay que pedirle que relea o la tarjeta de estado
  /// se queda en "Pendiente" con el ganador ya elegido.
  void _reloadGiveaways() {
    if (!mounted) return;
    context.read<GiveawayBloc>().add(LoadGiveaways());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_giveaway.name),
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _openEditPage,
            icon: const Icon(Icons.edit, color: AppColors.primary),
            tooltip: 'Editar Sorteo',
          ),
          IconButton(
            onPressed: () => _showAddParticipantDialog(context),
            icon: const Icon(
              Icons.person_add,
              color: AppColors.primary,
            ),
            tooltip: 'Nuevo Participante',
          ),
        ],
      ),
      body: BlocConsumer<ParticipantBloc, ParticipantState>(
        listener: (context, state) {
          if (state is WinnerSelected) {
            _reloadGiveaways();
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
        builder: (context, state) {
          // El reinicio solo tiene sentido cuando hay algo que deshacer.
          final hasResult = state is ParticipantLoaded &&
              state.participants.any((p) => p.isWinner || p.isPreselected);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GiveawayDescriptionWidget(description: _giveaway.description),
                const SizedBox(height: 16),
                GiveawayStatsWidget(giveawayId: _giveawayId),
                const SizedBox(height: 16),
                GiveawayStatusWidget(giveaway: _giveaway),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Participantes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (hasResult)
                      TextButton.icon(
                        onPressed: _confirmReset,
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: const Text('Reiniciar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Colors.grey.shade200, width: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade50.withValues(alpha: 0.05),
                    ),
                    child: ParticipantListWidget(giveawayId: _giveawayId),
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
                                  giveawayId: _giveawayId,
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
                                DrawWinnerEvent(giveawayId: _giveawayId),
                              );
                        },
                        icon: const Icon(Icons.casino),
                        label: const Text('Sortear Ganador'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonGreenBackground,
                          foregroundColor: AppColors.buttonGreenForeground,
                          side: const BorderSide(
                              color: AppColors.buttonGreenBorder),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
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
    // Igual que en el reinicio: el diálogo vive en el Navigator raíz y desde
    // ahí no se llega al bloc de esta ruta.
    final bloc = context.read<ParticipantBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
                  fillColor: Colors.greenAccent.shade100.withValues(alpha: 0.3),
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
                  fillColor: Colors.greenAccent.shade100.withValues(alpha: 0.3),
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
            onPressed: () => Navigator.pop(dialogContext),
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
                bloc.add(
                  AddParticipantEvent(
                    giveawayId: _giveawayId,
                    name: name,
                    contact: contact,
                  ),
                );
                Navigator.pop(dialogContext);
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
              side: const BorderSide(color: AppColors.buttonGreenBorder),
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
