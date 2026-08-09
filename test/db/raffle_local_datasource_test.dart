import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:raffle/core/db/app_database.dart';
import 'package:raffle/features/raffles/data/datasources/raffle_local_datasource.dart';
import 'package:raffle/features/raffles/data/models/raffle_model.dart';
import 'package:raffle/features/raffles/data/models/ticket_model.dart';

/// Rifa sintética con los campos mínimos.
RaffleModel buildRaffle({
  String name = 'Rifa de prueba',
  String lotteryNumber = 'Lotería de prueba',
  int priceMinor = 100000,
  int totalTickets = 10,
  String status = 'active',
  String gameType = 'app',
  int digitCount = 2,
  DateTime? deletedAt,
}) {
  final date = DateTime(2026, 1, 1);
  return RaffleModel(
    id: null,
    name: name,
    lotteryNumber: lotteryNumber,
    priceMinor: priceMinor,
    totalTickets: totalTickets,
    status: status,
    createdAt: date,
    updatedAt: date,
    date: date,
    gameType: gameType,
    digitCount: digitCount,
    deletedAt: deletedAt,
  );
}

List<TicketModel> buildTickets(int count, {String status = 'available'}) {
  return List.generate(
    count,
    (i) => TicketModel(
      id: null,
      raffleId: 0, // lo asigna la transacción
      number: i + 1,
      status: status,
    ),
  );
}

