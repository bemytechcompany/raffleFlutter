import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:raffle/core/money/money.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/raffle.dart';
import '../../domain/entities/ticket.dart';
import '../widgets/poster_templates.dart';

class RaffleSharePage extends StatefulWidget {
  final Raffle raffle;
  final List<Ticket> tickets;
  final int currentPage;

  const RaffleSharePage({
    super.key,
    required this.raffle,
    required this.tickets,
    required this.currentPage,
  });

  /// Identifica la vista previa del póster (útil en tests).
  static const Key posterKey = ValueKey('poster-preview');

  @override
  State<RaffleSharePage> createState() => _RaffleSharePageState();
}

class _RaffleSharePageState extends State<RaffleSharePage> {
  /// Ancho lógico fijo del póster. Con pixelRatio 3 exporta a 1080 px de
  /// ancho en cualquier teléfono; la vista previa se escala con FittedBox.
  static const double _posterWidth = 360;

  static const String _defaultFontLabel = 'Según plantilla';
  static const List<String> _fontOptions = [
    'Poppins',
    'Montserrat',
    'Oswald',
    'Bebas Neue',
    'Playfair Display',
    'Lobster',
    'Pacifico',
    'Dancing Script',
    'Comfortaa',
    'Fredoka',
  ];

  final GlobalKey repaintKey = GlobalKey();
  bool isProcessing = false;

  PosterTemplate template = PosterTemplates.custom;
  Color selectedBackgroundColor = PosterTemplates.custom.background;
  Color selectedTextColor = PosterTemplates.custom.textColor;

  /// Fuente elegida por el usuario. `null` usa las fuentes de la plantilla.
  String? selectedFontFamily;
  bool isBoldText = true;
  double logoSize = 100;
  double titleSize = 24;
  double gridOpacity = 0.8;
  bool showPrice = true;
  bool showLogo = true;
  bool isLogoRounded = true;
  bool showDateAndLottery = true;
  bool showProgressBar = true;
  bool showPercentageDetails = true;
  File? backgroundImage;
  bool useBackgroundImage = false;

  final TextEditingController messageController =
      TextEditingController(text: '¡Participa en nuestra rifa!');
  final TextEditingController responsibleController = TextEditingController();
  final TextEditingController prizeController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController phraseController = TextEditingController();

  /// Colores de fondo y texto de las boletas por estado. Un texto en `null`
  /// hereda [selectedTextColor].
  late final _StatusColors availableColors = _StatusColors(
    background: template.availableColor,
    text: template.availableTextColor,
  );
  late final _StatusColors reservedColors = _StatusColors(
    background: template.reservedColor,
    text: template.reservedTextColor,
  );
  late final _StatusColors soldColors = _StatusColors(
    background: template.soldColor,
    text: template.soldTextColor,
  );

  @override
  void initState() {
    super.initState();
    if (widget.raffle.imagePath == null) {
      titleSize = 28;
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    responsibleController.dispose();
    prizeController.dispose();
    contactController.dispose();
    phraseController.dispose();
    super.dispose();
  }

  /// Aplica la paleta, fuentes y fondo de la plantilla. Los ajustes manuales
  /// posteriores se hacen encima.
  void _applyTemplate(PosterTemplate next) {
    setState(() {
      template = next;
      selectedBackgroundColor = next.background;
      selectedTextColor = next.textColor;
      useBackgroundImage = false;
      selectedFontFamily = null;
      // Con patrón de fondo, las boletas translúcidas dejan ver el motivo y
      // ensucian los números; se parte de opacidad total.
      gridOpacity = next.pattern == PosterPattern.none ? 0.8 : 1.0;
      _resetTicketColorsTo(next);
    });
  }

  void _resetTicketColorsTo(PosterTemplate source) {
    availableColors
      ..background = source.availableColor
      ..text = source.availableTextColor;
    reservedColors
      ..background = source.reservedColor
      ..text = source.reservedTextColor;
    soldColors
      ..background = source.soldColor
      ..text = source.soldTextColor;
  }

  Future<void> _pickBackgroundImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, // Limitar el tamaño para mejor rendimiento
        maxHeight: 1920,
      );

