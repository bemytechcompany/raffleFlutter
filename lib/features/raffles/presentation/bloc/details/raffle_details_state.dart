import 'package:equatable/equatable.dart';

import 'package:raffle/core/pagination/paged.dart';
import '../../../domain/entities/raffle.dart';
import '../../../domain/entities/raffle_details.dart';
import '../../../domain/entities/ticket.dart';
import '../../../domain/entities/ticket_counts.dart';

abstract class RaffleDetailsState extends Equatable {
  const RaffleDetailsState();

  @override
  List<Object?> get props => [];
}

class RaffleDetailsInitial extends RaffleDetailsState {}

class RaffleDetailsLoading extends RaffleDetailsState {}

class RaffleDetailsLoaded extends RaffleDetailsState {
  final RaffleDetails details;

  /// Solo los boletos de la página visible del grid.
  final Paged<Ticket> tickets;

  /// Hay una página de boletos cargándose; el resto de la pantalla sigue
  /// siendo válido, así que no se reemplaza por un spinner completo.
  final bool loadingTickets;

  const RaffleDetailsLoaded({
    required this.details,
    required this.tickets,
    this.loadingTickets = false,
  });

  Raffle get raffle => details.raffle;
  TicketCounts get counts => details.counts;
  BuyerCounts get buyers => details.buyers;

  RaffleDetailsLoaded copyWith({
    RaffleDetails? details,
    Paged<Ticket>? tickets,
    bool? loadingTickets,
  }) {
    return RaffleDetailsLoaded(
      details: details ?? this.details,
      tickets: tickets ?? this.tickets,
      loadingTickets: loadingTickets ?? this.loadingTickets,
    );
  }

  @override
  List<Object?> get props => [details, tickets, loadingTickets];
}

class RaffleDetailsError extends RaffleDetailsState {
  final String message;

  const RaffleDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
