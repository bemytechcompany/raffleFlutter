import 'package:raffle/core/db/app_database.dart';

import '../../domain/entities/participant.dart';

/// Traducción entre la tabla `participants` y la entidad [Participant].
class ParticipantModel extends Participant {
  const ParticipantModel({
    super.id,
    required super.giveawayId,
    required super.name,
    required super.contact,
    required super.isPreselected,
    required super.isWinner,
    super.award,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ParticipantModel.fromMap(Map<String, dynamic> map) {
    return ParticipantModel(
      id: map['id'] as int?,
      giveawayId: map['giveaway_id'] as int,
      name: map['name'] as String,
      contact: (map['contact'] as String?) ?? '',
      isPreselected: (map['is_preselected'] as int) == 1,
      isWinner: (map['is_winner'] as int) == 1,
      award: map['award'] as String?,
      createdAt: parseDbDate(map['created_at'] as String),
      updatedAt: parseDbDate(map['updated_at'] as String),
    );
  }

  factory ParticipantModel.fromEntity(Participant participant) {
    return ParticipantModel(
      id: participant.id,
      giveawayId: participant.giveawayId,
      name: participant.name,
      contact: participant.contact,
      isPreselected: participant.isPreselected,
      isWinner: participant.isWinner,
      award: participant.award,
      createdAt: participant.createdAt,
      updatedAt: participant.updatedAt,
    );
  }

  /// Columnas para `insert`/`update`. Sin `id`: lo asigna SQLite.
  Map<String, dynamic> toColumns() {
    return {
      'giveaway_id': giveawayId,
      'name': name,
      'contact': contact,
      'is_preselected': isPreselected ? 1 : 0,
      'is_winner': isWinner ? 1 : 0,
      'award': award,
      'created_at': createdAt.toDbString(),
      'updated_at': updatedAt.toDbString(),
    };
  }

  Participant toEntity() {
    return Participant(
      id: id,
      giveawayId: giveawayId,
      name: name,
      contact: contact,
      isPreselected: isPreselected,
      isWinner: isWinner,
      award: award,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
