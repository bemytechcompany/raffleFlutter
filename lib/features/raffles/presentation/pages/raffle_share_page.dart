import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:raffle/core/money/money.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../../domain/entities/raffle.dart';
import '../../domain/entities/ticket.dart';
import 'dart:math' as math;

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

  @override
  State<RaffleSharePage> createState() => _RaffleSharePageState();
}

class _RaffleSharePageState extends State<RaffleSharePage> {
  final GlobalKey repaintKey = GlobalKey();
  bool isProcessing = false;
  Color selectedBackgroundColor = Colors.deepPurple;
  Color selectedTextColor = Colors.white;
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
  String shareMessage = '¡Participa en nuestra rifa!';
  final TextEditingController messageController = TextEditingController();
  File? backgroundImage;
  bool useBackgroundImage = false;

  /// Colores de fondo y texto de los tickets por estado. Un texto en `null`
  /// hereda [selectedTextColor].
  final _StatusColors availableColors =
      _StatusColors(defaultBackground: Colors.green);
  final _StatusColors reservedColors =
      _StatusColors(defaultBackground: Colors.orange);
  final _StatusColors soldColors = _StatusColors(defaultBackground: Colors.red);

  /// Fuente del póster. `null` usa la fuente del sistema; el resto son
  /// familias de Google Fonts que se descargan y quedan en caché al elegirlas.
  String? selectedFontFamily;
  static const String _defaultFontLabel = 'Predeterminada';
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

  @override
  void initState() {
    super.initState();
    messageController.text = shareMessage;
    if (widget.raffle.imagePath == null) {
      titleSize = 28;
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
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
      // para no exportar con la fuente de respaldo.
      await GoogleFonts.pendingFonts();
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

  /// Estilo de texto del póster: color global, negrita y fuente elegida.
  TextStyle _posterTextStyle({
    required double fontSize,
    Color? color,
    List<Shadow>? shadows,
  }) {
    final base = TextStyle(
      color: color ?? selectedTextColor,
      fontSize: fontSize,
      fontWeight: isBoldText ? FontWeight.bold : FontWeight.normal,
      shadows: shadows,
    );
    final family = selectedFontFamily;
    if (family == null) return base;
    return GoogleFonts.getFont(family, textStyle: base);
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
              color: Colors.white.withValues(alpha: 0.1),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
    final percentage = (count / total * 100).toStringAsFixed(1);
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
                  color: Colors.white.withValues(alpha: 0.2),
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
    if (!showLogo || widget.raffle.imagePath == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: isLogoRounded ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isLogoRounded ? null : BorderRadius.circular(16),
        image: DecorationImage(
          image: FileImage(File(widget.raffle.imagePath!)),
          fit: BoxFit.cover,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'es');

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
            // Vista previa
            Padding(
              padding: const EdgeInsets.all(16),
              child: RepaintBoundary(
                key: repaintKey,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: useBackgroundImage ? null : selectedBackgroundColor,
                    image: useBackgroundImage && backgroundImage != null
                        ? DecorationImage(
                            image: FileImage(backgroundImage!),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildLogoContainer(),
                      SizedBox(
                          height: showLogo && widget.raffle.imagePath != null
                              ? 16
                              : 0),
                      // Título
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          widget.raffle.name,
                          style: _posterTextStyle(
                            fontSize: titleSize,
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black38,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Información de fecha y lotería
                      if (showDateAndLottery)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (widget.raffle.gameType == 'lottery') ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.confirmation_number_outlined,
                                      color: selectedTextColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Lotería: ${widget.raffle.lotteryNumber}',
                                      style: _posterTextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: selectedTextColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Fecha: ${dateFormat.format(widget.raffle.date)}',
                                    style: _posterTextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Precio
                      if (showPrice)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Precio: ${Money.format(widget.raffle.priceMinor)}',
                            style: _posterTextStyle(
                              fontSize: 18,
                              shadows: const [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black38,
                                ),
                              ],
                            ),
                          ),
                        ),
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
                      const SizedBox(height: 20),
                    ],
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
                      const SizedBox(height: 16),

                      // Fondo
                      ExpansionTile(
                        title: const Text('Fondo'),
                        children: [
                          // El grupo lo gestiona el ancestro `RadioGroup`; cada
                          // `Radio` solo declara su valor.
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
                                              initialColor:
                                                  selectedBackgroundColor,
                                              onChanged: (color) =>
                                                  selectedBackgroundColor =
                                                      color,
                                            ),
                                  ),
                                ),
                                ListTile(
                                  title: const Text('Imagen'),
                                  leading: const Radio<bool>(value: true),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.image),
                                    onPressed: useBackgroundImage
                                        ? _pickBackgroundImage
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Color de texto
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

                      // Fuente del texto
                      ListTile(
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
                                child: Text(
                                  family,
                                  style: GoogleFonts.getFont(family),
                                ),
                              ),
                          ],
                          onChanged: (value) => setState(() {
                            selectedFontFamily =
                                value == _defaultFontLabel ? null : value;
                          }),
                        ),
                      ),