      if (image != null) {
        setState(() {
          backgroundImage = File(image.path);
          useBackgroundImage = true;
        });
      }
    } catch (e) {
      _showMessage('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _exportImage({required bool share}) async {
    if (isProcessing) return;
    setState(() => isProcessing = true);
    try {
      // Cerrar el teclado y esperar a que se pinte el frame para capturar la
      // vista previa tal como se ve.
      FocusManager.instance.primaryFocus?.unfocus();
      // Si se acaba de elegir una fuente, esperar a que termine de descargar
      // para no exportar con la fuente de respaldo. Sin conexión la descarga
      // falla y `pendingFonts` relanza el error: en ese caso se exporta igual
      // con la fuente de respaldo en vez de bloquear la exportación.
      try {
        await GoogleFonts.pendingFonts();
      } catch (_) {
        // Continuar con la fuente de respaldo.
      }
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      final pngBytes = await _capturePreview();
      if (pngBytes == null) {
        _showMessage(
            'No se pudo capturar la vista previa. Inténtalo de nuevo.');
        return;
      }

      if (share) {
        await _shareImage(pngBytes);
      } else {
        await _saveImageToGallery(pngBytes);
      }
    } catch (e) {
      _showMessage('Error al exportar: $e');
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  /// Renderiza la vista previa a PNG. Devuelve `null` si la vista previa no
  /// está montada o la imagen no se pudo codificar.
  Future<Uint8List?> _capturePreview() async {
    final renderObject = repaintKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;

    final image = await renderObject.toImage(pixelRatio: 3.0);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> _shareImage(Uint8List pngBytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${_exportFileName()}.png');
    await file.writeAsBytes(pngBytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: messageController.text,
      ),
    );
  }

  /// Guarda en la galería con `gal` en Android e iOS. El `Info.plist` ya
  /// declara `NSPhotoLibraryAddUsageDescription`.
  Future<void> _saveImageToGallery(Uint8List pngBytes) async {
    var hasAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasAccess) {
      hasAccess = await Gal.requestAccess(toAlbum: true);
    }
    if (!hasAccess) {
      _showMessage('Permiso de galería denegado');
      return;
    }
    await Gal.putImageBytes(
      pngBytes,
      album: 'RaffleShares',
      name: _exportFileName(),
    );
    _showMessage('Imagen guardada en la galería');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Nombre de archivo con la rifa y la fecha, por ejemplo
  /// `rifa_gran_rifa_20260924_2258`.
  String _exportFileName() {
    final slug = widget.raffle.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return 'rifa_${slug.isEmpty ? 'poster' : slug}_$stamp';
  }

  /// Mismo formato que la rejilla de la rifa: con ceros a la izquierda cuando
  /// juega con lotería.
  String _formatTicketNumber(int number) {
    if (widget.raffle.gameType == 'lottery') {
      return number.toString().padLeft(widget.raffle.digitCount, '0');
    }
    return number.toString();
  }

  /// Estilo de texto del póster: color global, negrita y fuente elegida o la
  /// de la plantilla (de título o de cuerpo).
  TextStyle _posterTextStyle({
    required double fontSize,
    Color? color,
    List<Shadow>? shadows,
    bool title = false,
  }) {
    final base = TextStyle(
      color: color ?? selectedTextColor,
      fontSize: fontSize,
      fontWeight: isBoldText ? FontWeight.bold : FontWeight.normal,
      shadows: shadows,
    );
    final family =
        selectedFontFamily ?? (title ? template.titleFont : template.bodyFont);
    if (family == null) return base;
    return GoogleFonts.getFont(family, textStyle: base);
  }

  /// Sombra suave solo cuando el texto es claro; sobre texto oscuro ensucia.
  List<Shadow>? _textShadows({double blur = 4, double offset = 2}) {
    if (selectedTextColor.computeLuminance() < 0.5) return null;
    return [
      Shadow(
        offset: Offset(0, offset),
        blurRadius: blur,
        color: Colors.black38,
      ),
    ];
  }

  Future<void> _pickColor({
    required String title,
    required Color initialColor,
    required ValueChanged<Color> onChanged,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
            onColorChanged: (color) => setState(() => onChanged(color)),
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hsv,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch({
    required Color color,
    VoidCallback? onTap,
    double size = 40,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Póster
  // ---------------------------------------------------------------------------

  Widget _buildPoster() {
    final dateFormat = DateFormat('dd/MM/yyyy', 'es');
    final responsible = responsibleController.text.trim();
    final prize = prizeController.text.trim();
    final contact = contactController.text.trim();
    final phrase = phraseController.text.trim();
    final hasLogo = showLogo && widget.raffle.imagePath != null;
    final image = backgroundImage;
    final showImage = useBackgroundImage && image != null;

    return RepaintBoundary(
      key: repaintKey,
      child: ClipRRect(
        key: RaffleSharePage.posterKey,
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            // Capa 1: color sólido o imagen del usuario.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: showImage ? null : selectedBackgroundColor,
                  image: showImage
                      ? DecorationImage(
                          image: FileImage(image),
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        )
                      : null,
                ),
              ),
            ),
            // Capa 2: patrón repetido de la plantilla (no sobre imagen).
            if (!showImage && template.pattern != PosterPattern.none)
              Positioned.fill(
                child: CustomPaint(
                  painter: PosterPatternPainter(
                    pattern: template.pattern,
                    colors: template.patternColors,
                  ),
                ),
              ),
            // Capa 3: adornos anclados a bordes y esquinas.
            if (template.ornament != PosterOrnament.none)
              Positioned.fill(
                child: CustomPaint(
                  painter: PosterOrnamentPainter(
                    ornament: template.ornament,
                    motif: template.cornerMotif,
                    color: template.ornamentColor,
                  ),
                ),
              ),
            // Capa 4: contenido.
            Column(
              children: [
                const SizedBox(height: 20),
                _buildLogoContainer(),
                SizedBox(height: hasLogo ? 16 : 0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.raffle.name,
                    style: _posterTextStyle(
                      fontSize: titleSize,
                      title: true,
                      shadows: _textShadows(),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (responsible.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Responsable: $responsible',
                      style: _posterTextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (showDateAndLottery) ...[
                  _buildInfoPanel(dateFormat),
                  const SizedBox(height: 16),
                ],
                if (prize.isNotEmpty || showPrice)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (prize.isNotEmpty) _buildPill('Premio: $prize'),
                        if (showPrice)
                          _buildPill(
                            'Precio: ${Money.format(widget.raffle.priceMinor)}',
                          ),
                      ],
                    ),
                  ),
                if (phrase.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      phrase,
                      style: _posterTextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Barra de progreso y detalles
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildProgressBar(),
                ),
                const SizedBox(height: 20),
                // Grid de tickets
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTicketGrid(),
                ),
                if (contact.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone, color: selectedTextColor, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          contact,
                          style: _posterTextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Recuadro con lotería y fecha.
  Widget _buildInfoPanel(DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: template.panelColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: template.panelBorderColor, width: 1),
      ),
      child: Column(
        children: [
          if (widget.raffle.gameType == 'lottery') ...[
            _buildInfoRow(
              Icons.confirmation_number_outlined,
              'Lotería: ${widget.raffle.lotteryNumber}',
            ),
            const SizedBox(height: 8),
          ],
          _buildInfoRow(
            Icons.calendar_today,
            'Fecha: ${dateFormat.format(widget.raffle.date)}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: selectedTextColor, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: _posterTextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: template.panelColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: template.panelBorderColor, width: 1),
      ),
      child: Text(
        text,
        style: _posterTextStyle(
          fontSize: 18,
          shadows: _textShadows(blur: 2, offset: 1),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final total = widget.tickets.length;
    final sold = widget.tickets.where((t) => t.status == 'sold').length;
    final reserved = widget.tickets.where((t) => t.status == 'reserved').length;
    final available = total - sold - reserved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra de progreso visual (opcional)
        if (showProgressBar)
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: template.panelColor,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: sold,
                  child: Container(
                    decoration: BoxDecoration(
                      color: soldColors.background.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.horizontal(
                        left: const Radius.circular(12),
                        right: Radius.circular(
                            reserved == 0 && available == 0 ? 12 : 0),
                      ),
                    ),
                  ),
                ),
                if (reserved > 0)
                  Expanded(
                    flex: reserved,
                    child: Container(
                      decoration: BoxDecoration(
                        color: reservedColors.background.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(available == 0 ? 12 : 0),
                        ),
                      ),
                    ),
                  ),
                if (available > 0)
                  Expanded(
                    flex: available,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            availableColors.background.withValues(alpha: 0.8),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        // Detalles de porcentaje (opcionales)
        if (showPercentageDetails) ...[
          SizedBox(height: showProgressBar ? 8 : 0),
          // Cada etiqueta ocupa un tercio y se encoge si la fuente es ancha,
          // así la leyenda nunca desborda el ancho fijo del póster.
          Row(
            children: [
              _buildStatusLabel('Vendidos', sold, total, soldColors.background),
              _buildStatusLabel(
                  'Reservados', reserved, total, reservedColors.background),
              _buildStatusLabel(
                  'Disponibles', available, total, availableColors.background),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatusLabel(String label, int count, int total, Color color) {
    final percentage =
        total == 0 ? '0.0' : (count / total * 100).toStringAsFixed(1);
    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: _buildStatusLabelContent(label, count, percentage, color),
      ),
    );
  }

  Widget _buildStatusLabelContent(
      String label, int count, String percentage, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border:
                    Border.all(color: template.panelBorderColor, width: 0.5),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: _posterTextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$count ($percentage%)',
          style: _posterTextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTicketGrid() {
    final startIndex = widget.currentPage * 100;
    final endIndex = math.min(startIndex + 100, widget.tickets.length);
    final pageTickets = widget.tickets.sublist(startIndex, endIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ancho disponible descontando el padding horizontal
        final availableWidth = constraints.maxWidth;

        // Encontrar el número más largo para ajustar el tamaño
        final maxDigits = pageTickets.fold<int>(
            0,
            (max, ticket) =>
                math.max(max, _formatTicketNumber(ticket.number).length));

        // Definir el ancho mínimo COMPACTO por ticket (solo lo necesario para el número)
        double desiredTicketWidth;
        double fontSize;

        if (maxDigits <= 2) {
          desiredTicketWidth = 22; // Muy compacto para 1-2 dígitos
          fontSize = 13;
        } else if (maxDigits == 3) {
          desiredTicketWidth = 28; // Compacto para 3 dígitos
          fontSize = 11;
        } else if (maxDigits == 4) {
          desiredTicketWidth = 34; // Justo para 4 dígitos
          fontSize = 10;
        } else {
          desiredTicketWidth = 40; // Mínimo para números muy largos
          fontSize = 9;
        }

        // Espaciado mínimo entre tickets
        const spacing = 3.0;

        // Calcular cuántas columnas caben en el ancho disponible
        int crossAxisCount =
            ((availableWidth + spacing) / (desiredTicketWidth + spacing))
                .floor();

        // Establecer límites para que no queden demasiado pequeños o grandes
        crossAxisCount = math.max(crossAxisCount, 8); // Mínimo 8 columnas
        crossAxisCount = math.min(crossAxisCount, 20); // Máximo 20 columnas

        // Si tenemos pocos tickets, ajustar las columnas
        if (pageTickets.length < crossAxisCount) {
          crossAxisCount = math.max(pageTickets.length, 8);
        }

        // Calcular el ancho real que tendrá cada ticket
        final actualTicketWidth =
            (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

        // Ajustar el tamaño de fuente pero mantenerlo legible
        final adjustedFontSize = math.max(
            fontSize * (actualTicketWidth / desiredTicketWidth),
            8.0 // Tamaño mínimo de fuente para legibilidad
            );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 1, // Mantener cuadrados compactos
          ),
          itemCount: pageTickets.length,
          itemBuilder: (context, index) {
            final ticket = pageTickets[index];
            return Container(
              decoration: BoxDecoration(
                color: _getTicketColor(ticket.status)
                    .withValues(alpha: gridOpacity),
                borderRadius: BorderRadius.circular(6), // Bordes más pequeños
                border: Border.all(
                  color: template.panelBorderColor.withValues(alpha: 0.5),
                  width: 0.5, // Borde más delgado
                ),
              ),
              child: Center(
                child: Text(
                  _formatTicketNumber(ticket.number),
                  style: _posterTextStyle(
                    fontSize: adjustedFontSize,
                    color: _getTicketTextColor(ticket.status),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLogoContainer() {
    final imagePath = widget.raffle.imagePath;
    if (!showLogo || imagePath == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: isLogoRounded ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isLogoRounded ? null : BorderRadius.circular(16),
        image: DecorationImage(
          image: FileImage(File(imagePath)),
          fit: BoxFit.cover,
        ),
        border: Border.all(
          color: template.panelBorderColor,
          width: 2,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Controles
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }

  Widget _buildTemplatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Plantilla'),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: PosterTemplates.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = PosterTemplates.all[index];
              return PosterTemplateThumbnail(
                template: item,
                selected: item.id == template.id,
                onTap: () => _applyTemplate(item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPosterFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Datos del póster'),
        _buildPosterField(
          responsibleController,
          label: 'Responsable',
          hint: 'Nombre de quien organiza',
        ),
        _buildPosterField(
          prizeController,
          label: 'Premio',
          hint: 'Ej.: una moto o \$1.000.000',
        ),
        _buildPosterField(
          contactController,
          label: 'Contacto',
          hint: 'WhatsApp o teléfono',
        ),
        _buildPosterField(
          phraseController,
          label: 'Frase',
          hint: 'Ej.: Juega el viernes con la Lotería de Risaralda',
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPosterField(
    TextEditingController controller, {
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildBackgroundSection() {
    return ExpansionTile(
      title: const Text('Fondo'),
      subtitle: Text(useBackgroundImage ? 'Imagen' : 'Color sólido'),
      children: [
        // El grupo lo gestiona el ancestro `RadioGroup`; cada `Radio` solo
        // declara su valor.
        RadioGroup<bool>(
          groupValue: useBackgroundImage,
          onChanged: (value) => setState(() {
            useBackgroundImage = value ?? false;
          }),
          child: Column(
            children: [
              ListTile(
                title: const Text('Color sólido'),
                leading: const Radio<bool>(value: false),
                trailing: _buildColorSwatch(
                  color: selectedBackgroundColor,
                  onTap: useBackgroundImage
                      ? null
                      : () => _pickColor(
                            title: 'Color de fondo',
                            initialColor: selectedBackgroundColor,
                            onChanged: (color) =>
                                selectedBackgroundColor = color,
                          ),
                ),
              ),
              ListTile(
                title: const Text('Imagen'),
                subtitle: const Text('Reemplaza el color y el patrón'),
                leading: const Radio<bool>(value: true),
                trailing: IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: useBackgroundImage ? _pickBackgroundImage : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFontSelector() {
    return ListTile(
      title: const Text('Fuente del texto'),
      trailing: DropdownButton<String>(
        value: selectedFontFamily ?? _defaultFontLabel,
        items: [
          const DropdownMenuItem(
            value: _defaultFontLabel,
            child: Text(_defaultFontLabel),
          ),
          for (final family in _fontOptions)
            DropdownMenuItem(
              value: family,
              child: Text(family, style: GoogleFonts.getFont(family)),
            ),
        ],
        onChanged: (value) => setState(() {
          selectedFontFamily = value == _defaultFontLabel ? null : value;
        }),
      ),
    );
  }

  Widget _buildTicketColorsSection() {
    return ExpansionTile(
      title: const Text('Colores de los tickets'),
      subtitle: const Text('Fondo y texto según el estado'),
      children: [
        _buildStatusColorRow('Disponibles', availableColors),
        _buildStatusColorRow('Reservados', reservedColors),
        _buildStatusColorRow('Vendidos', soldColors),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _resetTicketColorsTo(template)),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Restablecer'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusColorRow(String label, _StatusColors colors) {
    final usesGlobalText = colors.text == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
          _buildLabeledSwatch(
            label: 'Fondo',
            color: colors.background,
            onTap: () => _pickColor(
              title: 'Fondo de $label',
              initialColor: colors.background,
              onChanged: (color) => colors.background = color,
            ),
          ),
          const SizedBox(width: 12),
          _buildLabeledSwatch(
            label: 'Texto',
            color: colors.text ?? selectedTextColor,
            onTap: () => _pickColor(
              title: 'Texto de $label',
              initialColor: colors.text ?? selectedTextColor,
              onChanged: (color) => colors.text = color,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Usar el color de texto global',
            visualDensity: VisualDensity.compact,
            onPressed: usesGlobalText
                ? null
                : () => setState(() => colors.text = null),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledSwatch({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildColorSwatch(color: color, onTap: onTap, size: 36),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildVisibilityControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Elementos visibles'),
        SwitchListTile(
          title: const Text('Mostrar fecha y lotería'),
          value: showDateAndLottery,
          onChanged: (value) => setState(() => showDateAndLottery = value),
        ),
        SwitchListTile(
          title: const Text('Mostrar precio'),
          value: showPrice,
          onChanged: (value) => setState(() => showPrice = value),
        ),
        SwitchListTile(
          title: const Text('Mostrar barra de progreso'),
          value: showProgressBar,
          onChanged: (value) => setState(() => showProgressBar = value),
        ),
        SwitchListTile(
          title: const Text('Mostrar detalles de porcentaje'),
          value: showPercentageDetails,
          onChanged: (value) => setState(() => showPercentageDetails = value),
        ),
        SwitchListTile(
          title: const Text('Texto en negrita'),
          value: isBoldText,
          onChanged: (value) => setState(() => isBoldText = value),
        ),
        if (widget.raffle.imagePath != null) ...[
          SwitchListTile(
            title: const Text('Mostrar logo'),
            value: showLogo,
            onChanged: (value) => setState(() {
              showLogo = value;
              titleSize = value ? 24 : 28;
            }),
          ),
          if (showLogo) ...[
            SwitchListTile(
              title: const Text('Logo redondeado'),
              value: isLogoRounded,
              onChanged: (value) => setState(() => isLogoRounded = value),
            ),
            ListTile(
              title: const Text('Tamaño del logo'),
              subtitle: Slider(
                value: logoSize,
                min: 60,
                max: 140,
                onChanged: (value) => setState(() => logoSize = value),
              ),
            ),
          ],
        ],
        ListTile(
          title: const Text('Tamaño del título'),
          subtitle: Slider(
            value: titleSize,
            min: 18,
            max: widget.raffle.imagePath == null || !showLogo ? 32 : 28,
            onChanged: (value) => setState(() => titleSize = value),
          ),
        ),
        ListTile(
          title: const Text('Opacidad de los tickets'),
          subtitle: Slider(
            value: gridOpacity,
            min: 0.3,
            max: 1.0,
            onChanged: (value) => setState(() => gridOpacity = value),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartir Rifa'),
        actions: [
          if (!isProcessing) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _exportImage(share: true),
              tooltip: 'Compartir',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _exportImage(share: false),
              tooltip: 'Guardar',
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      // SingleChildScrollView mantiene la vista previa montada aunque el
      // usuario baje hasta el final. ListView la desmontaba al salir del
      // viewport y la captura fallaba con "Null check operator used on a
      // null value".
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vista previa a ancho fijo, escalada para caber en pantalla.
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: _posterWidth,
                    child: _buildPoster(),
                  ),
                ),
              ),
            ),

            // Opciones de personalización
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personalización',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTemplatePicker(),
                      const SizedBox(height: 8),
                      _buildPosterFields(),
                      const SizedBox(height: 8),
                      _buildBackgroundSection(),
                      ListTile(
                        title: const Text('Color de texto'),
                        trailing: _buildColorSwatch(
                          color: selectedTextColor,
                          onTap: () => _pickColor(
                            title: 'Color de texto',
                            initialColor: selectedTextColor,
                            onChanged: (color) => selectedTextColor = color,
                          ),
                        ),
                      ),
                      _buildFontSelector(),
                      _buildTicketColorsSection(),
                      _buildVisibilityControls(),
                      // Mensaje personalizado
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: messageController,
                          decoration: const InputDecoration(
                            labelText: 'Mensaje al compartir',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusColors _statusColorsFor(String status) {
    switch (status) {
      case 'sold':
        return soldColors;
      case 'reserved':
        return reservedColors;
      default:
        return availableColors;
    }
  }

  Color _getTicketColor(String status) => _statusColorsFor(status).background;

  Color _getTicketTextColor(String status) =>
      _statusColorsFor(status).text ?? selectedTextColor;
}

/// Colores configurables de un estado de ticket dentro del póster.
class _StatusColors {
  _StatusColors({required this.background, this.text});

  Color background;

  /// `null` significa que el texto usa el color de texto global.
  Color? text;
}
