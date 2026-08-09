import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Cómo obtiene una conexión quien la necesite.
///
/// Los datasources dependen de esto y no de [AppDatabase] directamente, para
/// poder abrir una base en memoria en los tests.
typedef DatabaseProvider = Future<Database> Function();

/// Definición del esquema, sin ninguna dependencia del sistema de archivos.
///
/// Está separado de [AppDatabase] para que los tests puedan crear exactamente
/// el mismo esquema sobre una base en memoria.
class AppSchema {
  AppSchema._();

  static const int version = 1;

  /// sqflite no activa las claves foráneas por defecto: sin esto los
  /// `ON DELETE CASCADE` no harían nada.
  static Future<void> onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> onCreate(Database db, int version) async {
    final batch = db.batch();

    // Los importes se guardan en unidades mínimas (enteros) para que sumar
    // miles de boletos no acumule error de coma flotante.
    batch.execute('''
      CREATE TABLE raffles (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        name           TEXT    NOT NULL,
        lottery_number TEXT    NOT NULL DEFAULT '',
        price_minor    INTEGER NOT NULL CHECK (price_minor >= 0),
        total_tickets  INTEGER NOT NULL CHECK (total_tickets > 0),
        status         TEXT    NOT NULL DEFAULT 'active'
                               CHECK (status IN ('active', 'inactive', 'expired')),
        game_type      TEXT    NOT NULL
                               CHECK (game_type IN ('app', 'lottery')),
        digit_count    INTEGER NOT NULL CHECK (digit_count BETWEEN 1 AND 6),
        winning_number TEXT,
        image_path     TEXT,
        draw_date      TEXT    NOT NULL,
        created_at     TEXT    NOT NULL,
        updated_at     TEXT    NOT NULL,
        deleted_at     TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE tickets (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        raffle_id     INTEGER NOT NULL
                              REFERENCES raffles (id) ON DELETE CASCADE,
        number        INTEGER NOT NULL,
        status        TEXT    NOT NULL DEFAULT 'available'
                              CHECK (status IN ('available', 'reserved', 'sold')),
        buyer_name    TEXT,
        buyer_contact TEXT,
        UNIQUE (raffle_id, number)
      )
    ''');

    batch.execute('''
      CREATE TABLE giveaways (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        description TEXT    NOT NULL DEFAULT '',
        draw_date   TEXT    NOT NULL,
        status      TEXT    NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending', 'completed', 'cancelled')),
        created_at  TEXT    NOT NULL,
        updated_at  TEXT    NOT NULL,
        deleted_at  TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE participants (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        giveaway_id     INTEGER NOT NULL
                                REFERENCES giveaways (id) ON DELETE CASCADE,
        name            TEXT    NOT NULL,
        contact         TEXT    NOT NULL DEFAULT '',
        is_preselected  INTEGER NOT NULL DEFAULT 0
                                CHECK (is_preselected IN (0, 1)),
        is_winner       INTEGER NOT NULL DEFAULT 0
                                CHECK (is_winner IN (0, 1)),
        award           TEXT,
        created_at      TEXT    NOT NULL,
        updated_at      TEXT    NOT NULL
      )
    ''');

    // Resuelve los contadores por estado del listado sin recorrer la tabla.
    batch.execute(
      'CREATE INDEX idx_tickets_raffle_status ON tickets (raffle_id, status)',
    );
    // Orden natural del grid de boletos y de la paginación por página.
    batch.execute(
      'CREATE INDEX idx_tickets_raffle_number ON tickets (raffle_id, number)',
    );
    // El listado filtra por `deleted_at` y ordena por fecha.
    batch.execute(
      'CREATE INDEX idx_raffles_active ON raffles (deleted_at, created_at)',
    );
    batch.execute(
      'CREATE INDEX idx_giveaways_active ON giveaways (deleted_at, created_at)',
    );
    batch.execute(
      'CREATE INDEX idx_participants_giveaway ON participants (giveaway_id)',
    );

    await batch.commit(noResult: true);
  }
}

/// Base de datos de la aplicación, en un único archivo.
///
/// Antes había tres (`raffle.db`, `giveaway.db` y `gateway.db`), lo que hacía
/// imposible declarar claves foráneas entre sorteos y participantes o escribir
/// en varias entidades dentro de la misma transacción.
class AppDatabase {
  static const String fileName = 'raffle_app.db';

  /// Bases del esquema antiguo. La app no estaba publicada, así que se
  /// eliminan en el primer arranque en vez de migrarlas.
  static const List<String> _legacyFileNames = [
    'raffle.db',
    'giveaway.db',
    'gateway.db',
  ];

  static final AppDatabase instance = AppDatabase._();

  /// Se guarda el `Future` para que varias llamadas concurrentes compartan una
  /// única apertura.
  Future<Database>? _databaseFuture;

  AppDatabase._();

  Future<Database> get database => _databaseFuture ??= _open();

  Future<Database> _open() async {
    final directory = await getApplicationDocumentsDirectory();
    await _removeLegacyDatabases(directory);

    return openDatabase(
      join(directory.path, fileName),
      version: AppSchema.version,
      onConfigure: AppSchema.onConfigure,
      onCreate: AppSchema.onCreate,
    );
  }

  Future<void> _removeLegacyDatabases(Directory directory) async {
    for (final name in _legacyFileNames) {
      final file = File(join(directory.path, name));
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// Borra el contenido de todas las tablas respetando las claves foráneas.
  Future<void> clear() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('participants');
      await txn.delete('giveaways');
      await txn.delete('tickets');
      await txn.delete('raffles');
    });
  }
}

/// Conversión de fechas para la base.
///
/// Siempre en UTC: antes se escribía la hora local sin zona horaria, así que
/// ordenar por `created_at` daba resultados incorrectos en cuanto cambiaba el
/// huso o el horario de verano.
extension DbDateTime on DateTime {
  String toDbString() => toUtc().toIso8601String();
}

/// Lee una fecha de la base y la devuelve en hora local, lista para mostrar.
DateTime parseDbDate(String value) => DateTime.parse(value).toLocal();

/// Igual que [parseDbDate] pero tolera nulos.
DateTime? parseDbDateOrNull(Object? value) =>
    value == null ? null : parseDbDate(value as String);
