import 'package:equatable/equatable.dart';
import '../../domain/entities/ticket.dart';

abstract class RaffleEvent extends Equatable {
  const RaffleEvent();

  @override
  List<Object?> get props => [];
}

/// Pide una página del listado.
///
/// Los tres parámetros son opcionales: lo que no se pase conserva el valor
/// actual, para que cambiar de página no borre la búsqueda ni al revés.
class LoadRaffles extends RaffleEvent {
  final String? search;
  final String? status;
  final int? page;

  const LoadRaffles({this.search, this.status, this.page});

  @override
  List<Object?> get props => [search, status, page];
}

/// Cambia el texto de búsqueda. El bloc lo aplica con un pequeño retardo para
/// no lanzar una consulta por cada tecla.
class SearchRaffles extends RaffleEvent {
  final String query;

  const SearchRaffles(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterRafflesByStatus extends RaffleEvent {
  final String status;

  const FilterRafflesByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class ChangeRafflePage extends RaffleEvent {
  final int page;

  const ChangeRafflePage(this.page);

  @override
  List<Object?> get props => [page];
}

/// Envía la rifa a la papelera. Se puede deshacer con [RestoreRaffle].
class MoveRaffleToTrash extends RaffleEvent {
  final int raffleId;

  const MoveRaffleToTrash(this.raffleId);

  @override
  List<Object?> get props => [raffleId];
}

class RestoreRaffle extends RaffleEvent {
  final int raffleId;

  const RestoreRaffle(this.raffleId);

  @override
  List<Object?> get props => [raffleId];
}

class CreateRaffle extends RaffleEvent {
  final String name;
  final String lotteryNumber;

  /// Precio por boleto en unidades mínimas (centavos).
  final int priceMinor;

  final int totalTickets;
  final DateTime drawDate;
  final String? imagePath;
  final String gameType;
  final int digitCount;

  const CreateRaffle({
    required this.name,
    required this.lotteryNumber,
    required this.priceMinor,
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
        priceMinor,
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

  /// Precio por boleto en unidades mínimas (centavos).
  final int priceMinor;

  final DateTime drawDate;
  final String? imagePath;

  const UpdateRaffle({
    required this.raffleId,
    required this.name,
    required this.lotteryNumber,
    required this.priceMinor,
    required this.drawDate,
    this.imagePath,
  });

  @override
  List<Object?> get props => [
        raffleId,
        name,
        lotteryNumber,
        priceMinor,
        drawDate,
        imagePath,
      ];
}
