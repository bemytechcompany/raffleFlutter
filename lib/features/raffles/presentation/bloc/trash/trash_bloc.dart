import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:raffle/core/pagination/paged.dart';
import '../../../domain/entities/raffle_summary.dart';
import '../../../domain/repositories/raffle_repository.dart';

part 'trash_event.dart';
part 'trash_state.dart';

/// Cuánto se conserva una rifa en la papelera antes de borrarse sola.
const Duration trashRetention = Duration(days: 30);

/// Estado de la papelera.
///
/// Va aparte de `RaffleBloc` porque las dos pestañas viven a la vez dentro del
/// `IndexedStack`: si compartieran bloc, abrir la papelera borraría el estado
/// del listado y viceversa.
class TrashBloc extends Bloc<TrashEvent, TrashState> {
  final RaffleRepository repository;

  int _page = 0;

  TrashBloc(this.repository) : super(TrashLoading()) {
    on<LoadTrash>((event, emit) async {
      _page = event.page ?? _page;
      if (state is! TrashLoaded) emit(TrashLoading());
      await _emitPage(emit);
    });

    on<RestoreRaffleFromTrash>((event, emit) async {
      await _mutate(emit, () => repository.restoreFromTrash(event.raffleId));
    });

    on<DeleteRaffleForever>((event, emit) async {
      await _mutate(emit, () => repository.deleteForever(event.raffleId));
    });

    on<EmptyTrash>((event, emit) async {
      await _mutate(emit, repository.emptyTrash);
    });

    on<PurgeExpiredTrash>(_onPurgeExpired);
  }

  /// Limpieza de arranque.
  ///
  /// No emite error si falla: es mantenimiento en segundo plano y no debe
  /// romper la pantalla. Tampoco publica una página si nadie ha abierto aún la
  /// papelera, para no pisar el estado inicial.
  Future<void> _onPurgeExpired(
    PurgeExpiredTrash event,
    Emitter<TrashState> emit,
  ) async {
    try {
      final purged = await repository.purgeTrashOlderThan(trashRetention);
      if (purged > 0 && state is TrashLoaded) {
        await _emitPage(emit);
      }
    } catch (_) {
      // Si la purga falla, la papelera simplemente conserva las rifas.
    }
  }

  Future<void> _mutate(
    Emitter<TrashState> emit,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      await _emitPage(emit);
    } catch (e) {
      emit(TrashError(e.toString()));
    }
  }

  Future<void> _emitPage(Emitter<TrashState> emit) async {
    try {
      final page = await repository.getTrashedRaffles(page: _page);
      // El repositorio ajusta la página si quedó fuera de rango al borrar.
      _page = page.page;
      emit(TrashLoaded(page));
    } catch (e) {
      emit(TrashError(e.toString()));
    }
  }
}
