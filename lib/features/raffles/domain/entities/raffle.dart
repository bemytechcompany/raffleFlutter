import 'package:raffle/features/raffles/domain/entities/ticket.dart';

class Raffle {
  final int? id;
  final String name;
  final String lotteryNumber;

  /// Precio del boleto en unidades mínimas (centavos).
  ///
  /// Entero a propósito: el resumen financiero multiplica este valor por miles
  /// de boletos y con `double` el resultado acumularía error.
  final int priceMinor;

  final int totalTickets;
  final String status; // 'active' | 'inactive' | 'expired'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime date;
  final String? imagePath;
  final List<Ticket>? tickets;
  final String gameType; // 'app' | 'lottery'
  final int digitCount; // 2, 3 o 4 dígitos
  final String? winningNumber;

  /// Momento en que se envió a la papelera. `null` si está activa.
  final DateTime? deletedAt;

  const Raffle({
    this.id,
    required this.name,
    required this.lotteryNumber,
    required this.priceMinor,
    required this.totalTickets,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.date,
    this.imagePath,
    this.tickets,
    required this.gameType,
    required this.digitCount,
    this.winningNumber,
    this.deletedAt,
  });

  bool get isInTrash => deletedAt != null;

  /// La rifa ya tiene número ganador.
  ///
  /// Se comprueba también que no sea cadena vacía porque el reinicio antiguo
  /// guardaba `''` en vez de `NULL` y esas filas siguen en las bases ya
  /// creadas.
  bool get hasWinner => winningNumber != null && winningNumber!.isNotEmpty;

  /// No se pueden vender ni reservar boletos.
  ///
  /// Manda el estado, pero un ganador ya sorteado cierra la rifa aunque el
  /// estado siga en `active`: es el caso de las rifas de lotería, donde el
  /// número se fija a mano y nadie cambia el estado después.
  bool get isLocked => status != 'active' || hasWinner;

  /// Importe total si se vendieran todos los boletos, en unidades mínimas.
  int get goalMinor => priceMinor * totalTickets;

  Raffle copyWith({
    int? id,
    String? name,
    String? lotteryNumber,
    int? priceMinor,
    int? totalTickets,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? date,
    String? imagePath,
    List<Ticket>? tickets,
    String? gameType,
    int? digitCount,
    String? winningNumber,
    DateTime? deletedAt,
  }) {
    return Raffle(
      id: id ?? this.id,
      name: name ?? this.name,
      lotteryNumber: lotteryNumber ?? this.lotteryNumber,
      priceMinor: priceMinor ?? this.priceMinor,
      totalTickets: totalTickets ?? this.totalTickets,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      tickets: tickets ?? this.tickets,
      gameType: gameType ?? this.gameType,
      digitCount: digitCount ?? this.digitCount,
      winningNumber: winningNumber ?? this.winningNumber,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
