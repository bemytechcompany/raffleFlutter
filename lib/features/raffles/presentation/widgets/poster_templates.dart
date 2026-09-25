import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Motivo que se repite en el fondo del póster.
enum PosterPattern {
  none,
  hearts,
  confetti,
  stars,
  snow,
  waves,
  stripes,
  balloons,
  dots,
  flowers,
}

/// Adorno fijo del póster. Se ancla a bordes o esquinas, así que funciona con
/// cualquier alto de rejilla.
enum PosterOrnament { none, frame, corners }

/// Diseño predefinido del póster: fondo, adornos, fuentes y paleta.
class PosterTemplate {
  const PosterTemplate({
    required this.id,
    required this.name,
    required this.background,
    required this.textColor,
    required this.panelColor,
    required this.panelBorderColor,
    required this.availableColor,
    required this.reservedColor,
    required this.soldColor,
    this.pattern = PosterPattern.none,
    this.patternColors = const [],
    this.ornament = PosterOrnament.none,
    this.ornamentColor = Colors.white,
    this.titleFont,
    this.bodyFont,
    this.availableTextColor,
    this.reservedTextColor,
    this.soldTextColor,
  });

  final String id;
  final String name;
  final Color background;
  final Color textColor;

  /// Relleno de los recuadros de fecha, precio y barra de progreso.
  final Color panelColor;
  final Color panelBorderColor;
  final Color availableColor;
  final Color reservedColor;
  final Color soldColor;
  final PosterPattern pattern;
  final List<Color> patternColors;
  final PosterOrnament ornament;
  final Color ornamentColor;

  /// Familias de Google Fonts. `null` usa la fuente del sistema.
  final String? titleFont;
  final String? bodyFont;

  /// Texto de las boletas por estado. `null` hereda [textColor].
  final Color? availableTextColor;
  final Color? reservedTextColor;
  final Color? soldTextColor;

  /// Motivo con el que se dibujan los adornos de esquina.
  PosterPattern get cornerMotif {
    switch (pattern) {
      case PosterPattern.none:
      case PosterPattern.waves:
      case PosterPattern.stripes:
        return PosterPattern.dots;
      default:
        return pattern;
    }
  }
}

/// Catálogo de plantillas. [custom] reproduce el comportamiento original
/// (color sólido o imagen de fondo, sin adornos).
class PosterTemplates {
  PosterTemplates._();

  static const PosterTemplate custom = PosterTemplate(
    id: 'custom',
    name: 'Personalizado',
    background: Colors.deepPurple,
    textColor: Colors.white,
    panelColor: Color(0x26FFFFFF),
    panelBorderColor: Color(0x4DFFFFFF),
    availableColor: Colors.green,
    reservedColor: Colors.orange,
    soldColor: Colors.red,
  );

  static const PosterTemplate hearts = PosterTemplate(
    id: 'hearts',
    name: 'Corazones',
    background: Color(0xFFFBEAF0),
    textColor: Color(0xFF72243E),
    panelColor: Color(0x99FFFFFF),
    panelBorderColor: Color(0xFFED93B1),
    availableColor: Colors.white,
    reservedColor: Color(0xFFF4C0D1),
    soldColor: Color(0xFFD4537E),
    availableTextColor: Color(0xFF993556),
    reservedTextColor: Color(0xFF72243E),
    soldTextColor: Colors.white,
    pattern: PosterPattern.hearts,
    patternColors: [Color(0xFFF4C0D1)],
    ornament: PosterOrnament.corners,
    ornamentColor: Color(0xFFED93B1),
    titleFont: 'Pacifico',
    bodyFont: 'Poppins',
  );

  static const PosterTemplate elegant = PosterTemplate(
    id: 'elegant',
    name: 'Elegante',
    background: Color(0xFF1C1B18),
    textColor: Color(0xFFF0D98A),
    panelColor: Color(0x1AC9A227),
    panelBorderColor: Color(0xFFC9A227),
    availableColor: Color(0xFF2C2A22),
    reservedColor: Color(0xFF4A3F12),
    soldColor: Color(0xFFC9A227),
    availableTextColor: Color(0xFFF0D98A),
    reservedTextColor: Color(0xFFF0D98A),
    soldTextColor: Color(0xFF1C1B18),
    ornament: PosterOrnament.frame,
    ornamentColor: Color(0xFFC9A227),
    titleFont: 'Playfair Display',
    bodyFont: 'Montserrat',
  );

