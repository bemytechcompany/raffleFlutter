import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/features/raffles/domain/entities/ticket_counts.dart';
import 'package:raffle/features/raffles/presentation/widgets/financial_summary.dart';

/// Rifa de prueba con los campos mínimos que exige la entidad.
Raffle buildRaffle({required int totalTickets}) {
  final date = DateTime(2026, 1, 1);
  return Raffle(
    id: 1,
    name: 'Rifa de prueba',
    lotteryNumber: 'Lotería de prueba',
    priceMinor: 100000, // $1.000,00
    totalTickets: totalTickets,
    status: 'active',
    createdAt: date,
    updatedAt: date,
    date: date,
    gameType: 'app',
    digitCount: 2,
  );
}

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('FinancialSummary', () {
    testWidgets('no revienta cuando la rifa no tiene boletos', (tester) async {
      // Regresión: con cero boletos los porcentajes daban NaN y
      // `Expanded(flex: NaN.round())` lanzaba UnsupportedError.
      await tester.pumpWidget(
        wrap(FinancialSummary(
          raffle: buildRaffle(totalTickets: 1),
          counts: TicketCounts.empty,
        )),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Resumen Financiero'), findsOneWidget);
    });

    testWidgets('reparte los porcentajes entre los estados de los boletos',
        (tester) async {
      await tester.pumpWidget(
        wrap(FinancialSummary(
          raffle: buildRaffle(totalTickets: 4),
          counts: const TicketCounts(sold: 2, reserved: 1, available: 1),
        )),
      );

      expect(tester.takeException(), isNull);
      // 2 vendidos + 1 reservado sobre 4 boletos = 75 % comprometido.
      expect(find.textContaining('75'), findsWidgets);
    });
  });

  group('TicketCounts', () {
    test('sin boletos las proporciones son cero, no NaN', () {
      const counts = TicketCounts.empty;

      expect(counts.total, 0);
      expect(counts.soldRatio, 0);
      expect(counts.committedRatio, 0);
      expect(counts.soldRatio.isNaN, isFalse);
    });

    test('las proporciones suman uno', () {
      const counts = TicketCounts(sold: 2, reserved: 1, available: 1);

      expect(counts.total, 4);
      expect(
        counts.soldRatio + counts.reservedRatio + counts.availableRatio,
        closeTo(1.0, 1e-9),
      );
      expect(counts.committedRatio, 0.75);
    });

    test('los importes se calculan con aritmética entera', () {
      const counts = TicketCounts(sold: 3, reserved: 2, available: 5);

      expect(counts.collectedMinor(150), 450);
      expect(counts.reservedMinor(150), 300);
      expect(counts.remainingMinor(150), 750);
    });
  });
}
