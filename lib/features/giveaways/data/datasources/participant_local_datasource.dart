import 'package:sqflite/sqflite.dart';

import 'package:raffle/core/db/app_database.dart';
import '../../domain/entities/participant.dart';
import '../models/participant_model.dart';

/// Consultas sobre la tabla `participants`.
class ParticipantLocalDatasource {
  /// Premios por orden de sorteo.
  static const List<String> _awards = ['Oro', 'Plata', 'Bronce'];
  static const String _consolationAward = 'Reconocimiento';

  final DatabaseProvider _databaseProvider;

  ParticipantLocalDatasource({DatabaseProvider? databaseProvider})
      : _databaseProvider =
            databaseProvider ?? (() => AppDatabase.instance.database);

  static final ParticipantLocalDatasource instance =
      ParticipantLocalDatasource();

  Future<Database> get _db => _databaseProvider();

  Future<int> insertParticipant(ParticipantModel participant) async {
    final db = await _db;
    return db.insert('participants', participant.toColumns());
  }

  Future<List<ParticipantModel>> getParticipantsByGiveawayId(
      int giveawayId) async {
    final db = await _db;
    final rows = await db.query(
      'participants',
      where: 'giveaway_id = ?',
      whereArgs: [giveawayId],
      orderBy: 'created_at ASC',
    );
    return rows.map(ParticipantModel.fromMap).toList();
  }

  Future<void> updateParticipant(ParticipantModel participant) async {
    final db = await _db;
    await db.update(
      'participants',
      participant.toColumns(),
      where: 'id = ?',
      whereArgs: [participant.id],
    );
  }

  Future<void> deleteParticipant(int id) async {
    final db = await _db;
    await db.delete('participants', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteParticipantsByGiveaway(int giveawayId) async {
    final db = await _db;
    await db.delete('participants',
        where: 'giveaway_id = ?', whereArgs: [giveawayId]);
  }

  /// Marca al azar [count] participantes como preseleccionados y quita la
  /// preselección al resto.
  Future<void> preselectParticipants({
    required int giveawayId,
    required int count,
  }) async {
    if (count <= 0) return;

    final db = await _db;

    await db.transaction((txn) async {
      await txn.update(
        'participants',
        {'is_preselected': 0},
        where: 'giveaway_id = ?',
        whereArgs: [giveawayId],
      );

      final rows = await txn.query(
        'participants',
        columns: ['id'],
        where: 'giveaway_id = ?',
        whereArgs: [giveawayId],
      );
      if (rows.isEmpty) return;

      final ids = rows.map((row) => row['id'] as int).toList()..shuffle();
      final selected = ids.take(count).toList();
      if (selected.isEmpty) return;

      final placeholders = List.filled(selected.length, '?').join(', ');
      await txn.update(
        'participants',
        {'is_preselected': 1},
        where: 'id IN ($placeholders)',
        whereArgs: selected,
      );
    });
  }

  /// Sortea un ganador entre quienes aún no han ganado.
  ///
  /// Si el sorteo tiene preseleccionados, solo ellos entran. Cuando ya han
  /// ganado todos, devuelve `null` en vez de repescar a quien nunca fue
  /// preseleccionado.
  Future<Participant?> drawWinner(int giveawayId) async {
    final db = await _db;

    return db.transaction((txn) async {
      final preselected = Sqflite.firstIntValue(await txn.rawQuery(
            'SELECT COUNT(*) FROM participants '
            'WHERE giveaway_id = ? AND is_preselected = 1',
            [giveawayId],
          )) ??
          0;

      final candidates = await txn.query(
        'participants',
        where: preselected > 0
            ? 'giveaway_id = ? AND is_preselected = 1 AND is_winner = 0'
            : 'giveaway_id = ? AND is_winner = 0',
        whereArgs: [giveawayId],
      );
      if (candidates.isEmpty) return null;

      final winner =
          ParticipantModel.fromMap((candidates.toList()..shuffle()).first);

      final winnerCount = Sqflite.firstIntValue(await txn.rawQuery(
            'SELECT COUNT(*) FROM participants '
            'WHERE giveaway_id = ? AND is_winner = 1',
            [giveawayId],
          )) ??
          0;

      final award = winnerCount < _awards.length
          ? _awards[winnerCount]
          : _consolationAward;
      final updatedAt = DateTime.now();

      await txn.update(
        'participants',
        {
          'is_winner': 1,
          'award': award,
          'updated_at': updatedAt.toDbString(),
        },
        where: 'id = ?',
        whereArgs: [winner.id],
      );

      // Se devuelve ya con el premio aplicado para que quien llame no tenga
      // que releer la fila.
      return Participant(
        id: winner.id,
        giveawayId: winner.giveawayId,
        name: winner.name,
        contact: winner.contact,
        isPreselected: winner.isPreselected,
        isWinner: true,
        award: award,
        createdAt: winner.createdAt,
        updatedAt: updatedAt,
      );
    });
  }
}
