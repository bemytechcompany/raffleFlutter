import 'package:equatable/equatable.dart';

import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/features/raffles/domain/entities/ticket_counts.dart';

/// Cabecera de la pantalla de detalle: la rifa y sus contadores.
///
/// No incluye los boletos. Los pide el grid una página a la vez, porque una
/// rifa de lotería de cuatro dígitos tiene diez mil.
class RaffleDetails extends Equatable {
  final Raffle raffle;
  final TicketCounts counts;
  final BuyerCounts buyers;

  const RaffleDetails({
    required this.raffle,
    required this.counts,
    required this.buyers,
  });

  @override
  List<Object?> get props => [raffle.id, raffle.updatedAt, counts, buyers];
}