  static const PosterTemplate party = PosterTemplate(
    id: 'party',
    name: 'Fiesta',
    background: Color(0xFF534AB7),
    textColor: Colors.white,
    panelColor: Color(0x2EFFFFFF),
    panelBorderColor: Color(0x66FFFFFF),
    availableColor: Colors.white,
    reservedColor: Color(0xFFFAC775),
    soldColor: Color(0xFFD85A30),
    availableTextColor: Color(0xFF26215C),
    reservedTextColor: Color(0xFF412402),
    soldTextColor: Colors.white,
    pattern: PosterPattern.confetti,
    patternColors: [
      Color(0xFF5DCAA5),
      Color(0xFFFAC775),
      Color(0xFFF0997B),
      Color(0xFFED93B1),
    ],
    titleFont: 'Fredoka',
    bodyFont: 'Poppins',
  );

  static const PosterTemplate christmas = PosterTemplate(
    id: 'christmas',
    name: 'Navidad',
    background: Color(0xFF7A1F1F),
    textColor: Colors.white,
    panelColor: Color(0x26FFFFFF),
    panelBorderColor: Color(0xFFFAC775),
    availableColor: Color(0xFFEAF3DE),
    reservedColor: Color(0xFFFAC775),
    soldColor: Color(0xFF27500A),
    availableTextColor: Color(0xFF173404),
    reservedTextColor: Color(0xFF412402),
    soldTextColor: Colors.white,
    pattern: PosterPattern.snow,
    patternColors: [Color(0x80FFFFFF)],
    ornament: PosterOrnament.frame,
    ornamentColor: Color(0xFFFAC775),
    titleFont: 'Lobster',
    bodyFont: 'Poppins',
  );

  static const PosterTemplate minimal = PosterTemplate(
    id: 'minimal',
    name: 'Minimal',
    background: Colors.white,
    textColor: Color(0xFF2C2C2A),
    panelColor: Color(0x0F000000),
    panelBorderColor: Color(0xFFD3D1C7),
    availableColor: Color(0xFFF1EFE8),
    reservedColor: Color(0xFFFAC775),
    soldColor: Color(0xFF2C2C2A),
    availableTextColor: Color(0xFF2C2C2A),
    reservedTextColor: Color(0xFF412402),
    soldTextColor: Colors.white,
    ornament: PosterOrnament.frame,
    ornamentColor: Color(0xFFD3D1C7),
    titleFont: 'Montserrat',
    bodyFont: 'Montserrat',
  );

  static const PosterTemplate ocean = PosterTemplate(
    id: 'ocean',
    name: 'Océano',
    background: Color(0xFF185FA5),
    textColor: Colors.white,
    panelColor: Color(0x2EFFFFFF),
    panelBorderColor: Color(0x66FFFFFF),
    availableColor: Color(0xFFE6F1FB),
    reservedColor: Color(0xFFFAC775),
    soldColor: Color(0xFF042C53),
    availableTextColor: Color(0xFF042C53),
    reservedTextColor: Color(0xFF412402),
    soldTextColor: Colors.white,
    pattern: PosterPattern.waves,
    patternColors: [Color(0x8085B7EB)],
    titleFont: 'Poppins',
    bodyFont: 'Poppins',
  );

  static const PosterTemplate soccer = PosterTemplate(
    id: 'soccer',
    name: 'Fútbol',
    background: Color(0xFF3B6D11),
    textColor: Colors.white,
    panelColor: Color(0x33000000),
    panelBorderColor: Color(0x80FFFFFF),
    availableColor: Color(0xFFEAF3DE),
    reservedColor: Color(0xFFFAC775),
    soldColor: Color(0xFFE24B4A),
    availableTextColor: Color(0xFF173404),
    reservedTextColor: Color(0xFF412402),
    soldTextColor: Colors.white,
    pattern: PosterPattern.stripes,
    patternColors: [Color(0x33FFFFFF)],
    ornament: PosterOrnament.frame,
    ornamentColor: Colors.white,
    titleFont: 'Bebas Neue',
    bodyFont: 'Oswald',
  );

