import 'package:raffle/core/db/app_database.dart';
import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/features/raffles/domain/entities/ticket.dart';

/// Traducción entre la tabla `raffles` y la entidad [Raffle].
class RaffleModel extends Raffle {
  const RaffleModel({
    required super.id,
    required super.name,
    required super.lotteryNumber,
    required super.priceMinor,
    required super.totalTickets,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    required super.date,
    super.imagePath,
    super.tickets,
    required super.gameType,
    required super.digitCount,
    super.winningNumber,
    super.deletedAt,
  });

  factory RaffleModel.fromMap(Map<String, dynamic> map) {
    return RaffleModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      lotteryNumber: (map['lottery_number'] as String?) ?? '',
      priceMinor: map['price_minor'] as int,
      totalTickets: map['total_tickets'] as int,
      status: map['status'] as String,
      createdAt: parseDbDate(map['created_at'] as String),
      updatedAt: parseDbDate(map['updated_at'] as String),
      date: parseDbDate(map['draw_date'] as String),
      imagePath: map['image_path'] as String?,
      gameType: map['game_type'] as String,
      digitCount: map['digit_count'] as int,
      winningNumber: map['winning_number'] as String?,
      deletedAt: parseDbDateOrNull(map['deleted_at']),
    );
  }

  factory RaffleModel.fromEntity(Raffle raffle) {
    return RaffleModel(
      id: raffle.id,
      name: raffle.name,
      lotteryNumber: raffle.lotteryNumber,
      priceMinor: raffle.priceMinor,
      totalTickets: raffle.totalTickets,
      status: raffle.status,
      createdAt: raffle.createdAt,
      updatedAt: raffle.updatedAt,
      date: raffle.date,
      imagePath: raffle.imagePath,
      tickets: raffle.tickets,
      gameType: raffle.gameType,
      digitCount: raffle.digitCount,
      winningNumber: raffle.winningNumber,
      deletedAt: raffle.deletedAt,
    );
  }

  /// Columnas para `insert`/`update`. Sin `id`: lo asigna SQLite.
  Map<String, dynamic> toColumns() {
    return {
      'name': name,
      'lottery_number': lotteryNumber,
      'price_minor': priceMinor,
      'total_tickets': totalTickets,
      'status': status,
      'game_type': gameType,
      'digit_count': digitCount,
      'winning_number': winningNumber,
      'image_path': imagePath,
      'draw_date': date.toDbString(),
      'created_at': createdAt.toDbString(),
      'updated_at': updatedAt.toDbString(),
      'deleted_at': deletedAt?.toDbString(),
    };
  }

  Raffle toEntity({List<Ticket>? tickets}) {
    return Raffle(
      id: id,
      name: name,
      lotteryNumber: lotteryNumber,
      priceMinor: priceMinor,
      totalTickets: totalTickets,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      date: date,
      imagePath: imagePath,
      tickets: tickets ?? this.tickets,
      gameType: gameType,
      digitCount: digitCount,
      winningNumber: winningNumber,
      deletedAt: deletedAt,
    );
  }
}
