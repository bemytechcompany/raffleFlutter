import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:raffle/features/raffles/presentation/widgets/poster_templates.dart';

void main() {
  test('el catálogo trae Personalizado más al menos diez diseños', () {
    expect(PosterTemplates.all.first, PosterTemplates.custom);
    expect(PosterTemplates.all.length, greaterThanOrEqualTo(11));
  });

  test('los ids de plantilla son únicos', () {
    final ids = PosterTemplates.all.map((t) => t.id).toSet();
    expect(ids.length, PosterTemplates.all.length);
  });

  test('Personalizado conserva la paleta original del póster', () {
    final custom = PosterTemplates.custom;
    expect(custom.background, Colors.deepPurple);
    expect(custom.textColor, Colors.white);
    expect(custom.availableColor, Colors.green);
    expect(custom.reservedColor, Colors.orange);
    expect(custom.soldColor, Colors.red);
    expect(custom.pattern, PosterPattern.none);
    expect(custom.ornament, PosterOrnament.none);
  });

  test('los adornos de esquina usan un motivo dibujable', () {
    for (final template in PosterTemplates.all) {
      expect(template.cornerMotif, isNot(PosterPattern.none));
      expect(template.cornerMotif, isNot(PosterPattern.waves));
      expect(template.cornerMotif, isNot(PosterPattern.stripes));
    }
  });

  testWidgets('los pintores dibujan cada patrón sin lanzar excepciones',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            for (final pattern in PosterPattern.values)
              SizedBox(
                width: 120,
                height: 40,
                child: CustomPaint(
                  painter: PosterPatternPainter(
                    pattern: pattern,
                    colors: const [Colors.pink, Colors.amber],
                  ),
                  foregroundPainter: PosterOrnamentPainter(
                    ornament: PosterOrnament.corners,
                    motif: pattern,
                    color: Colors.pink,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