  static const PosterTemplate birthday = PosterTemplate(
    id: 'birthday',
    name: 'Cumpleaños',
    background: Color(0xFFE6F1FB),
    textColor: Color(0xFF0C447C),
    panelColor: Color(0x99FFFFFF),
    panelBorderColor: Color(0xFF85B7EB),
    availableColor: Colors.white,
    reservedColor: Color(0xFFFAC775),
    soldColor: Color(0xFF378ADD),
    availableTextColor: Color(0xFF185FA5),
    reservedTextColor: Color(0xFF412402),
    soldTextColor: Colors.white,
    pattern: PosterPattern.balloons,
    patternColors: [
      Color(0xFFF09595),
      Color(0xFFFAC775),
      Color(0xFF9FE1CB),
      Color(0xFFAFA9EC),
    ],
    ornament: PosterOrnament.corners,
    ornamentColor: Color(0xFFF09595),
    titleFont: 'Fredoka',
    bodyFont: 'Comfortaa',
  );

  static const PosterTemplate stars = PosterTemplate(
    id: 'stars',
    name: 'Estrellas',
    background: Color(0xFF26215C),
    textColor: Colors.white,
    panelColor: Color(0x1FFFFFFF),
    panelBorderColor: Color(0x66FAC775),
    availableColor: Color(0xFFEEEDFE),
    reservedColor: Color(0xFFFAC775),
    soldColor: Color(0xFF7F77DD),
    availableTextColor: Color(0xFF26215C),
    reservedTextColor: Color(0xFF412402),
    soldTextColor: Colors.white,
    pattern: PosterPattern.stars,
    patternColors: [Color(0xB3FAC775)],
    titleFont: 'Comfortaa',
    bodyFont: 'Poppins',
  );

  static const PosterTemplate halloween = PosterTemplate(
    id: 'halloween',
    name: 'Halloween',
    background: Color(0xFF2C2C2A),
    textColor: Color(0xFFFAC775),
    panelColor: Color(0x4D000000),
    panelBorderColor: Color(0xFFEF9F27),
    availableColor: Color(0xFFF1EFE8),
    reservedColor: Color(0xFFFAC775),
    soldColor: Color(0xFFEF9F27),
    availableTextColor: Color(0xFF2C2C2A),
    reservedTextColor: Color(0xFF412402),
    soldTextColor: Color(0xFF2C2C2A),
    pattern: PosterPattern.stars,
    patternColors: [Color(0x99EF9F27)],
    ornament: PosterOrnament.frame,
    ornamentColor: Color(0xFFEF9F27),
    titleFont: 'Creepster',
    bodyFont: 'Poppins',
  );

  static const PosterTemplate spring = PosterTemplate(
    id: 'spring',
    name: 'Primavera',
    background: Color(0xFFEAF3DE),
    textColor: Color(0xFF27500A),
    panelColor: Color(0x99FFFFFF),
    panelBorderColor: Color(0xFF97C459),
    availableColor: Colors.white,
    reservedColor: Color(0xFFFAC775),
    soldColor: Color(0xFF639922),
    availableTextColor: Color(0xFF3B6D11),
    reservedTextColor: Color(0xFF412402),
    soldTextColor: Colors.white,
    pattern: PosterPattern.flowers,
    patternColors: [Color(0xFFF4C0D1), Color(0xFFFAC775)],
    ornament: PosterOrnament.corners,
    ornamentColor: Color(0xFFED93B1),
    titleFont: 'Dancing Script',
    bodyFont: 'Poppins',
  );

  static const List<PosterTemplate> all = [
    custom,
    hearts,
    elegant,
    party,
    christmas,
    minimal,
    ocean,
    soccer,
    birthday,
    stars,
    halloween,
    spring,
  ];
}

