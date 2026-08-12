import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:raffle/core/pagination/paged.dart';
import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/features/raffles/domain/entities/raffle_details.dart';
import 'package:raffle/features/raffles/domain/entities/ticket.dart';
import 'package:raffle/features/raffles/domain/entities/ticket_counts.dart';
import 'package:raffle/features/raffles/domain/repositories/raffle_repository.dart';
import 'package:raffle/features/raffles/presentation/bloc/details/raffle_details_bloc.dart';
import 'package:raffle/features/raffles/presentation/bloc/details/raffle_details_event.dart';
import 'package:raffle/features/raffles/presentation/bloc/details/raffle_details_state.dart';
import 'package:raffle/features/raffles/presentation/widgets/ticket_grid.dart';

/// Repositorio en memoria.
///
/// No se usa la base con `sqflite_common_ffi` como en los tests de datasource:
/// `testWidgets` corre con reloj falso y la E/S real nunca resuelve, así que
/// el test se quedaría colgado. Lo que se ejercita aquí es el cableado de la
/// pantalla, y para eso basta con recordar lo que se escribió.
class InMemoryRaffleRepository implements RaffleRepository {
  Raffle raffle;
  final List<Ticket> tickets;

  InMemoryRaffleRepository({required this.raffle, required this.tickets});

  @override
  Future<RaffleDetails?> getRaffleDetails(int raffleId) async {
    return RaffleDetails(
      raffle: raffle,
      counts: TicketCounts(
        sold: tickets.where((t) => t.status == 'sold').length,
        reserved: tickets.where((t) => t.status == 'reserved').length,
        available: tickets.where((t) => t.status == 'available').length,
      ),
      buyers: const BuyerCounts(total: 0, sold: 0, reserved: 0),
    );
  }

  @override
  Future<Paged<Ticket>> getTicketPage(int raffleId,
      {int page = 0, int pageSize = 100}) async {
    return Paged(
      items: tickets,
      total: tickets.length,
      page: 0,
      pageSize: pageSize,
    );
  }

  @override
  Future<Ticket?> pickWinningTicket(int raffleId) async {
    final sold = tickets.where((t) => t.status == 'sold').toList();
    final pool = sold.isNotEmpty ? sold : tickets;
    return pool.isEmpty ? null : pool.first;
  }

