import 'package:equatable/equatable.dart';
import '../../domain/entities/ticket.dart';

abstract class RaffleEvent extends Equatable {
  const RaffleEvent();

  @override
  List<Object?> get props => [];
}

class LoadRaffles extends RaffleEvent {}

class DeleteRaffle extends RaffleEvent {
  final int raffleId;

  const DeleteRaffle(this.raffleId);

  @override
  List<Object?> get props => [raffleId];
}

class CreateRaffle extends RaffleEvent {
  final String name;
  final String lotteryNumber;
  final double price;
  final int totalTickets;
  final DateTime drawDate;
  final String? imagePath;
  final String gameType;
  final int digitCount;

  const CreateRaffle({
    required this.name,
    required this.lotteryNumber,
    required this.price,
    required this.totalTickets,
    required this.drawDate,
    this.imagePath,
    required this.gameType,
    required this.digitCount,
  });

  @override
  List<Object?> get props => [
        name,
        lotteryNumber,
        price,
        totalTickets,
        drawDate,
        imagePath,
        gameType,
        digitCount,
      ];
}

class UpdateTicketEvent extends RaffleEvent {
  final Ticket ticket;

  const UpdateTicketEvent(this.ticket);

  @override
  List<Object?> get props => [ticket];
}

class UpdateRaffleStatusEvent extends RaffleEvent {
  final int raffleId;
  final String newStatus;

  const UpdateRaffleStatusEvent({
    required this.raffleId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [raffleId, newStatus];
}

class UpdateRaffle extends RaffleEvent {
  final int raffleId;
  final String name;
  final String lotteryNumber;
  final double price;
  final DateTime drawDate;
  final String? imagePath;

  const UpdateRaffle({
    required this.raffleId,
    required this.name,
    required this.lotteryNumber,
    required this.price,
    required this.drawDate,
    this.imagePath,
  });

  @override
  List<Object?> get props => [
        raffleId,
        name,
        lotteryNumber,
        price,
        drawDate,
        imagePath,
      ];
}