/// Dibuja un motivo centrado en [center] con radio aproximado [radius].
/// [seed] varía la forma en motivos con variantes, como el confeti.
void drawPosterMotif(
  Canvas canvas,
  PosterPattern pattern,
  Offset center,
  double radius,
  Color color, {
  int seed = 0,
}) {
  final fill = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  switch (pattern) {
    case PosterPattern.hearts:
      canvas.drawPath(_heartPath(center, radius), fill);
    case PosterPattern.stars:
      canvas.drawPath(_starPath(center, radius), fill);
    case PosterPattern.confetti:
      if (seed.isEven) {
        canvas.drawCircle(center, radius * 0.55, fill);
      } else {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(seed * 0.7);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: radius, height: radius),
          fill,
        );
        canvas.restore();
      }
    case PosterPattern.snow:
      final stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1, radius * 0.18);
      for (var i = 0; i < 3; i++) {
        final angle = i * math.pi / 3;
        final delta = Offset(math.cos(angle), math.sin(angle)) * radius;
        canvas.drawLine(center - delta, center + delta, stroke);
      }
    case PosterPattern.balloons:
      canvas.drawOval(
        Rect.fromCenter(
            center: center, width: radius * 1.6, height: radius * 2),
        fill,
      );
      final knot = Path()
        ..moveTo(center.dx, center.dy + radius)
        ..lineTo(center.dx - radius * 0.25, center.dy + radius * 1.3)
        ..lineTo(center.dx + radius * 0.25, center.dy + radius * 1.3)
        ..close();
      canvas.drawPath(knot, fill);
      canvas.drawLine(
        Offset(center.dx, center.dy + radius * 1.3),
        Offset(center.dx + radius * 0.3, center.dy + radius * 2.2),
        Paint()
          ..color = color
          ..strokeWidth = 1,
      );
    case PosterPattern.flowers:
      for (var i = 0; i < 5; i++) {
        final angle = i * 2 * math.pi / 5;
        canvas.drawCircle(
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.7,
          radius * 0.5,
          fill,
        );
      }
      canvas.drawCircle(
        center,
        radius * 0.35,
        Paint()..color = Color.lerp(color, Colors.white, 0.6) ?? color,
      );
    case PosterPattern.dots:
    case PosterPattern.none:
    case PosterPattern.waves:
    case PosterPattern.stripes:
      canvas.drawCircle(center, radius * 0.6, fill);
  }
}

Path _heartPath(Offset c, double s) {
  return Path()
    ..moveTo(c.dx, c.dy + s)
    ..cubicTo(c.dx - s * 1.6, c.dy - s * 0.2, c.dx - s * 0.9, c.dy - s * 1.3,
        c.dx, c.dy - s * 0.5)
    ..cubicTo(c.dx + s * 0.9, c.dy - s * 1.3, c.dx + s * 1.6, c.dy - s * 0.2,
        c.dx, c.dy + s)
    ..close();
}

Path _starPath(Offset c, double r) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final radius = i.isEven ? r : r * 0.45;
    final angle = -math.pi / 2 + i * math.pi / 5;
    final point = c + Offset(math.cos(angle), math.sin(angle)) * radius;
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  return path..close();
}

/// Pinta el motivo de fondo repetido. [scale] reduce el tamaño para las
/// miniaturas del selector.
class PosterPatternPainter extends CustomPainter {
  const PosterPatternPainter({
    required this.pattern,
    required this.colors,
    this.scale = 1,
  });

