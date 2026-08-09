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

  /// Se enumeran los campos que la pantalla pinta, no solo `updatedAt`.
  ///
  /// `Raffle` no es `Equatable`, así que la igualdad tenía que apoyarse en la
  /// marca de tiempo: si dos lecturas la traían igual, el bloc daba el estado
  /// por repetido y se saltaba la emisión, dejando la cabecera con el ganador
  /// viejo. Ahora un cambio de estado o de ganador se nota por sí solo.
  @override
  List<Object?> get props => [
        raffle.id,
        raffle.name,
        raffle.status,
        raffle.winningNumber,
        raffle.imagePath,
        raffle.updatedAt,
        counts,
        buyers,
      ];
}
