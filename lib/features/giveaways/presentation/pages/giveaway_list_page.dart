import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/giveaway.dart';
import '../../domain/use_cases/participant_usecases.dart';
import '../bloc/giveaway_bloc.dart';
import '../bloc/participant_bloc.dart';
import '../widgets/create_giveaway_button.dart';
import '../widgets/giveaway_card.dart';
import 'giveaway_details_page.dart';

class GiveawaysListPage extends StatefulWidget {
  const GiveawaysListPage({super.key});

  @override
  State<GiveawaysListPage> createState() => _GiveawaysListPageState();
}

class _GiveawaysListPageState extends State<GiveawaysListPage> {
  @override
  void initState() {
    super.initState();
    context.read<GiveawayBloc>().add(LoadGiveaways());
  }

  /// Pide confirmación y borra el sorteo.
  ///
  /// Los sorteos no tienen papelera como las rifas: esto es definitivo, y la
  /// clave foránea se lleva a los participantes por delante. El texto lo dice
  /// para que nadie lo descubra después.
  Future<void> _confirmDelete(Giveaway giveaway) async {
    // El bloc se resuelve antes de abrir el diálogo: `showDialog` monta en el
    // Navigator raíz y desde su context no se garantiza llegar a este provider.
    final bloc = context.read<GiveawayBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Sorteo'),
        content: Text(
          '¿Seguro que quieres eliminar "${giveaway.name}"? '
          'Se borrarán también sus participantes y no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    bloc.add(DeleteGiveawayEvent(giveaway.id!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<GiveawayBloc, GiveawayState>(
        builder: (context, state) {
          if (state is GiveawayLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GiveawayLoaded) {
            if (state.giveaways.isEmpty) {
              return const Center(child: Text('No hay sorteos todavía.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.giveaways.length,
              itemBuilder: (context, index) {
                final giveaway = state.giveaways[index];
                return GiveawayCard(
                  giveaway: giveaway,
                  onDelete: () => _confirmDelete(giveaway),
                  onTap: () {
                    // Un `ParticipantBloc` por sorteo abierto. Con uno solo
                    // global, entrar en otro sorteo mostraba los participantes
                    // del anterior hasta que respondía la consulta.
                    final useCases = context.read<ParticipantUseCases>();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) => ParticipantBloc(useCases),
                          child: GiveawayDetailsPage(giveaway: giveaway),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          } else if (state is GiveawayError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: const CreateGiveawayButton(),
    );
  }
}