  @override
  Future<void> setWinningNumberAndFinishRaffle(
      int raffleId, String winningNumber) async {
    if (winningNumber.isEmpty) return resetDraw(raffleId);
    raffle = raffle.copyWith(
      winningNumber: winningNumber,
      status: 'expired',
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> resetDraw(int raffleId) async {
    raffle = Raffle(
      id: raffle.id,
      name: raffle.name,
      lotteryNumber: raffle.lotteryNumber,
      priceMinor: raffle.priceMinor,
      totalTickets: raffle.totalTickets,
      status: 'active',
      createdAt: raffle.createdAt,
      updatedAt: DateTime.now(),
      date: raffle.date,
      gameType: raffle.gameType,
      digitCount: raffle.digitCount,
      // Sin `copyWith`: no sabe poner el ganador a null.
      winningNumber: null,
    );
  }

  @override
  Future<void> updateRaffleStatus(int raffleId, String newStatus) async {
    raffle = raffle.copyWith(status: newStatus);
  }

  @override
  Future<List<Ticket>> getAllTickets(int raffleId) async => tickets;

  @override
  Future<List<Ticket>> getTicketsWithBuyers(int raffleId) async =>
      tickets.where((t) => t.buyerName != null).toList();

  // El resto de la interfaz no interviene en esta pantalla.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} no se usa aquí');
}

Raffle buildRaffle({String status = 'active', String? winningNumber}) {
  final date = DateTime(2026, 1, 1);
  return Raffle(
    id: 1,
    name: 'Rifa de prueba',
    lotteryNumber: 'Lotería de prueba',
    priceMinor: 100000,
    totalTickets: 5,
    status: status,
    createdAt: date,
    updatedAt: date,
    date: date,
    gameType: 'app',
    digitCount: 2,
    winningNumber: winningNumber,
  );
}

List<Ticket> buildSoldTickets() => List.generate(
      5,
      (i) => Ticket(
        id: i + 1,
        raffleId: 1,
        number: i + 1,
        status: 'sold',
        buyerName: 'Ana',
      ),
    );

/// El sorteo, de punta a punta: botón, diálogo y escritura.
///
/// El `BlocProvider` se monta **dentro** de `home`, como en producción, donde
/// lo crea la ruta de detalle. Es la parte que importa: `showDialog` inserta en
/// el Navigator raíz, que queda por encima de ese provider, así que un diálogo
/// que busque el bloc desde su propio context no lo encuentra. Ese era el
/// fallo: el evento se iba a otro bloc sin rifa cargada y se descartaba en
/// silencio, sin escribir nada y sin dar error.
void main() {
  Future<RaffleDetailsBloc> pumpGrid(
    WidgetTester tester,
    InMemoryRaffleRepository repository,
  ) async {
    final bloc = RaffleDetailsBloc(repository);
    bloc.add(const LoadRaffleDetails(1));
    await bloc.stream.firstWhere((s) => s is RaffleDetailsLoaded);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: Scaffold(
            // Se reconstruye desde el estado, igual que `RaffleDetailsPage`:
            // si el grid se montara con una copia fija de la rifa, el test no
            // vería los cambios que el sorteo provoca en la pantalla.
            body: BlocBuilder<RaffleDetailsBloc, RaffleDetailsState>(
              builder: (context, state) {
                if (state is! RaffleDetailsLoaded) {
                  return const SizedBox.shrink();
                }
                return SingleChildScrollView(
                  child: TicketGrid(
                    page: state.tickets,
                    raffle: state.raffle,
                    onTap: (_) {},
                    showRandomButton: state.raffle.status == 'active',
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bloc;
  }

  testWidgets('confirmar en el diálogo guarda el ganador y cierra la rifa',
      (tester) async {
    final repository = InMemoryRaffleRepository(
      raffle: buildRaffle(),
      tickets: buildSoldTickets(),
    );
    final bloc = await pumpGrid(tester, repository);
    addTearDown(bloc.close);

    await tester.tap(find.text('Seleccionar Número Ganador'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar Número Ganador'), findsOneWidget);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(repository.raffle.winningNumber, '1',
        reason: 'confirmar tiene que guardar el ganador');
    expect(repository.raffle.status, 'expired');
    // Y la pantalla se entera sin salir y volver a entrar.
    expect(find.text('Ver Número Ganador'), findsOneWidget);
  });

  testWidgets('cancelar en el diálogo no toca la rifa', (tester) async {
    final repository = InMemoryRaffleRepository(
      raffle: buildRaffle(),
      tickets: buildSoldTickets(),
    );
    final bloc = await pumpGrid(tester, repository);
    addTearDown(bloc.close);

    await tester.tap(find.text('Seleccionar Número Ganador'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repository.raffle.winningNumber, isNull);
    expect(repository.raffle.status, 'active');
  });

  testWidgets('reiniciar el sorteo borra el ganador y reabre la rifa',
      (tester) async {
    final repository = InMemoryRaffleRepository(
      raffle: buildRaffle(status: 'expired', winningNumber: '3'),
      tickets: buildSoldTickets(),
    );
    final bloc = await pumpGrid(tester, repository);
    addTearDown(bloc.close);

    await tester.tap(find.text('Ver Número Ganador'));
    await tester.pumpAndSettle();
    // El botón de reiniciar tiene que salir aunque la rifa esté en `expired`:
    // es justo el caso para el que existe.
    expect(find.text('Reiniciar Sorteo'), findsOneWidget);

    await tester.tap(find.text('Reiniciar Sorteo'));
    await tester.pumpAndSettle();

    expect(repository.raffle.winningNumber, isNull);
    expect(repository.raffle.status, 'active');
    expect(find.text('Seleccionar Número Ganador'), findsOneWidget,
        reason: 'tras reiniciar se puede volver a sortear sin salir');
  });

  testWidgets('el número ganador se resalta en el grid', (tester) async {
    final repository = InMemoryRaffleRepository(
      raffle: buildRaffle(status: 'expired', winningNumber: '3'),
      tickets: buildSoldTickets(),
    );
    final bloc = await pumpGrid(tester, repository);
    addTearDown(bloc.close);

    expect(find.text('Ganador'), findsOneWidget,
        reason: 'la leyenda incluye al ganador cuando hay número');
  });
}
