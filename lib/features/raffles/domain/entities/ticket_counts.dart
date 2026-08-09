import 'package:equatable/equatable.dart';

/// Cuántos boletos hay en cada estado.
///
/// Lo calcula SQLite con un `GROUP BY`. Existe para que ni el listado ni el
/// detalle tengan que cargar los boletos solo para contarlos: una rifa de
/// lotería de cuatro dígitos son diez mil filas.
class TicketCounts extends Equatable {
  final int available;
  final int reserved;
  final int sold;

  const TicketCounts({
    this.available = 0,
    this.reserved = 0,
    this.sold = 0,
  });

  static const TicketCounts empty = TicketCounts();

  factory TicketCounts.fromMap(Map<String, int> counts) {
    return TicketCounts(
      available: counts['available'] ?? 0,
      reserved: counts['reserved'] ?? 0,
      sold: counts['sold'] ?? 0,
    );
  }

  int get total => available + reserved + sold;

  /// Proporciones entre 0 y 1. Con cero boletos devuelven 0, nunca `NaN`:
  /// un `NaN` acabaría en un `Expanded(flex:)` y reventaría la pantalla.
  double get soldRatio => _ratio(sold);
  double get reservedRatio => _ratio(reserved);
  double get availableRatio => _ratio(available);

  /// Parte ya comprometida: vendido más reservado.
  double get committedRatio => _ratio(sold + reserved);

  double _ratio(int value) => total == 0 ? 0 : value / total;

  /// Importes en unidades mínimas, a partir del precio del boleto.
  int collectedMinor(int priceMinor) => sold * priceMinor;
  int reservedMinor(int priceMinor) => reserved * priceMinor;
  int remainingMinor(int priceMinor) => available * priceMinor;

  @override
  List<Object?> get props => [available, reserved, sold];
}

/// Cuántos boletos tienen comprador asignado en una rifa.
class BuyerCounts extends Equatable {
  final int total;
  final int sold;
  final int reserved;

  const BuyerCounts({
    this.total = 0,
    this.sold = 0,
    this.reserved = 0,
  });

  static const BuyerCounts empty = BuyerCounts();

  @override
  List<Object?> get props => [total, sold, reserved];
}