                      // Colores de los tickets por estado
                      ExpansionTile(
                        title: const Text('Colores de los tickets'),
                        subtitle: const Text('Fondo y texto según el estado'),
                        children: [
                          _buildStatusColorRow('Disponibles', availableColors),
                          _buildStatusColorRow('Reservados', reservedColors),
                          _buildStatusColorRow('Vendidos', soldColors),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _resetTicketColors,
                              icon: const Icon(Icons.restart_alt),
                              label: const Text('Restablecer'),
                            ),
                          ),
                        ],
                      ),

                      // Controles de visibilidad
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Elementos visibles',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      // Mostrar fecha y lotería
                      SwitchListTile(
                        title: const Text('Mostrar fecha y lotería'),
                        value: showDateAndLottery,
                        onChanged: (value) =>
                            setState(() => showDateAndLottery = value),
                      ),

                      // Mostrar precio
                      SwitchListTile(
                        title: const Text('Mostrar precio'),
                        value: showPrice,
                        onChanged: (value) => setState(() => showPrice = value),
                      ),

                      // Mostrar barra de progreso
                      SwitchListTile(
                        title: const Text('Mostrar barra de progreso'),
                        value: showProgressBar,
                        onChanged: (value) =>
                            setState(() => showProgressBar = value),
                      ),

                      // Mostrar detalles de porcentaje
                      SwitchListTile(
                        title: const Text('Mostrar detalles de porcentaje'),
                        value: showPercentageDetails,
                        onChanged: (value) =>
                            setState(() => showPercentageDetails = value),
                      ),

                      // Texto en negrita
                      SwitchListTile(
                        title: const Text('Texto en negrita'),
                        value: isBoldText,
                        onChanged: (value) =>
                            setState(() => isBoldText = value),
                      ),

                      // Opciones de logo
                      if (widget.raffle.imagePath != null) ...[
                        SwitchListTile(
                          title: const Text('Mostrar logo'),
                          value: showLogo,
                          onChanged: (value) => setState(() {
                            showLogo = value;
                            if (!value) {
                              titleSize = 28;
                            } else {
                              titleSize = 24;
                            }
                          }),
                        ),
                        if (showLogo) ...[
                          SwitchListTile(
                            title: const Text('Logo redondeado'),
                            value: isLogoRounded,
                            onChanged: (value) =>
                                setState(() => isLogoRounded = value),
                          ),
                          ListTile(
                            title: const Text('Tamaño del logo'),
                            subtitle: Slider(
                              value: logoSize,
                              min: 60,
                              max: 140,
                              onChanged: (value) =>
                                  setState(() => logoSize = value),
                            ),
                          ),
                        ],
                      ],

                      // Tamaño del título
                      ListTile(
                        title: const Text('Tamaño del título'),
                        subtitle: Slider(
                          value: titleSize,
                          min: 18,
                          max: widget.raffle.imagePath == null || !showLogo
                              ? 32
                              : 28,
                          onChanged: (value) =>
                              setState(() => titleSize = value),
                        ),
                      ),

                      // Opacidad del grid
                      ListTile(
                        title: const Text('Opacidad de los tickets'),
                        subtitle: Slider(
                          value: gridOpacity,
                          min: 0.3,
                          max: 1.0,
                          onChanged: (value) =>
                              setState(() => gridOpacity = value),
                        ),
                      ),

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

  void _resetTicketColors() {
    setState(() {
      availableColors.reset();
      reservedColors.reset();
      soldColors.reset();
    });
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
}

/// Colores configurables de un estado de ticket dentro del póster.
class _StatusColors {
  _StatusColors({required this.defaultBackground})
      : background = defaultBackground;

  final Color defaultBackground;
  Color background;

  /// `null` significa que el texto usa el color de texto global.
  Color? text;

  void reset() {
    background = defaultBackground;
    text = null;
  }
}
