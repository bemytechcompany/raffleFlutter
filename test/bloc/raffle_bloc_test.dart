import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:raffle/core/db/app_database.dart';
import 'package:raffle/features/raffles/data/datasources/raffle_local_datasource.dart';
import 'package:raffle/features/raffles/data/repositories/raffle_repository_impl.dart';
import 'package:raffle/features/raffles/domain/repositories/raffle_repository.dart';
import 'package:raffle/features/raffles/presentation/bloc/raffle_bloc.dart';
import 'package:raffle/features/raffles/presentation/bloc/raffle_event.dart';
import 'package:raffle/features/raffles/presentation/bloc/raffle_state.dart';
import 'package:raffle/features/raffles/presentation/bloc/trash/trash_bloc.dart';

/// Los blocs se prueban contra el repositorio real sobre una base en memoria.
///
/// Con dobles de prueba solo se comprobaría que el bloc llama a lo que
/// creemos; así se comprueba además que la consulta hace lo que esperamos.
void main() {
  sqfliteFfiInit();

  late Database db;
  late RaffleRepository repository;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppSchema.version,
        onConfigure: AppSchema.onConfigure,
        onCreate: AppSchema.onCreate,
      ),
    );
    repository = RaffleRepositoryImpl(
      raffleLocalDatasource:
          RaffleLocalDatasource(databaseProvider: () async => db),
    );
  });

  tearDown(() async => db.close());

  /// Crea rifas a través del bloc y espera a que aparezcan en el listado.
  Future<RaffleBloc> blocWithRaffles(List<String> names) async {
    final bloc = RaffleBloc(repository);
    bloc.add(const LoadRaffles());
    await bloc.stream.firstWhere((s) => s is RaffleLoaded);

    for (var i = 0; i < names.length; i++) {
      bloc.add(CreateRaffle(
        name: names[i],
        lotteryNumber: 'Lotería',
        priceMinor: 100000,
        totalTickets: 5,
        drawDate: DateTime(2026, 6, 1),
        gameType: 'app',
        digitCount: 2,
      ));
      await bloc.stream.firstWhere(
        (s) => s is RaffleLoaded && s.page.total == i + 1,
      );
    }

    return bloc;
  }

  group('RaffleBloc', () {
    test('empieza cargando y publica una lista vacía', () async {
      final bloc = RaffleBloc(repository);
      expect(bloc.state, isA<RaffleLoading>());

      bloc.add(const LoadRaffles());
      final loaded =
          await bloc.stream.firstWhere((s) => s is RaffleLoaded) as RaffleLoaded;

      expect(loaded.page.total, 0);
      expect(loaded.isFiltered, isFalse);
      await bloc.close();
    });

    test('crear una rifa la publica con sus boletos contados', () async {
      final bloc = await blocWithRaffles(['Rifa de la moto']);
      final state = bloc.state as RaffleLoaded;

      expect(state.page.total, 1);
      final summary = state.page.items.single;
      expect(summary.raffle.name, 'Rifa de la moto');
      expect(summary.availableCount, 5);
      expect(summary.soldCount, 0);
      await bloc.close();
    });

    test('la búsqueda filtra tras el retardo', () async {
      final bloc = await blocWithRaffles(['Rifa de la moto', 'Sorteo del TV']);

      bloc.add(const SearchRaffles('moto'));
      final filtered = await bloc.stream.firstWhere(
        (s) => s is RaffleLoaded && s.search == 'moto',
      ) as RaffleLoaded;

      expect(filtered.page.total, 1);
      expect(filtered.page.items.single.raffle.name, 'Rifa de la moto');
      expect(filtered.isFiltered, isTrue);
      await bloc.close();
    });

    test('una búsqueda sin resultados marca el estado como filtrado', () async {
      final bloc = await blocWithRaffles(['Rifa de la moto']);

      bloc.add(const SearchRaffles('no existe'));
      final filtered = await bloc.stream.firstWhere(
        (s) => s is RaffleLoaded && s.search == 'no existe',
      ) as RaffleLoaded;

      expect(filtered.page.isEmpty, isTrue);
      expect(filtered.isFiltered, isTrue,
          reason: 'la pantalla debe decir "sin resultados", no "sin rifas"');
      await bloc.close();
    });

    test('escribir rápido solo consulta la última búsqueda', () async {
      final bloc = await blocWithRaffles(['Rifa de la moto']);

      final seen = <String>[];
      final sub = bloc.stream.listen((s) {
        if (s is RaffleLoaded) seen.add(s.search);
      });

      // Tecleo rápido: el debounce debe descartar los intermedios.
      bloc
        ..add(const SearchRaffles('m'))
        ..add(const SearchRaffles('mo'))
        ..add(const SearchRaffles('mot'))
        ..add(const SearchRaffles('moto'));

      await bloc.stream.firstWhere(
        (s) => s is RaffleLoaded && s.search == 'moto',
      );
      await sub.cancel();

      expect(seen, ['moto'], reason: 'solo debe consultarse el término final');
      await bloc.close();
    });

    test('filtrar por estado usa la consulta y no la lista en memoria',
        () async {
      final bloc = await blocWithRaffles(['Activa']);

      bloc.add(const FilterRafflesByStatus('expired'));
      final filtered = await bloc.stream.firstWhere(
        (s) => s is RaffleLoaded && s.status == 'expired',
      ) as RaffleLoaded;

      expect(filtered.page.total, 0);
      await bloc.close();
    });

    test('mandar a la papelera la saca del listado', () async {
      final bloc = await blocWithRaffles(['Rifa de la moto']);
      final id = (bloc.state as RaffleLoaded).page.items.single.raffle.id!;

      bloc.add(MoveRaffleToTrash(id));
      final after = await bloc.stream.firstWhere(
        (s) => s is RaffleLoaded && s.page.total == 0,
      ) as RaffleLoaded;

      expect(after.page.isEmpty, isTrue);
      await bloc.close();
    });
  });

  group('TrashBloc', () {
    test('recoge lo enviado a la papelera y lo restaura', () async {
      final raffleBloc = await blocWithRaffles(['Rifa de la moto']);
      final id =
          (raffleBloc.state as RaffleLoaded).page.items.single.raffle.id!;
      await repository.moveToTrash(id);

      final trashBloc = TrashBloc(repository);
      trashBloc.add(const LoadTrash());
      final inTrash = await trashBloc.stream
          .firstWhere((s) => s is TrashLoaded) as TrashLoaded;
      expect(inTrash.summaries, hasLength(1));

      trashBloc.add(RestoreRaffleFromTrash(id));
      final restored = await trashBloc.stream.firstWhere(
        (s) => s is TrashLoaded && s.summaries.isEmpty,
      ) as TrashLoaded;
      expect(restored.summaries, isEmpty);

      // Y vuelve a estar en el listado principal.
      expect((await repository.getRaffleSummaries()).total, 1);

      await trashBloc.close();
      await raffleBloc.close();
    });

    test('el borrado definitivo se lleva los boletos', () async {
      final raffleBloc = await blocWithRaffles(['Rifa de la moto']);
      final id =
          (raffleBloc.state as RaffleLoaded).page.items.single.raffle.id!;
      await repository.moveToTrash(id);

      final trashBloc = TrashBloc(repository);
      trashBloc.add(const LoadTrash());
      await trashBloc.stream.firstWhere((s) => s is TrashLoaded);

      trashBloc.add(DeleteRaffleForever(id));
      await trashBloc.stream.firstWhere(
        (s) => s is TrashLoaded && s.summaries.isEmpty,
      );

      final orphans = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM tickets'),
      );
      expect(orphans, 0);

      await trashBloc.close();
      await raffleBloc.close();
    });

    test('la purga no rompe la pantalla si no hay nada que borrar', () async {
      final trashBloc = TrashBloc(repository);
      trashBloc.add(const LoadTrash());
      await trashBloc.stream.firstWhere((s) => s is TrashLoaded);

      trashBloc.add(PurgeExpiredTrash());
      // No debe emitir error; se le da margen para procesarlo.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(trashBloc.state, isA<TrashLoaded>());
      await trashBloc.close();
    });
  });
}
