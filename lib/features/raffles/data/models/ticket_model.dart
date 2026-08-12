import 'package:raffle/features/raffles/domain/entities/ticket.dart';

/// Traducción entre la tabla `tickets` y la entidad [Ticket].
class TicketModel extends Ticket {
  TicketModel({
    required super.id,
    required super.number,
    required super.status,
    super.buyerName,
    super.buyerContact,
    required super.raffleId,
  });

  factory TicketModel.fromMap(Map<String, dynamic> map) {
    return TicketModel(
      id: map['id'] as int?,
      raffleId: map['raffle_id'] as int,
      number: map['number'] as int,
      status: map['status'] as String,
      buyerName: map['buyer_name'] as String?,
      buyerContact: map['buyer_contact'] as String?,
    );
  }

  factory TicketModel.fromEntity(Ticket ticket) {
    return TicketModel(
      id: ticket.id,
      raffleId: ticket.raffleId,
      number: ticket.number,
      status: ticket.status,
      buyerName: ticket.buyerName,
      buyerContact: ticket.buyerContact,
    );
  }

  /// Columnas para `insert`. El `raffleId` se pasa aparte porque al crear una
  /// rifa el id real solo se conoce dentro de la transacción.
  Map<String, dynamic> toColumns({required int raffleId}) {
    return {
      'raffle_id': raffleId,
      'number': number,
      'status': status,
      'buyer_name': buyerName,
      'buyer_contact': buyerContact,
    };
  }

  Ticket toEntity() {
    return Ticket(
      id: id,
      number: number,
      status: status,
      buyerName: buyerName,
      buyerContact: buyerContact,
      raffleId: raffleId,
    );
  }
}
