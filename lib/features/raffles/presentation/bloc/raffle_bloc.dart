import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/features/raffles/domain/entities/ticket.dart';
import 'package:raffle/features/raffles/domain/repositories/raffle_repository.dart';

import 'raffle_event.dart';
import 'raffle_state.dart';

/// Espera entre pulsaciones antes de consultar la base al buscar.
const _searchDebounce = Duration(milliseconds: 300);

class RaffleBloc extends Bloc<RaffleEvent, RaffleState> {
  final RaffleRepository repository;

  /// Filtros vigentes. Viven aquí y no solo en el estado para poder repetirlos
  /// cuando una escritura obliga a recargar la página.
  String _search = '';
  String _status = 'all';
  int _page = 0;

  RaffleBloc(this.repository) : super(RaffleLoading()) {
    on<LoadRaffles>(_onLoad);

    // Cada tecla cancela la consulta anterior: sin esto, escribir "navidad"
    // lanzaría siete consultas y podrían llegar desordenadas.
    on<SearchRaffles>(
      _onSearch,
      transformer: (events, mapper) =>
          events.debounce(_searchDebounce).switchMap(mapper),
    );

    on<FilterRafflesByStatus>(_onFilterByStatus);
    on<ChangeRafflePage>(_onChangePage);
    on<CreateRaffle>(_onCreate);
    on<MoveRaffleToTrash>(_onMoveToTrash);
    on<RestoreRaffle>(_onRestore);
    on<UpdateRaffleStatusEvent>(_onUpdateStatus);
    on<UpdateRaffle>(_onUpdate, transformer: droppable());
    on<UpdateTicketEvent>(_onUpdateTicket);
  }

  Future<void> _onLoad(LoadRaffles event, Emitter<RaffleState> emit) async {
    _search = event.search ?? _search;
    _status = event.status ?? _status;
    _page = event.page ?? _page;

    if (state is! RaffleLoaded) emit(RaffleLoading());
    await _emitPage(emit);
  }

  Future<void> _onSearch(
      SearchRaffles event, Emitter<RaffleState> emit) async {
    _search = event.query;
    _page = 0; // un filtro nuevo siempre vuelve a la primera página
    await _emitPage(emit);
  }

  Future<void> _onFilterByStatus(
      FilterRafflesByStatus event, Emitter<RaffleState> emit) async {
    _status = event.status;
    _page = 0;
    await _emitPage(emit);
  }

  Future<void> _onChangePage(
      ChangeRafflePage event, Emitter<RaffleState> emit) async {
    _page = event.page;
    await _emitPage(emit);
  }

  Future<void> _onCreate(CreateRaffle event, Emitter<RaffleState> emit) async {
    try {
      final now = DateTime.now();
      final raffle = Raffle(
        id: null,
        name: event.name,
        lotteryNumber: event.lotteryNumber,
        priceMinor: event.priceMinor,
        totalTickets: event.totalTickets,
        status: 'active',
        createdAt: now,
        updatedAt: now,
        date: event.drawDate,
        imagePath: event.imagePath,
        gameType: event.gameType,
        digitCount: event.digitCount,
      );

      // Los números se guardan como enteros: la lotería empieza en 0 (00, 01…)
      // y el sorteo en la app en 1. El relleno con ceros lo aplica la interfaz
      // según `digitCount`.
      final tickets = List.generate(event.totalTickets, (i) {
        return Ticket(
          id: null,
          raffleId: 0, // lo asigna el repositorio dentro de la transacción
          number: event.gameType == 'lottery' ? i : i + 1,
          status: 'available',
        );
      });

      await repository.createRaffleWithTickets(raffle, tickets);

      // La rifa nueva es la más reciente: vuelve a la primera página para que
      // se vea.
      _page = 0;
      await _emitPage(emit);
    } catch (e) {
      emit(RaffleError(message: e.toString()));
    }
  }

  Future<void> _onMoveToTrash(
      MoveRaffleToTrash event, Emitter<RaffleState> emit) {
    return _mutate(emit, () => repository.moveToTrash(event.raffleId));
  }

  Future<void> _onRestore(RestoreRaffle event, Emitter<RaffleState> emit) {
    return _mutate(emit, () => repository.restoreFromTrash(event.raffleId));
  }

  Future<void> _onUpdateStatus(
      UpdateRaffleStatusEvent event, Emitter<RaffleState> emit) {
    return _mutate(
      emit,
      () => repository.updateRaffleStatus(event.raffleId, event.newStatus),
    );
  }

  Future<void> _onUpdateTicket(
      UpdateTicketEvent event, Emitter<RaffleState> emit) {
    return _mutate(emit, () => repository.updateTicket(event.ticket));
  }

  Future<void> _onUpdate(UpdateRaffle event, Emitter<RaffleState> emit) async {
    final current = state;
    if (current is! RaffleLoaded) return;

    final match = current.page.items
        .where((summary) => summary.raffle.id == event.raffleId)
        .toList();
    if (match.isEmpty) {
      emit(const RaffleError(message: 'La rifa ya no existe.'));
      return;
    }

    final updated = match.first.raffle.copyWith(
      name: event.name,
      lotteryNumber: event.lotteryNumber,
      priceMinor: event.priceMinor,
      date: event.drawDate,
      imagePath: event.imagePath,
      updatedAt: DateTime.now(),
    );

    await _mutate(emit, () => repository.updateRaffle(updated));
  }

  /// Ejecuta un cambio y vuelve a publicar la página actual.
  ///
  /// No emite `RaffleLoading` para que la lista no parpadee en cada edición.
  Future<void> _mutate(
    Emitter<RaffleState> emit,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      await _emitPage(emit);
    } catch (e) {
      emit(RaffleError(message: e.toString()));
    }
  }

  Future<void> _emitPage(Emitter<RaffleState> emit) async {
    try {
      final page = await repository.getRaffleSummaries(
        search: _search,
        status: _status,
        page: _page,
      );

      // El repositorio ajusta la página si quedó fuera de rango.
      _page = page.page;

      emit(RaffleLoaded(page: page, search: _search, status: _status));
    } catch (e) {
      emit(RaffleError(message: e.toString()));
    }
  }
}