void main() {
  sqfliteFfiInit();

  late Database db;
  late RaffleLocalDatasource datasource;

  setUp(() async {
    // Base en memoria con exactamente el mismo esquema que la de producción.
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppSchema.version,
        onConfigure: AppSchema.onConfigure,
        onCreate: AppSchema.onCreate,
      ),
    );
    datasource = RaffleLocalDatasource(databaseProvider: () async => db);
  });

  tearDown(() async => db.close());

  group('esquema', () {
    test('borrar una rifa arrastra sus boletos por la clave foránea', () async {
      final raffleId = await datasource.insertRaffleWithTickets(
        buildRaffle(),
        buildTickets(10),
      );

      expect((await datasource.getTickets(raffleId)).length, 10);

      await datasource.deleteForever(raffleId);

      final orphans = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM tickets'),
      );
      expect(orphans, 0, reason: 'no deben quedar boletos huérfanos');
    });

    test('rechaza un estado de rifa que no existe', () async {
      expect(
        () => datasource.insertRaffleWithTickets(
          buildRaffle(status: 'inventado'),
          const [],
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('rechaza un precio negativo', () async {
      expect(
        () => datasource.insertRaffleWithTickets(
          buildRaffle(priceMinor: -1),
          const [],
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('rechaza una rifa sin boletos', () async {
      expect(
        () => datasource.insertRaffleWithTickets(
          buildRaffle(totalTickets: 0),
          const [],
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('no admite dos boletos con el mismo número en una rifa', () async {
      final raffleId = await datasource.insertRaffleWithTickets(
        buildRaffle(),
        buildTickets(3),
      );

      expect(
        () => db.insert('tickets', {
          'raffle_id': raffleId,
          'number': 1, // repetido
          'status': 'available',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('creación', () {
    test('inserta rifa y boletos de forma atómica', () async {
      final raffleId = await datasource.insertRaffleWithTickets(
        buildRaffle(totalTickets: 500),
        buildTickets(500),
      );

      expect(raffleId, greaterThan(0));
      expect((await datasource.getTickets(raffleId)).length, 500);
    });

    test('las fechas se guardan en UTC', () async {
      final raffleId = await datasource.insertRaffleWithTickets(
        buildRaffle(),
        const [],
      );

      final row = await datasource.getRaffleById(raffleId);
      expect(row!['created_at'] as String, endsWith('Z'));
    });
  });

  group('contadores agregados', () {
    test('cuenta por estado sin cargar los boletos', () async {
      final raffleId = await datasource.insertRaffleWithTickets(
        buildRaffle(totalTickets: 6),
        buildTickets(6),
      );

      final tickets = await datasource.getTickets(raffleId);
      await datasource.updateTicket(
        ticketId: tickets[0]['id'] as int,
        status: 'sold',
        buyerName: 'Ana',
      );
      await datasource.updateTicket(
        ticketId: tickets[1]['id'] as int,
        status: 'sold',
        buyerName: 'Luis',
      );
      await datasource.updateTicket(
        ticketId: tickets[2]['id'] as int,
        status: 'reserved',
        buyerName: 'Sara',
      );

      final summaries = await datasource.getRaffleSummaries();
      expect(summaries, hasLength(1));
      expect(summaries.first['sold_count'], 2);
      expect(summaries.first['reserved_count'], 1);
      expect(summaries.first['available_count'], 3);

      expect(
        await datasource.getTicketStatusCounts(raffleId),
        {'available': 3, 'reserved': 1, 'sold': 2},
      );
    });

    test('una rifa sin boletos devuelve ceros, no nulos', () async {
      await datasource.insertRaffleWithTickets(buildRaffle(), const []);

      final summaries = await datasource.getRaffleSummaries();
      expect(summaries.first['sold_count'], 0);
      expect(summaries.first['available_count'], 0);
    });

    test('poner un boleto como disponible borra al comprador', () async {
      final raffleId = await datasource.insertRaffleWithTickets(
        buildRaffle(),
        buildTickets(1),
      );
      final ticketId = (await datasource.getTickets(raffleId)).first['id'];

      await datasource.updateTicket(
        ticketId: ticketId as int,
        status: 'sold',
        buyerName: 'Ana',
        buyerContact: '300',
      );
      await datasource.updateTicket(ticketId: ticketId, status: 'available');

      final ticket = (await datasource.getTickets(raffleId)).first;
      expect(ticket['buyer_name'], isNull);
      expect(ticket['buyer_contact'], isNull);
    });
  });

  group('búsqueda y paginación', () {
    setUp(() async {
      await datasource.insertRaffleWithTickets(
        buildRaffle(name: 'Rifa de la moto', lotteryNumber: 'Boyacá'),
        const [],
      );
      await datasource.insertRaffleWithTickets(
        buildRaffle(name: 'Rifa del carro', lotteryNumber: 'Medellín'),
        const [],
      );
      await datasource.insertRaffleWithTickets(
        buildRaffle(name: 'Sorteo navideño', status: 'inactive'),
        const [],
      );
    });

    test('filtra por nombre sin distinguir mayúsculas', () async {
      final rows = await datasource.getRaffleSummaries(search: 'MOTO');
      expect(rows, hasLength(1));
      expect(rows.first['name'], 'Rifa de la moto');
    });

    test('también busca por el nombre de la lotería', () async {
      final rows = await datasource.getRaffleSummaries(search: 'medell');
      expect(rows, hasLength(1));
      expect(rows.first['name'], 'Rifa del carro');
    });

    test('filtra por estado', () async {
      expect(await datasource.countRaffles(status: 'inactive'), 1);
      expect(await datasource.countRaffles(status: 'all'), 3);
    });

    test('los comodines de LIKE se tratan como texto literal', () async {
      // Sin escapar, "%" devolvería las tres rifas.
      expect(await datasource.countRaffles(search: '%'), 0);
      expect(await datasource.countRaffles(search: '_'), 0);
    });

    test('pagina con limit y offset', () async {
      final first = await datasource.getRaffleSummaries(limit: 2, offset: 0);
      final second = await datasource.getRaffleSummaries(limit: 2, offset: 2);

      expect(first, hasLength(2));
      expect(second, hasLength(1));
      expect(await datasource.countRaffles(), 3);
    });

    test('los boletos se piden por página', () async {
      final raffleId = await datasource.insertRaffleWithTickets(
        buildRaffle(totalTickets: 250),
        buildTickets(250),
      );

      final page =
          await datasource.getTickets(raffleId, limit: 100, offset: 100);
      expect(page, hasLength(100));
      expect(page.first['number'], 101);
      expect(page.last['number'], 200);
    });
  });

  group('papelera', () {
    test('enviar a la papelera la saca del listado pero conserva todo',
        () async {
      final raffleId = await datasource.insertRaffleWithTickets(
        buildRaffle(),
        buildTickets(5),
      );

      await datasource.moveToTrash(raffleId);

      expect(await datasource.getRaffleSummaries(), isEmpty);
      expect(await datasource.getRaffleSummaries(inTrash: true), hasLength(1));
      expect((await datasource.getTickets(raffleId)).length, 5,
          reason: 'los boletos deben sobrevivir para poder restaurar');
    });

    test('restaurar la devuelve al listado', () async {
      final raffleId = await datasource.insertRaffleWithTickets(
        buildRaffle(),
        const [],
      );

      await datasource.moveToTrash(raffleId);
      await datasource.restoreFromTrash(raffleId);

      expect(await datasource.getRaffleSummaries(), hasLength(1));
      expect(await datasource.getRaffleSummaries(inTrash: true), isEmpty);
    });

    test('vaciar la papelera no toca las rifas activas', () async {
      final trashed = await datasource.insertRaffleWithTickets(
        buildRaffle(name: 'A la papelera'),
        const [],
      );
      await datasource.insertRaffleWithTickets(
        buildRaffle(name: 'Se queda'),
        const [],
      );

      await datasource.moveToTrash(trashed);
      await datasource.emptyTrash();

      final remaining = await datasource.getRaffleSummaries();
      expect(remaining, hasLength(1));
      expect(remaining.first['name'], 'Se queda');
    });

    test('la purga solo borra lo que superó el plazo', () async {
      final old = await datasource.insertRaffleWithTickets(
        buildRaffle(name: 'Antigua'),
        const [],
      );
      final recent = await datasource.insertRaffleWithTickets(
        buildRaffle(name: 'Reciente'),
        const [],
      );

      await db.update(
        'raffles',
        {
          'deleted_at':
              DateTime.now().subtract(const Duration(days: 40)).toDbString()
        },
        where: 'id = ?',
        whereArgs: [old],
      );
      await datasource.moveToTrash(recent);

      final purged =
          await datasource.purgeTrashOlderThan(const Duration(days: 30));

      expect(purged, 1);
      final left = await datasource.getRaffleSummaries(inTrash: true);
      expect(left, hasLength(1));
      expect(left.first['name'], 'Reciente');
    });
  });

  group('sorteo aleatorio', () {
    test('elige entre todos los disponibles, no solo la primera página',
        () async {
      final raffleId = await datasource.insertRaffleWithTickets(
        buildRaffle(totalTickets: 300),
        buildTickets(300),
      );

      // Se reserva todo menos un boleto muy avanzado, fuera de la primera
      // página de cien: el sorteo tiene que encontrarlo igualmente.
      await db.update(
        'tickets',
        {'status': 'reserved', 'buyer_name': 'Ana'},
        where: 'raffle_id = ? AND number != ?',
        whereArgs: [raffleId, 250],
      );

      final picked = await datasource.pickRandomAvailableTicket(raffleId);
      expect(picked!['number'], 250);
    });

    test('devuelve null si no queda ninguno disponible', () async {
      final raffleId = await datasource.insertRaffleWithTickets(
        buildRaffle(totalTickets: 3),
        buildTickets(3, status: 'sold'),
      );

      expect(await datasource.pickRandomAvailableTicket(raffleId), isNull);
    });
  });

  group('compradores', () {
    test('cuenta solo los boletos con comprador', () async {
      final raffleId = await datasource.insertRaffleWithTickets(
        buildRaffle(totalTickets: 5),
        buildTickets(5),
      );
      final tickets = await datasource.getTickets(raffleId);

      await datasource.updateTicket(
        ticketId: tickets[0]['id'] as int,
        status: 'sold',
        buyerName: 'Ana',
      );
      await datasource.updateTicket(
        ticketId: tickets[1]['id'] as int,
        status: 'reserved',
        buyerName: 'Luis',
      );
      // Vendido pero sin nombre: no cuenta como comprador.
      await datasource.updateTicket(
        ticketId: tickets[2]['id'] as int,
        status: 'sold',
      );

      expect(await datasource.getBuyerCounts(raffleId),
          {'total': 2, 'sold': 1, 'reserved': 1});
      expect((await datasource.getTicketsWithBuyers(raffleId)).length, 2);
    });
  });

  group('número ganador', () {
    test('una rifa jugada en la app queda finalizada', () async {
      final raffleId = await datasource.insertRaffleWithTickets(
        buildRaffle(gameType: 'app'),
        const [],
      );

      await datasource.setWinningNumberAndFinishRaffle(raffleId, '42');

      final raffle = await datasource.getRaffleById(raffleId);
      expect(raffle!['winning_number'], '42');
      expect(raffle['status'], 'expired');
    });

    test('una rifa de lotería conserva su estado', () async {
      final raffleId = await datasource.insertRaffleWithTickets(
        buildRaffle(gameType: 'lottery'),
        const [],
      );

      await datasource.setWinningNumberAndFinishRaffle(raffleId, '42');

      final raffle = await datasource.getRaffleById(raffleId);
      expect(raffle!['winning_number'], '42');
      expect(raffle['status'], 'active');
    });
  });
}
