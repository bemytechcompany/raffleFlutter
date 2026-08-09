import 'package:sqflite/sqflite.dart';

import 'package:raffle/core/db/app_database.dart';
import '../models/giveaway_model.dart';

/// Consultas sobre la tabla `giveaways`.
///
/// Los participantes cuelgan de esta tabla por clave foránea con
/// `ON DELETE CASCADE`, así que borrar un sorteo se los lleva por delante sin
/// tener que coordinarlo desde Dart.
class GiveawayLocalDatasource {
  final DatabaseProvider _databaseProvider;

  GiveawayLocalDatasource({DatabaseProvider? databaseProvider})
      : _databaseProvider =
            databaseProvider ?? (() => AppDatabase.instance.database);

  static final GiveawayLocalDatasource instance = GiveawayLocalDatasource();

  Future<Database> get _db => _databaseProvider();

  Future<int> insertGiveaway(GiveawayModel model) async {
    final db = await _db;
    return db.insert('giveaways', model.toColumns());
  }

  Future<List<GiveawayModel>> getAllGiveaways() async {
    final db = await _db;
    final rows = await db.query(
      'giveaways',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );
    return rows.map(GiveawayModel.fromMap).toList();
  }

  Future<GiveawayModel?> getGiveawayById(int id) async {
    final db = await _db;
    final rows = await db.query('giveaways', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : GiveawayModel.fromMap(rows.first);
  }

  Future<void> updateGiveawayStatus(int id, String newStatus) async {
    final db = await _db;
    await db.update(
      'giveaways',
      {
        'status': newStatus,
        'updated_at': DateTime.now().toDbString(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteGiveaway(int id) async {
    final db = await _db;
    await db.delete('giveaways', where: 'id = ?', whereArgs: [id]);
  }
}
