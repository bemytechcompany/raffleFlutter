import 'package:equatable/equatable.dart';

import '../../../domain/entities/ticket.dart';

abstract class RaffleDetailsEvent extends Equatable {
  const RaffleDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Carga la cabecera (rifa y contadores) y la primera página de boletos.
class LoadRaffleDetails extends RaffleDetailsEvent {
  final int raffleId;

  const LoadRaffleDetails(this.raffleId);

  @override
  List<Object?> get props => [raffleId];
}

/// Pide otra página del grid de boletos.
class LoadTicketPage extends RaffleDetailsEvent {
  final int page;

  const LoadTicketPage(this.page);

  @override
  List<Object?> get props => [page];
}

class EditTicket extends RaffleDetailsEvent {
  final Ticket ticket;

  const EditTicket(this.ticket);

  @override
  List<Object?> get props => [ticket];
}

class ChangeRaffleStatus extends RaffleDetailsEvent {
  final int raffleId;
  final String newStatus;

  const ChangeRaffleStatus({
    required this.raffleId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [raffleId, newStatus];
}

/// Deshace el sorteo: borra el ganador y reabre la rifa.
class ResetDraw extends RaffleDetailsEvent {
  final int raffleId;

  const ResetDraw(this.raffleId);

  @override
  List<Object?> get props => [raffleId];
}

class SetWinningNumber extends RaffleDetailsEvent {
  final int raffleId;
  final String winningNumber;

  const SetWinningNumber({
    required this.raffleId,
    required this.winningNumber,
  });

  @override
  List<Object?> get props => [raffleId, winningNumber];
}
