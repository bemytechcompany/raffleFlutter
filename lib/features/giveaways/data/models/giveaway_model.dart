import 'package:raffle/core/db/app_database.dart';

import '../../domain/entities/giveaway.dart';

/// Traducción entre la tabla `giveaways` y la entidad [Giveaway].
class GiveawayModel extends Giveaway {
  GiveawayModel({
    required super.id,
    required super.name,
    required super.description,
    required super.drawDate,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory GiveawayModel.fromMap(Map<String, dynamic> map) {
    return GiveawayModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      drawDate: parseDbDate(map['draw_date'] as String),
      status: map['status'] as String,
      createdAt: parseDbDate(map['created_at'] as String),
      updatedAt: parseDbDate(map['updated_at'] as String),
    );
  }

  factory GiveawayModel.fromEntity(Giveaway giveaway) {
    return GiveawayModel(
      id: giveaway.id,
      name: giveaway.name,
      description: giveaway.description,
      drawDate: giveaway.drawDate,
      status: giveaway.status,
      createdAt: giveaway.createdAt,
      updatedAt: giveaway.updatedAt,
    );
  }

  /// Columnas para `insert`/`update`. Sin `id`: lo asigna SQLite.
  Map<String, dynamic> toColumns() {
    return {
      'name': name,
      'description': description,
      'draw_date': drawDate.toDbString(),
      'status': status,
      'created_at': createdAt.toDbString(),
      'updated_at': updatedAt.toDbString(),
    };
  }

  Giveaway toEntity() {
    return Giveaway(
      id: id,
      name: name,
      description: description,
      drawDate: drawDate,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
