import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/ticket.dart';
import '../../../domain/repositories/raffle_repository.dart';
import 'raffle_details_event.dart';
import 'raffle_details_state.dart';

/// Estado de la pantalla de detalle.
///
/// La cabecera (rifa y contadores) se calcula en SQL y los boletos se piden
/// por páginas: una rifa de lotería de cuatro dígitos tiene diez mil y
/// cargarlos todos para pintar cien era el cuello de botella de la pantalla.
class RaffleDetailsBloc extends Bloc<RaffleDetailsEvent, RaffleDetailsState> {
  final RaffleRepository repository;

  int? _raffleId;

  RaffleDetailsBloc(this.repository) : super(RaffleDetailsInitial()) {
    on<LoadRaffleDetails>(_onLoad);

    // Cambiar de página rápido no debe encolar consultas: nos quedamos con la
    // última pedida.
    on<LoadTicketPage>(_onLoadTicketPage, transformer: restartable());

    on<EditTicket>(_onEditTicket);
    on<ChangeRaffleStatus>(_onChangeStatus);
    on<SetWinningNumber>(_onSetWinningNumber);
    on<ResetDraw>(_onResetDraw);
  }

  Future<void> _onLoad(
      LoadRaffleDetails event, Emitter<RaffleDetailsState> emit) async {
    _raffleId = event.raffleId;
    emit(RaffleDetailsLoading());

    try {
      final details = await repository.getRaffleDetails(event.raffleId);
      if (details == null) {
        emit(const RaffleDetailsError('La rifa ya no existe.'));
        return;
      }

      final tickets = await repository.getTicketPage(event.raffleId);
      emit(RaffleDetailsLoaded(details: details, tickets: tickets));
    } catch (e) {
      emit(RaffleDetailsError(e.toString()));
    }
  }

  Future<void> _onLoadTicketPage(
      LoadTicketPage event, Emitter<RaffleDetailsState> emit) async {
    final current = state;
    final raffleId = _raffleId;
    if (current is! RaffleDetailsLoaded || raffleId == null) return;

    emit(current.copyWith(loadingTickets: true));

    try {
      final tickets =
          await repository.getTicketPage(raffleId, page: event.page);
      emit(current.copyWith(tickets: tickets, loadingTickets: false));
    } catch (e) {
      emit(RaffleDetailsError(e.toString()));
    }
  }

  /// Sortea el boleto ganador entre **todos** los de la rifa.
  ///
  /// Es una consulta, no una transición de estado: quien llama enseña el
  /// número y solo si se confirma dispara [SetWinningNumber]. Por eso es un
  /// método y no un evento.
  Future<Ticket?> pickWinningTicket() async {
    final raffleId = _raffleId;
    if (raffleId == null) return null;
    return repository.pickWinningTicket(raffleId);
  }

  /// Todos los boletos de la rifa.
  ///
  /// Solo para compartir y exportar, que necesitan la lista entera. El resto
  /// de la pantalla trabaja por páginas.
  Future<List<Ticket>> loadAllTickets() async {
    final raffleId = _raffleId;
    if (raffleId == null) return const [];
    return repository.getAllTickets(raffleId);
  }

  /// Solo los boletos que tienen comprador, para la lista de compradores.
  Future<List<Ticket>> loadTicketsWithBuyers() async {
    final raffleId = _raffleId;
    if (raffleId == null) return const [];
    return repository.getTicketsWithBuyers(raffleId);
  }

  Future<void> _onEditTicket(
      EditTicket event, Emitter<RaffleDetailsState> emit) async {
    await _mutate(emit, () => repository.updateTicket(event.ticket));
  }

  Future<void> _onChangeStatus(
      ChangeRaffleStatus event, Emitter<RaffleDetailsState> emit) async {
    await _mutate(
      emit,
      () => repository.updateRaffleStatus(event.raffleId, event.newStatus),
    );
  }

  Future<void> _onSetWinningNumber(
      SetWinningNumber event, Emitter<RaffleDetailsState> emit) async {
    await _mutate(
      emit,
      () => repository.setWinningNumberAndFinishRaffle(
          event.raffleId, event.winningNumber),
    );
  }

  Future<void> _onResetDraw(
      ResetDraw event, Emitter<RaffleDetailsState> emit) async {
    await _mutate(emit, () => repository.resetDraw(event.raffleId));
  }

  /// Aplica un cambio y refresca cabecera y página actual sin volver al
  /// spinner de pantalla completa.
  Future<void> _mutate(
    Emitter<RaffleDetailsState> emit,
    Future<void> Function() action,
  ) async {
    final current = state;
    final raffleId = _raffleId;

    // Antes se salía con un `return` mudo. Si el evento llegaba a un bloc sin
    // rifa cargada —por ejemplo desde un diálogo montado en el Navigator raíz,
    // que resuelve otro provider— no se escribía nada y la pantalla se quedaba
    // igual, sin pista de que el sorteo no había ocurrido.
    if (current is! RaffleDetailsLoaded || raffleId == null) {
      emit(const RaffleDetailsError(
        'No hay ninguna rifa cargada en esta pantalla.',
      ));
      return;
    }

    try {
      await action();

      final details = await repository.getRaffleDetails(raffleId);
      if (details == null) {
        emit(const RaffleDetailsError('La rifa ya no existe.'));
        return;
      }

      final tickets = await repository.getTicketPage(
        raffleId,
        page: current.tickets.page,
      );
      emit(RaffleDetailsLoaded(details: details, tickets: tickets));
    } catch (e) {
      emit(RaffleDetailsError(e.toString()));
    }
  }
}
