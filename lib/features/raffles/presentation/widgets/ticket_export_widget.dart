import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:gal/gal.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/raffle.dart';

class TicketExportWidget extends StatefulWidget {
  final Ticket ticket;
  final Raffle raffle;

  const TicketExportWidget({
    super.key, 
    required this.ticket,
    required this.raffle,
  });

  @override
  State<TicketExportWidget> createState() => _TicketExportWidgetState();
}

class _TicketExportWidgetState extends State<TicketExportWidget> {
  final GlobalKey repaintKey = GlobalKey();
  bool isProcessing = false;

  Future<void> _exportTicket({required bool share}) async {
    if (isProcessing) return; // Prevenir múltiples ejecuciones
    
    try {
      setState(() => isProcessing = true);
      final boundary = repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      if (share) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/ticket.png').create();
        await file.writeAsBytes(pngBytes);
        
        try {
          if (kDebugMode) {
            print('📱 TicketExport - Iniciando compartir en ${Platform.isIOS ? 'iOS' : 'Android'}');
          }
          
          // Timeout de seguridad para iOS
          if (Platform.isIOS) {
            await Future.any([
              Share.shareXFiles([XFile(file.path)], text: '¡Gracias por participar!'),
              Future.delayed(const Duration(seconds: 10)), // Timeout de 10 segundos
            ]);
          } else {
            await Share.shareXFiles([XFile(file.path)], text: '¡Gracias por participar!');
          }
          
          if (kDebugMode) {
            print('📱 TicketExport - Compartir completado');
          }
        } catch (e) {
          if (kDebugMode) {
            print('📱 TicketExport - Error al compartir: $e');
          }
        } finally {
          // Resetear el estado siempre, sin importar la plataforma
          if (mounted) {
            if (kDebugMode) {
              print('📱 TicketExport - Reseteando estado isProcessing = false');
            }
            setState(() => isProcessing = false);
          }
        }
      } else {
        final hasAccess = await Gal.hasAccess(toAlbum: true);
        if (!hasAccess) {
           await Gal.requestAccess(toAlbum: true);
        }

        if (await Gal.hasAccess(toAlbum: true)){
           await Gal.putImageBytes(pngBytes, album: 'RaffleTickets');
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
        
        if (mounted) {
          setState(() => isProcessing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
        setState(() => isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final raffle = widget.raffle;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
      locale: 'es',
    );

    return Column(
      children: [
        RepaintBoundary(
          key: repaintKey,
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'TICKET DE RIFA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.white24, height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Columna izquierda
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.buyerName ?? '—',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lotería #${ticket.raffleId}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '#${ticket.number} ',
                            style: const TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 12),
                            decoration: BoxDecoration(
                              color: _statusColor(ticket.status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _translateStatus(ticket.status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fecha del sorteo: ${dateFormat.format(raffle.date)}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          Text(
                            'Precio: ${currencyFormat.format(raffle.price)}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Columna derecha
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INFORMACIÓN DEL COMPRADOR',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Nombre: ${ticket.buyerName ?? '—'}',
                              style: const TextStyle(color: Colors.white)),
                          Text('Contacto: ${ticket.buyerContact ?? '—'}',
                              style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 16),
                          Center(
                            child: QrImageView(
                              data:
                                  'Ticket #${ticket.number}\nEstado: ${ticket.status}\nNombre: ${ticket.buyerName}\nContacto: ${ticket.buyerContact}',
                              version: QrVersions.auto,
                              size: 100,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    '¡GRACIAS POR PARTICIPAR!',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!isProcessing)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportTicket(share: true),
                  icon: const Icon(Icons.share),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonGreenBackground,
                    foregroundColor: AppColors.buttonGreenForeground,
                    side: BorderSide(color: AppColors.buttonGreenBorder),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportTicket(share: false),
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonGreenBackground,
                    foregroundColor: AppColors.buttonGreenForeground,
                    side: BorderSide(color: AppColors.buttonGreenBorder),
                  ),
                ),
              ),
            ],
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'sold':
        return Colors.red;
      case 'reserved':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Disponible';
      case 'reserved':
        return 'Reservado';
      case 'sold':
      default:
        return 'Vendido';
    }
  }
}
