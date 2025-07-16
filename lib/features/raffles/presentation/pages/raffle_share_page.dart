import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
    try {
      setState(() => isProcessing = true);
      final boundary = repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      if (share) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/raffle_share.png').create();
        await file.writeAsBytes(pngBytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: messageController.text,
        );
      } else {
        if (Platform.isIOS) {
          // En iOS, guardamos directamente en la galería usando image_picker
          final tempDir = await getTemporaryDirectory();
          final file = await File('${tempDir.path}/raffle_share.png').create();
          await file.writeAsBytes(pngBytes);
          await Share.shareXFiles([XFile(file.path)]);
        } else {
          // En Android, usamos gal
          final hasAccess = await Gal.hasAccess(toAlbum: true);
          if (!hasAccess) {
            await Gal.requestAccess(toAlbum: true);
          }

          if (await Gal.hasAccess(toAlbum: true)) {
            await Gal.putImageBytes(pngBytes, album: 'RaffleShares');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Imagen guardada en la galería')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permiso de galería denegado')),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Color de Fondo'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedBackgroundColor,
            onColorChanged: (color) =>
                setState(() => selectedBackgroundColor = color),
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            displayThumbColor: true,
            showLabel: true,
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

  void _showTextColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Color de Texto'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedTextColor,
            onColorChanged: (color) =>
                setState(() => selectedTextColor = color),
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            displayThumbColor: true,
            showLabel: true,
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
              color: Colors.white.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: sold,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
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
                        color: Colors.orange.withOpacity(0.8),
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
                        color: Colors.green.withOpacity(0.8),
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
              _buildStatusLabel('Vendidos', sold, total, Colors.red),
              _buildStatusLabel('Reservados', reserved, total, Colors.orange),
              _buildStatusLabel('Disponibles', available, total, Colors.green),
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
                color: color.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selectedTextColor,
                fontSize: 12,
                fontWeight: isBoldText ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$count ($percentage%)',
          style: TextStyle(
            color: selectedTextColor,
            fontSize: 12,
            fontWeight: isBoldText ? FontWeight.bold : FontWeight.normal,
          ),
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
            0, (max, ticket) => math.max(max, ticket.number.toString().length));

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
                color: _getTicketColor(ticket.status).withOpacity(gridOpacity),
                borderRadius: BorderRadius.circular(6), // Bordes más pequeños
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5, // Borde más delgado
                ),
              ),
              child: Center(
                child: Text(
                  '${ticket.number}',
                  style: TextStyle(
                    color: selectedTextColor,
                    fontWeight: isBoldText ? FontWeight.bold : FontWeight.normal,
                    fontSize: adjustedFontSize,
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
    if (!showLogo || widget.raffle.imagePath == null)
      return const SizedBox.shrink();

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
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
      locale: 'es_MX',
    );

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
      body: ListView(
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
                      child:                       Text(
                        widget.raffle.name,
                        style: TextStyle(
                          color: selectedTextColor,
                          fontSize: titleSize,
                          fontWeight: isBoldText ? FontWeight.bold : FontWeight.normal,
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
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
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
                                    style: TextStyle(
                                      color: selectedTextColor,
                                      fontSize: 16,
                                      fontWeight: isBoldText ? FontWeight.bold : FontWeight.normal,
                                    ),
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
                                  style: TextStyle(
                                    color: selectedTextColor,
                                    fontSize: 16,
                                    fontWeight: isBoldText ? FontWeight.bold : FontWeight.normal,
                                  ),
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Precio: ${currencyFormat.format(widget.raffle.price)}',
                          style: TextStyle(
                            color: selectedTextColor,
                            fontSize: 18,
                            fontWeight: isBoldText ? FontWeight.bold : FontWeight.normal,
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
                        ListTile(
                          title: const Text('Color sólido'),
                          leading: Radio<bool>(
                            value: false,
                            groupValue: useBackgroundImage,
                            onChanged: (value) => setState(() {
                              useBackgroundImage = value!;
                            }),
                          ),
                          trailing: GestureDetector(
                            onTap: useBackgroundImage ? null : _showColorPicker,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: selectedBackgroundColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        ListTile(
                          title: const Text('Imagen'),
                          leading: Radio<bool>(
                            value: true,
                            groupValue: useBackgroundImage,
                            onChanged: (value) => setState(() {
                              useBackgroundImage = value!;
                            }),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.image),
                            onPressed: useBackgroundImage
                                ? _pickBackgroundImage
                                : null,
                          ),
                        ),
                      ],
                    ),

                    // Color de texto
                    ListTile(
                      title: const Text('Color de texto'),
                      trailing: GestureDetector(
                        onTap: _showTextColorPicker,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selectedTextColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                      ),
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
                      onChanged: (value) => setState(() => isBoldText = value),
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
                        onChanged: (value) => setState(() => titleSize = value),
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
    );
  }

  Color _getTicketColor(String status) {
    switch (status) {
      case 'sold':
        return Colors.red;
      case 'reserved':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}
