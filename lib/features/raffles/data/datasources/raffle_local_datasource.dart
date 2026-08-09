import 'package:sqflite/sqflite.dart';

import 'package:raffle/core/db/app_database.dart';
import '../models/raffle_model.dart';
import '../models/ticket_model.dart';

/// Filtro reutilizable para las consultas del listado.
typedef _Filter = ({String where, List<Object?> args});

/// Consultas sobre las tablas `raffles` y `tickets`.
///
/// Todo lo que puede resolver SQLite (contar, filtrar, ordenar, paginar) se
/// resuelve en SQL: la app puede tener rifas de diez mil boletos y traerlos a
/// memoria para contarlos no escala.
///
/// Las rifas se borran de forma suave: `deleted_at` marca las que están en la
/// papelera.
class RaffleLocalDatasource {
  final DatabaseProvider _databaseProvider;

  RaffleLocalDatasource({DatabaseProvider? databaseProvider})
      : _databaseProvider =
            databaseProvider ?? (() => AppDatabase.instance.database);

  static final RaffleLocalDatasource instance = RaffleLocalDatasource();

  Future<Database> get _db => _databaseProvider();

  // --------------------------------------------------------------------
  // Listado
  // --------------------------------------------------------------------

  /// Rifas con sus contadores de boletos resueltos por SQLite.
  ///
  /// Devuelve una fila por rifa con cuántos boletos hay vendidos, reservados y
  /// disponibles, sin traer ni un solo boleto a memoria.
  Future<List<Map<String, dynamic>>> getRaffleSummaries({
    bool inTrash = false,
    String? search,
    String? status,
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    final filter = _raffleFilter(
      inTrash: inTrash,
      search: search,
      status: status,
    );
    final orderColumn = inTrash ? 'r.deleted_at' : 'r.created_at';

    return db.rawQuery(
      '''
      SELECT r.*,
             COALESCE(SUM(CASE WHEN t.status = 'sold'      THEN 1 ELSE 0 END), 0) AS sold_count,
             COALESCE(SUM(CASE WHEN t.status = 'reserved'  THEN 1 ELSE 0 END), 0) AS reserved_count,
             COALESCE(SUM(CASE WHEN t.status = 'available' THEN 1 ELSE 0 END), 0) AS available_count
      FROM raffles r
      LEFT JOIN tickets t ON t.raffle_id = r.id
      WHERE ${filter.where}
      GROUP BY r.id
      ORDER BY $orderColumn DESC
      ${limit == null ? '' : 'LIMIT ? OFFSET ?'}
      ''',
      [...filter.args, if (limit != null) limit, if (limit != null) offset ?? 0],
    );
  }

  /// Cuántas rifas cumplen el filtro. Necesario para paginar sin cargarlas.
  Future<int> countRaffles({
    bool inTrash = false,
    String? search,
    String? status,
  }) async {
    final db = await _db;
    final filter = _raffleFilter(
      inTrash: inTrash,
      search: search,
      status: status,
    );

    final rows = await db.rawQuery(
      'SELECT COUNT(*) FROM raffles r WHERE ${filter.where}',
      filter.args,
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Construye el `WHERE` del listado con parámetros, nunca interpolando lo
  /// que escribe la persona usuaria.
  _Filter _raffleFilter({
    required bool inTrash,
    String? search,
    String? status,
  }) {
    final clauses = <String>[
      inTrash ? 'r.deleted_at IS NOT NULL' : 'r.deleted_at IS NULL',
    ];
    final args = <Object?>[];

    final term = search?.trim().toLowerCase();
    if (term != null && term.isNotEmpty) {
      // LOWER() para que el filtro se comporte igual que el `toLowerCase()`
      // que hacía la lista en Dart.
      clauses.add(
        r"(LOWER(r.name) LIKE ? ESCAPE '\' "
        r"OR LOWER(r.lottery_number) LIKE ? ESCAPE '\')",
      );
      final pattern = '%${_escapeLike(term)}%';
      args
        ..add(pattern)
        ..add(pattern);
    }

    if (status != null && status != 'all') {
      clauses.add('r.status = ?');
      args.add(status);
    }

    return (where: clauses.join(' AND '), args: args);
  }

  /// Neutraliza los comodines de `LIKE` en lo que escribe la persona usuaria,
  /// para que buscar "50%" no devuelva media base.
  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  // --------------------------------------------------------------------
  // Detalle y boletos
  // --------------------------------------------------------------------

  Future<Map<String, dynamic>?> getRaffleById(int id) async {
    final db = await _db;
    final rows = await db.query('raffles', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  /// Una página de boletos, ordenados por número.
  ///
  /// Sin `limit` devuelve todos: lo usan la exportación y el compartir, que sí
  /// necesitan la lista completa.
  Future<List<Map<String, dynamic>>> getTickets(
    int raffleId, {
    int? limit,
    int? offset,
    String? status,
  }) async {
    final db = await _db;
    final hasStatus = status != null && status != 'all';

    return db.query(
      'tickets',
      where: hasStatus ? 'raffle_id = ? AND status = ?' : 'raffle_id = ?',
      whereArgs: [raffleId, if (hasStatus) status],
      orderBy: 'number ASC',
      limit: limit,
      offset: limit == null ? null : (offset ?? 0),
    );
  }

  /// Cuántos boletos hay en cada estado, contados por SQLite.
  Future<Map<String, int>> getTicketStatusCounts(int raffleId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT status, COUNT(*) AS total FROM tickets '
      'WHERE raffle_id = ? GROUP BY status',
      [raffleId],
    );

    final counts = {'available': 0, 'reserved': 0, 'sold': 0};
    for (final row in rows) {
      counts[row['status'] as String] = row['total'] as int;
    }
    return counts;
  }

  /// Cuántos boletos tienen comprador asignado, por estado.
  ///
  /// Lo necesita el resumen de compradores del detalle, que antes recorría los
  /// diez mil boletos en Dart para contarlos.
  Future<Map<String, int>> getBuyerCounts(int raffleId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total,
        COALESCE(SUM(CASE WHEN status = 'sold'     THEN 1 ELSE 0 END), 0) AS sold,
        COALESCE(SUM(CASE WHEN status = 'reserved' THEN 1 ELSE 0 END), 0) AS reserved
      FROM tickets
      WHERE raffle_id = ? AND buyer_name IS NOT NULL AND TRIM(buyer_name) <> ''
      ''',
      [raffleId],
    );

    final row = rows.first;
    return {
      'total': row['total'] as int,
      'sold': row['sold'] as int,
      'reserved': row['reserved'] as int,
    };
  }

  /// Un boleto disponible al azar, elegido por SQLite.
  ///
  /// Se sortea en la base y no en Dart: la pantalla solo tiene cargada una
  /// página de boletos, así que elegir en memoria sortearía entre cien de diez
  /// mil.
  Future<Map<String, dynamic>?> pickRandomAvailableTicket(int raffleId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      "SELECT * FROM tickets WHERE raffle_id = ? AND status = 'available' "
      'ORDER BY RANDOM() LIMIT 1',
      [raffleId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Solo los boletos que tienen comprador, para la lista de compradores.
  Future<List<Map<String, dynamic>>> getTicketsWithBuyers(int raffleId) async {
    final db = await _db;
    return db.query(
      'tickets',
      where: "raffle_id = ? AND buyer_name IS NOT NULL AND TRIM(buyer_name) <> ''",
      whereArgs: [raffleId],
      orderBy: 'number ASC',
    );
  }

  // --------------------------------------------------------------------
  // Escritura
  // --------------------------------------------------------------------

  /// Crea la rifa y sus boletos de forma atómica y devuelve el id asignado.
  ///
  /// Los boletos se insertan por lote: una lotería de cuatro dígitos son diez
  /// mil filas, y una a una tardaba segundos.
  Future<int> insertRaffleWithTickets(
    RaffleModel raffle,
    List<TicketModel> tickets,
  ) async {
    final db = await _db;

    return db.transaction((txn) async {
      final raffleId = await txn.insert('raffles', raffle.toColumns());

      if (tickets.isNotEmpty) {
        final batch = txn.batch();
        for (final ticket in tickets) {
          batch.insert('tickets', ticket.toColumns(raffleId: raffleId));
        }
        await batch.commit(noResult: true);
      }

      return raffleId;
    });
  }

  Future<void> updateTicket({
    required int ticketId,
    required String status,
    String? buyerName,
    String? buyerContact,
  }) async {
    final db = await _db;
    // Un boleto disponible no conserva comprador.
    final isAvailable = status == 'available';

    await db.update(
      'tickets',
      {
        'status': status,
        'buyer_name': isAvailable ? null : buyerName,
        'buyer_contact': isAvailable ? null : buyerContact,
      },
      where: 'id = ?',
      whereArgs: [ticketId],
    );
  }

  /// Devuelve todos los boletos de una rifa al estado disponible.
  Future<void> releaseTickets(int raffleId) async {
    final db = await _db;
    await db.update(
      'tickets',
      {'status': 'available', 'buyer_name': null, 'buyer_contact': null},
      where: 'raffle_id = ?',
      whereArgs: [raffleId],
    );
  }

  Future<void> updateRaffleStatus(int raffleId, String newStatus) =>
      _touch(raffleId, {'status': newStatus});

  Future<void> updateRaffle({
    required int raffleId,
    required String name,
    required String lotteryNumber,
    required int priceMinor,
    required DateTime date,
    String? imagePath,
  }) {
    return _touch(raffleId, {
      'name': name,
      'lottery_number': lotteryNumber,
      'price_minor': priceMinor,
      'draw_date': date.toDbString(),
      'image_path': imagePath,
    });
  }

  /// Guarda el número ganador y, si la rifa se juega en la app, la da por
  /// terminada en la misma transacción.
  Future<void> setWinningNumberAndFinishRaffle(
    int raffleId,
    String winningNumber,
  ) async {
    final db = await _db;

    await db.transaction((txn) async {
      final rows =
          await txn.query('raffles', where: 'id = ?', whereArgs: [raffleId]);
      if (rows.isEmpty) return;

      final gameType = rows.first['game_type'] as String;
      final values = <String, dynamic>{
        'winning_number': winningNumber,
        'updated_at': DateTime.now().toDbString(),
      };

      if (gameType == 'app' && winningNumber.isNotEmpty) {
        values['status'] = 'expired';
      }

      await txn
          .update('raffles', values, where: 'id = ?', whereArgs: [raffleId]);
    });
  }

  // --------------------------------------------------------------------
  // Papelera
  // --------------------------------------------------------------------

  /// Envía la rifa a la papelera. Los boletos se conservan intactos para poder
  /// restaurarla tal cual.
  Future<void> moveToTrash(int raffleId) =>
      _touch(raffleId, {'deleted_at': DateTime.now().toDbString()});

  Future<void> restoreFromTrash(int raffleId) =>
      _touch(raffleId, {'deleted_at': null});

  /// Borrado definitivo. Los boletos se van por `ON DELETE CASCADE`.
  Future<void> deleteForever(int raffleId) async {
    final db = await _db;
    await db.delete('raffles', where: 'id = ?', whereArgs: [raffleId]);
  }

  Future<void> emptyTrash() async {
    final db = await _db;
    await db.delete('raffles', where: 'deleted_at IS NOT NULL');
  }

  /// Elimina lo que lleve demasiado tiempo en la papelera.
  ///
  /// Devuelve cuántas rifas se borraron.
  Future<int> purgeTrashOlderThan(Duration retention) async {
    final db = await _db;
    final cutoff = DateTime.now().subtract(retention).toDbString();

    // Las fechas se guardan en UTC ISO-8601, que es comparable como texto.
    return db.delete(
      'raffles',
      where: 'deleted_at IS NOT NULL AND deleted_at < ?',
      whereArgs: [cutoff],
    );
  }

  /// Aplica cambios a una rifa refrescando siempre `updated_at`.
  Future<void> _touch(int raffleId, Map<String, dynamic> values) async {
    final db = await _db;
    await db.update(
      'raffles',
      {...values, 'updated_at': DateTime.now().toDbString()},
      where: 'id = ?',
      whereArgs: [raffleId],
    );
  }
}
