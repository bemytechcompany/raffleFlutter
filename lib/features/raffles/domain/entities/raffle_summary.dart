import 'package:equatable/equatable.dart';

import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/features/raffles/domain/entities/ticket_counts.dart';

/// Rifa con sus contadores de boletos ya calculados.
///
/// El listado solo necesita cuántos boletos hay en cada estado, no los boletos
/// en sí. Antes se cargaban todos en memoria para contarlos: diez rifas de
/// lotería de cuatro dígitos son cien mil objetos por abrir la pantalla. Ahora
/// los cuenta SQLite con un `GROUP BY`.
class RaffleSummary extends Equatable {
  final Raffle raffle;
  final TicketCounts counts;

  const RaffleSummary({
    required this.raffle,
    required this.counts,
  });

  int get soldCount => counts.sold;
  int get reservedCount => counts.reserved;
  int get availableCount => counts.available;
  int get ticketCount => counts.total;

  /// Dinero ya cobrado, en unidades mínimas.
  int get collectedMinor => counts.collectedMinor(raffle.priceMinor);

  /// Dinero comprometido pero no cobrado, en unidades mínimas.
  int get reservedMinor => counts.reservedMinor(raffle.priceMinor);

  /// Dinero que falta por vender, en unidades mínimas.
  int get remainingMinor => counts.remainingMinor(raffle.priceMinor);

  double get soldRatio => counts.soldRatio;
  double get reservedRatio => counts.reservedRatio;
  double get availableRatio => counts.availableRatio;

  /// Vendido más reservado: lo que se usa en la barra de progreso del listado.
  double get committedRatio => counts.committedRatio;

  @override
  List<Object?> get props => [raffle.id, raffle.updatedAt, counts];
}
