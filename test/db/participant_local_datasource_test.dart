import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:raffle/core/db/app_database.dart';
import 'package:raffle/features/giveaways/data/datasources/giveaway_local_datasource.dart';
import 'package:raffle/features/giveaways/data/datasources/participant_local_datasource.dart';
import 'package:raffle/features/giveaways/data/models/giveaway_model.dart';
import 'package:raffle/features/giveaways/data/models/participant_model.dart';

GiveawayModel buildGiveaway({String status = 'pending'}) {
  final date = DateTime(2026, 1, 1);
  return GiveawayModel(
    id: null,
    name: 'Sorteo de prueba',
    description: '',
    drawDate: date,
    status: status,
    createdAt: date,
    updatedAt: date,
  );
}

ParticipantModel buildParticipant(int giveawayId, int index) {
  final date = DateTime(2026, 1, 1);
  return ParticipantModel(
    id: null,
    giveawayId: giveawayId,
    name: 'P$index',
    contact: 'contacto$index',
    isPreselected: false,
    isWinner: false,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  sqfliteFfiInit();

  late Database db;
  late ParticipantLocalDatasource datasource;
  late GiveawayLocalDatasource giveaways;

  /// Cuenta filas de `participants` que cumplen [where].
  Future<int> count(String where, List<Object?> args) async {
    return Sqflite.firstIntValue(
          await db
              .rawQuery('SELECT COUNT(*) FROM participants WHERE $where', args),
        ) ??
        0;
  }

  Future<String> statusOf(int giveawayId) async {
    final row = await giveaways.getGiveawayById(giveawayId);
    return row!.status;
  }

  /// Crea un sorteo con [participants] participantes y devuelve su id.
  Future<int> seed({int participants = 5, String status = 'pending'}) async {
    final giveawayId =
        await giveaways.insertGiveaway(buildGiveaway(status: status));
    for (var i = 1; i <= participants; i++) {
      await datasource.insertParticipant(buildParticipant(giveawayId, i));
    }
    return giveawayId;
  }

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppSchema.version,
        onConfigure: AppSchema.onConfigure,
        onCreate: AppSchema.onCreate,
      ),
    );
    datasource = ParticipantLocalDatasource(databaseProvider: () async => db);
    giveaways = GiveawayLocalDatasource(databaseProvider: () async => db);
  });

  tearDown(() async => db.close());

  group('preselección', () {
    test('marca exactamente el número pedido y limpia la anterior', () async {
      final giveawayId = await seed(participants: 5);

      await datasource.preselectParticipants(giveawayId: giveawayId, count: 3);
      expect(
          await count('giveaway_id = ? AND is_preselected = 1', [giveawayId]),
          3);

      // Una segunda preselección no acumula: sustituye a la primera.
      await datasource.preselectParticipants(giveawayId: giveawayId, count: 2);
      expect(
          await count('giveaway_id = ? AND is_preselected = 1', [giveawayId]),
          2);
    });
  });

  group('sortear ganador', () {
    test('el ganador deja de contar como preseleccionado pendiente', () async {
      // Regresión: la pantalla contaba `is_preselected` a secas, así que el
      // número se quedaba clavado en el inicial aunque esos participantes ya
      // hubieran ganado y no pudieran volver a salir.
      final giveawayId = await seed(participants: 5);
      await datasource.preselectParticipants(giveawayId: giveawayId, count: 2);

      final winner = await datasource.drawWinner(giveawayId);

      expect(winner, isNotNull);
      expect(winner!.isPendingPreselection, isFalse,
          reason: 'el ganador ya no está pendiente de salir');
      expect(
        await count(
            'giveaway_id = ? AND is_preselected = 1 AND is_winner = 0',
            [giveawayId]),
        1,
        reason: 'de los 2 preseleccionados queda 1 sin sortear',
      );
    });

    test('agotar la preselección deja el contador en cero', () async {
      final giveawayId = await seed(participants: 5);
      await datasource.preselectParticipants(giveawayId: giveawayId, count: 2);

      await datasource.drawWinner(giveawayId);
      await datasource.drawWinner(giveawayId);

      expect(
          await count(
              'giveaway_id = ? AND is_preselected = 1 AND is_winner = 0',
              [giveawayId]),
          0);
      expect(await count('giveaway_id = ? AND is_winner = 1', [giveawayId]), 2);
    });

    test('sin preseleccionados sin sortear ya no hay ganador', () async {
      final giveawayId = await seed(participants: 5);
      await datasource.preselectParticipants(giveawayId: giveawayId, count: 1);

      expect(await datasource.drawWinner(giveawayId), isNotNull);
      expect(await datasource.drawWinner(giveawayId), isNull,
          reason: 'no debe repescar a quien nunca fue preseleccionado');
    });

    test('reparte los premios por orden', () async {
      final giveawayId = await seed(participants: 5);

      final awards = <String?>[];
      for (var i = 0; i < 4; i++) {
        awards.add((await datasource.drawWinner(giveawayId))?.award);
      }

      expect(awards, ['Oro', 'Plata', 'Bronce', 'Reconocimiento']);
    });

    test('el sorteo pasa a completado al salir el primer ganador', () async {
      final giveawayId = await seed(participants: 3);
      expect(await statusOf(giveawayId), 'pending');

      await datasource.drawWinner(giveawayId);

      expect(await statusOf(giveawayId), 'completed');
    });

    test('un sorteo cancelado no se reabre al sortear', () async {
      final giveawayId = await seed(participants: 3, status: 'cancelled');

      await datasource.drawWinner(giveawayId);

      expect(await statusOf(giveawayId), 'cancelled');
    });

    test('sin participantes devuelve null y no toca el estado', () async {
      final giveawayId = await seed(participants: 0);

      expect(await datasource.drawWinner(giveawayId), isNull);
      expect(await statusOf(giveawayId), 'pending');
    });
  });

  group('reiniciar sorteo', () {
    test('borra ganadores, premios y preselección, y vuelve a pendiente',
        () async {
      final giveawayId = await seed(participants: 5);
      await datasource.preselectParticipants(giveawayId: giveawayId, count: 3);
      await datasource.drawWinner(giveawayId);
      await datasource.drawWinner(giveawayId);

      await datasource.resetDraw(giveawayId);

      expect(await count('giveaway_id = ? AND is_winner = 1', [giveawayId]), 0);
      expect(
          await count('giveaway_id = ? AND is_preselected = 1', [giveawayId]),
          0);
      expect(await count('giveaway_id = ? AND award IS NOT NULL', [giveawayId]),
          0);
      expect(await statusOf(giveawayId), 'pending');
    });

    test('conserva a los participantes', () async {
      final giveawayId = await seed(participants: 5);
      await datasource.drawWinner(giveawayId);

      await datasource.resetDraw(giveawayId);

      expect(
          (await datasource.getParticipantsByGiveawayId(giveawayId)).length, 5);
    });

    test('deja como está un sorteo cancelado', () async {
      final giveawayId = await seed(participants: 3, status: 'cancelled');

      await datasource.resetDraw(giveawayId);

      expect(await statusOf(giveawayId), 'cancelled');
    });

    test('tras reiniciar se puede volver a sortear', () async {
      final giveawayId = await seed(participants: 2);
      await datasource.preselectParticipants(giveawayId: giveawayId, count: 2);
      await datasource.drawWinner(giveawayId);
      await datasource.drawWinner(giveawayId);
      expect(await datasource.drawWinner(giveawayId), isNull);

      await datasource.resetDraw(giveawayId);

      final winner = await datasource.drawWinner(giveawayId);
      expect(winner, isNotNull);
      expect(winner!.award, 'Oro', reason: 'los premios empiezan de nuevo');
    });
  });

  group('edición del sorteo', () {
    test('actualiza nombre, descripción y fecha sin tocar el estado', () async {
      final giveawayId = await seed(participants: 1);
      await datasource.drawWinner(giveawayId);
      expect(await statusOf(giveawayId), 'completed');

      await giveaways.updateGiveaway(
        id: giveawayId,
        name: 'Sorteo renombrado',
        description: 'Nueva descripción',
        drawDate: DateTime.utc(2027, 3, 15),
      );

      final updated = await giveaways.getGiveawayById(giveawayId);
      expect(updated!.name, 'Sorteo renombrado');
      expect(updated.description, 'Nueva descripción');
      expect(updated.drawDate.toUtc(), DateTime.utc(2027, 3, 15));
      expect(updated.status, 'completed',
          reason: 'guardar la edición no puede reabrir un sorteo resuelto');
    });
  });

  group('esquema', () {
    test('borrar el sorteo arrastra a sus participantes', () async {
      final giveawayId = await seed(participants: 4);

      await giveaways.deleteGiveaway(giveawayId);

      expect(
        Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM participants')),
        0,
      );
    });

    test('rechaza un estado de sorteo que no existe', () async {
      expect(
        () => giveaways.insertGiveaway(buildGiveaway(status: 'inventado')),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