  final PosterPattern pattern;
  final List<Color> colors;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern == PosterPattern.none || colors.isEmpty) return;
    switch (pattern) {
      case PosterPattern.waves:
        _paintWaves(canvas, size);
      case PosterPattern.stripes:
        _paintStripes(canvas, size);
      default:
        _paintTiled(canvas, size);
    }
  }

  void _paintTiled(Canvas canvas, Size size) {
    final cell = 48 * scale;
    final radius = 7 * scale;
    var row = 0;
    for (var y = cell / 2; y < size.height + cell; y += cell, row++) {
      final shift = row.isOdd ? cell / 2 : 0.0;
      var col = 0;
      for (var x = cell / 2 + shift; x < size.width + cell; x += cell, col++) {
        drawPosterMotif(
          canvas,
          pattern,
          Offset(x, y),
          radius,
          colors[(row + col) % colors.length],
          seed: row * 7 + col * 3,
        );
      }
    }
  }

  void _paintWaves(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.first
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;
    final gap = 30 * scale;
    final amplitude = 4 * scale;
    final length = 48 * scale;
    for (var y = gap / 2; y < size.height; y += gap) {
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 2) {
        path.lineTo(x, y + amplitude * math.sin(x / length * 2 * math.pi));
      }
      canvas.drawPath(path, paint);
    }
  }

  void _paintStripes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.first
      ..strokeWidth = 14 * scale;
    final gap = 44 * scale;
    for (var d = -size.height; d < size.width; d += gap) {
      canvas.drawLine(
          Offset(d, 0), Offset(d + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant PosterPatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern ||
        oldDelegate.scale != scale ||
        !listEquals(oldDelegate.colors, colors);
  }
}

/// Pinta el adorno fijo: marco doble o motivos grandes en las esquinas.
class PosterOrnamentPainter extends CustomPainter {
  const PosterOrnamentPainter({
    required this.ornament,
    required this.motif,
    required this.color,
    this.scale = 1,
  });

  final PosterOrnament ornament;
  final PosterPattern motif;
  final Color color;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    switch (ornament) {
      case PosterOrnament.none:
        return;
      case PosterOrnament.frame:
        _paintFrame(canvas, size);
      case PosterOrnament.corners:
        _paintCorners(canvas, size);
    }
  }

  void _paintFrame(Canvas canvas, Size size) {
    final outer = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    final inner = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * scale;
    final o = 10 * scale;
    final i = 16 * scale;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(o, o, size.width - 2 * o, size.height - 2 * o),
        Radius.circular(12 * scale),
      ),
      outer,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(i, i, size.width - 2 * i, size.height - 2 * i),
        Radius.circular(8 * scale),
      ),
      inner,
    );
  }

  void _paintCorners(Canvas canvas, Size size) {
    final big = 34 * scale;
    final small = 18 * scale;
    final soft = color.withValues(alpha: 0.7);
    drawPosterMotif(canvas, motif, Offset(big * 0.4, big * 0.4), big, color);
    drawPosterMotif(
      canvas,
      motif,
      Offset(size.width - big * 0.4, size.height - big * 0.4),
      big,
      color,
      seed: 2,
    );
    drawPosterMotif(
      canvas,
      motif,
      Offset(size.width - small, small * 1.2),
      small,
      soft,
      seed: 1,
    );
    drawPosterMotif(
      canvas,
      motif,
      Offset(small, size.height - small * 1.2),
      small,
      soft,
      seed: 3,
    );
  }

  @override
  bool shouldRepaint(covariant PosterOrnamentPainter oldDelegate) {
    return oldDelegate.ornament != ornament ||
        oldDelegate.motif != motif ||
        oldDelegate.color != color ||
        oldDelegate.scale != scale;
  }
}

/// Miniatura de una plantilla para el selector.
class PosterTemplateThumbnail extends StatelessWidget {
  const PosterTemplateThumbnail({
    super.key,
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final PosterTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final statusColors = [
      template.availableColor,
      template.soldColor,
      template.reservedColor,
    ];

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 84,
              decoration: BoxDecoration(
                color: template.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? accent : Colors.grey,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomPaint(
                  painter: PosterPatternPainter(
                    pattern: template.pattern,
                    colors: template.patternColors,
                    scale: 0.45,
                  ),
                  foregroundPainter: PosterOrnamentPainter(
                    ornament: template.ornament,
                    motif: template.cornerMotif,
                    color: template.ornamentColor,
                    scale: 0.35,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 30,
                      child: Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        children: [
                          for (var i = 0; i < 9; i++)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColors[(i * 2) % 3],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              template.name,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
