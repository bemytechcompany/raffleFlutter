import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/features/raffles/domain/entities/ticket.dart';
import 'package:raffle/features/raffles/presentation/pages/raffle_share_page.dart';
import 'package:raffle/features/raffles/presentation/widgets/poster_templates.dart';

const _raffleName = 'Gran Rifa de Prueba';

Raffle _buildRaffle() {
  final now = DateTime(2026, 9, 1);
  return Raffle(
    id: 1,
    name: _raffleName,
    lotteryNumber: 'Risaralda',
    priceMinor: 2000000,
    totalTickets: 100,
    status: 'active',
    createdAt: now,
    updatedAt: now,
    date: DateTime(2026, 10, 30),
    gameType: 'lottery',
    digitCount: 2,
  );
}

/// 100 boletas con los tres estados mezclados.
List<Ticket> _buildTickets() {
  return List.generate(100, (i) {
    final status =
        i % 7 == 0 ? 'sold' : (i % 5 == 0 ? 'reserved' : 'available');
    return Ticket(raffleId: 1, number: i, status: status);
  });
}

Future<void> _pumpSharePage(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: RaffleSharePage(
        raffle: _buildRaffle(),
        tickets: _buildTickets(),
        currentPage: 0,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Baja hasta el final de la página, donde está el campo de mensaje.
Future<void> _scrollToBottom(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).first;
  await tester.drag(scrollable, const Offset(0, -5000));
  await tester.pumpAndSettle();

  final position = tester.state<ScrollableState>(scrollable).position;
  expect(position.pixels, position.maxScrollExtent);
}

void main() {
  setUpAll(() async {
    // La página formatea la fecha con el locale 'es'.
    await initializeDateFormatting('es');
  });

  testWidgets('la vista previa sigue montada tras bajar hasta el final',
      (tester) async {
    await _pumpSharePage(tester);
    expect(find.text(_raffleName), findsOneWidget);

    await _scrollToBottom(tester);

    // Regresión: con ListView la vista previa se desmontaba al salir del
    // viewport y exportar fallaba con "Null check operator used on a null
    // value" porque el RepaintBoundary ya no tenía contexto.
    expect(find.text(_raffleName, skipOffstage: false), findsOneWidget);
    expect(find.text('Mensaje al compartir'), findsOneWidget);
  });

  testWidgets('permite personalizar fondo y texto por estado de boleta',
      (tester) async {
    await _pumpSharePage(tester);

    final sectionTitle = find.text('Colores de los tickets');
    await tester.ensureVisible(sectionTitle);
    await tester.tap(sectionTitle);
    await tester.pumpAndSettle();

    // Una fila por estado, cada una con su selector de fondo y de texto.
    // Se acota a la sección porque "Fondo" también es el título del
    // ExpansionTile de fondo del póster.
    final colorsSection =
        find.widgetWithText(ExpansionTile, 'Colores de los tickets');
    expect(
      find.descendant(of: colorsSection, matching: find.text('Fondo')),
      findsNWidgets(3),
    );
    expect(
      find.descendant(of: colorsSection, matching: find.text('Texto')),
      findsNWidgets(3),
    );
    expect(find.text('Restablecer'), findsOneWidget);

    // Mientras el texto de un estado no esté personalizado, el botón para
    // volver al color global queda deshabilitado.
    final undoButtons = find.widgetWithIcon(IconButton, Icons.undo);
    expect(undoButtons, findsNWidgets(3));
    for (final button in tester.widgetList<IconButton>(undoButtons)) {
      expect(button.onPressed, isNull);
    }

    // El círculo "Texto" de la primera fila abre el selector de ese estado.
    final firstTextSwatch = find
        .descendant(
          of: find
              .ancestor(
                of: find.text('Texto').first,
                matching: find.byType(Column),
              )
              .first,
          matching: find.byType(GestureDetector),
        )
        .first;
    await tester.ensureVisible(firstTextSwatch);
    await tester.tap(firstTextSwatch);
    await tester.pumpAndSettle();

    expect(find.text('Texto de Disponibles'), findsOneWidget);
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    expect(find.text('Texto de Disponibles'), findsNothing);
  });

  testWidgets('aplicar una plantilla cambia el fondo del póster',
      (tester) async {
    await _pumpSharePage(tester);

    BoxDecoration posterBackground() {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byKey(RaffleSharePage.posterKey),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return box.decoration as BoxDecoration;
    }

    expect(posterBackground().color, PosterTemplates.custom.background);

    final thumbnail = find.text(PosterTemplates.hearts.name);
    await tester.ensureVisible(thumbnail);
    await tester.tap(thumbnail);
    await tester.pumpAndSettle();

    expect(posterBackground().color, PosterTemplates.hearts.background);
  });
}
