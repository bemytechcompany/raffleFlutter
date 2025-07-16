import 'package:equatable/equatable.dart';
import '../../../domain/entities/ticket.dart';

abstract class RaffleDetailsEvent extends Equatable {
  const RaffleDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadRaffleDetails extends RaffleDetailsEvent {
  final int raffleId;

  const LoadRaffleDetails(this.raffleId);

  @override
  List<Object?> get props => [raffleId];
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

class EditTicket extends RaffleDetailsEvent {
  final Ticket ticket;

  const EditTicket(this.ticket);

  @override
  List<Object?> get props => [ticket];
}

class DeleteRaffle extends RaffleDetailsEvent {
  final int raffleId;

  const DeleteRaffle(this.raffleId);

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
