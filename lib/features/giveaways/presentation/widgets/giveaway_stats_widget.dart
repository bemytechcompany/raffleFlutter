import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/participant_bloc.dart';

class GiveawayStatsWidget extends StatelessWidget {
  final int giveawayId;

  const GiveawayStatsWidget({super.key, required this.giveawayId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParticipantBloc, ParticipantState>(
      builder: (context, state) {
        if (state is ParticipantLoaded) {
          final total = state.participants.length;
          // Solo los que siguen en el bombo. Contando `isPreselected` a secas,
          // el número se quedaba clavado en el inicial: los ya premiados
          // seguían sumando aunque no pudieran volver a salir.
          final preselected =
              state.participants.where((p) => p.isPendingPreselection).length;
          final winners = state.participants.where((p) => p.isWinner).length;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Participantes', total),
              _buildStatCard('Preseleccionados', preselected),
              _buildStatCard('Ganadores', winners),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatCard(String title, int value) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
