import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/raffle_summary.dart';
import '../bloc/raffle_bloc.dart';
import '../bloc/raffle_event.dart';
import '../bloc/trash/trash_bloc.dart';

/// Rifas enviadas a la papelera.
///
/// Antes esta pantalla solo tenía un botón que borraba la base entera. Ahora
/// lista lo que hay en la papelera y deja restaurarlo o eliminarlo de verdad.
class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<TrashBloc>().add(const LoadTrash());
    });
  }

  /// Tras restaurar hay que refrescar también el listado principal.
  void _refreshRaffleList() => context.read<RaffleBloc>().add(const LoadRaffles());

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.text,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrashBloc, TrashState>(
      builder: (context, state) {
        if (state is TrashError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }

        if (state is! TrashLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.summaries.isEmpty) {
          return const _EmptyTrash();
        }

        return Column(
          children: [
            _buildEmptyTrashBar(state.summaries.length),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.summaries.length,
                itemBuilder: (_, index) => _buildCard(state.summaries[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyTrashBar(int count) {
    final noun = count == 1 ? 'rifa' : 'rifas';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count $noun en la papelera',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              final trashBloc = context.read<TrashBloc>();
              final confirmed = await _confirm(
                title: 'Vaciar papelera',
                message: 'Se eliminarán definitivamente $count $noun y todos '
                    'sus boletos. Esta acción no se puede deshacer.',
                confirmLabel: 'Vaciar',
              );
              if (!confirmed) return;

              trashBloc.add(EmptyTrash());
            },
            icon: const Icon(Icons.delete_forever, color: AppColors.error),
            label: const Text(
              'Vaciar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(RaffleSummary summary) {
    final raffle = summary.raffle;
    final raffleId = raffle.id;
    final deletedAt = raffle.deletedAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          raffle.name,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${summary.soldCount} vendidos · ${summary.ticketCount} boletos',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (deletedAt != null)
              Text(
                'Eliminada el ${_dateFormat.format(deletedAt)}',
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: raffleId == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Restaurar',
                    icon: const Icon(Icons.restore, color: AppColors.success),
                    onPressed: () {
                      context
                          .read<TrashBloc>()
                          .add(RestoreRaffleFromTrash(raffleId));
                      _refreshRaffleList();
                    },
                  ),
                  IconButton(
                    tooltip: 'Eliminar definitivamente',
                    icon: const Icon(Icons.delete_forever,
                        color: AppColors.error),
                    onPressed: () async {
                      final trashBloc = context.read<TrashBloc>();
                      final confirmed = await _confirm(
                        title: 'Eliminar definitivamente',
                        message: '"${raffle.name}" y sus '
                            '${summary.ticketCount} boletos se borrarán para '
                            'siempre. Esta acción no se puede deshacer.',
                        confirmLabel: 'Eliminar',
                      );
                      if (!confirmed) return;

                      trashBloc.add(DeleteRaffleForever(raffleId));
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyTrash extends StatelessWidget {
  const _EmptyTrash();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, size: 64, color: AppColors.textHint),
          SizedBox(height: 16),
          Text(
            'La papelera está vacía',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Las rifas que elimines aparecerán aquí\ny podrás restaurarlas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
