import 'package:flutter/material.dart';
import 'package:raffle/core/theme/app_colors.dart';
import 'package:raffle/features/raffles/domain/entities/ticket.dart';
import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/core/widgets/keyboard_dismissible.dart';

class TicketModal extends StatefulWidget {
  final Ticket ticket;
  final void Function(Ticket ticket) onSubmit;
  final VoidCallback onClose;
  final bool isSubmitting;
  final Raffle? raffle;

  const TicketModal({
    super.key,
    required this.ticket,
    required this.onSubmit,
    required this.onClose,
    this.isSubmitting = false,
    this.raffle,
  });

  @override
  State<TicketModal> createState() => _TicketModalState();
}

class _TicketModalState extends State<TicketModal> with TickerProviderStateMixin {
  late String _status;
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Map<String, String> _errors = {};
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _status = widget.ticket.status;
    _nameCtrl.text = widget.ticket.buyerName ?? '';
    _contactCtrl.text = widget.ticket.buyerContact ?? '';
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Función para obtener el factor de escala basado en el ancho de pantalla
  double _getScaleFactor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 0.8;  // Pantallas muy pequeñas
    if (screenWidth < 480) return 0.9;  // Pantallas pequeñas
    if (screenWidth < 768) return 1.0;  // Pantallas medianas
    return 1.1; // Pantallas grandes
  }

  // Función para obtener tamaños de fuente escalados
  double _getFontSize(BuildContext context, double baseSize) {
    return baseSize * _getScaleFactor(context);
  }

  // Función para obtener espaciado escalado
  double _getSpacing(BuildContext context, double baseSpacing) {
    return baseSpacing * _getScaleFactor(context);
  }

  // Función para obtener altura de botones escalada
  double _getButtonHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 600) return 48; // Pantallas muy bajas
    if (screenHeight < 800) return 54; // Pantallas normales
    return 60; // Pantallas altas
  }

  void _save() {
    if (_validate()) {
      final updatedTicket = widget.ticket.copyWith(
        status: _status,
        buyerName: _status == 'available' ? null : _nameCtrl.text.trim(),
        buyerContact: _status == 'available' ? null : _contactCtrl.text.trim(),
      );
      widget.onSubmit(updatedTicket);
    }
  }

  bool _validate() {
    if (_status != 'available') {
      _errors = {};
      if (_nameCtrl.text.trim().isEmpty) {
        setState(() {
          _errors['name'] = 'El nombre del comprador es obligatorio';
        });
      }
      if (_contactCtrl.text.trim().isEmpty) {
        setState(() {
          _errors['contact'] = 'La información de contacto es obligatoria';
        });
      }
      return _errors.isEmpty;
    }
    return true;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'sold':
        return const Color(0xFFE53E3E); // Rojo más vibrante
      case 'reserved':
        return const Color(0xFFFF8C00); // Naranja más rico
      case 'available':
        return const Color(0xFF38A169); // Verde más moderno
      default:
        return Colors.grey;
    }
  }

  Color _getStatusSecondaryColor(String status) {
    switch (status) {
      case 'sold':
        return const Color(0xFFFF6B6B);
      case 'reserved':
        return const Color(0xFFFFB347);
      case 'available':
        return const Color(0xFF68D391);
      default:
        return Colors.grey.shade400;
    }
  }

  String _getButtonText() {
    switch (_status) {
      case 'sold':
        return 'Confirmar Venta';
      case 'reserved':
        return 'Confirmar Reserva';
      case 'available':
        return 'Liberar Ticket';
      default:
        return 'Guardar Cambios';
    }
  }

  Widget _statusButton(BuildContext context, String value, Color color) {
    final isSelected = _status == value;
    final isRaffleExpired = widget.raffle?.status == 'expired';
    final isDisabled = isRaffleExpired == true && (value == 'sold' || value == 'reserved');
    String label;
    IconData icon;
    
    switch (value) {
      case 'sold':
        label = 'VENDIDO';
        icon = Icons.monetization_on_rounded;
        break;
      case 'reserved':
        label = 'RESERVADO';
        icon = Icons.bookmark_added_rounded;
        break;
      case 'available':
        label = 'DISPONIBLE';
        icon = Icons.check_circle_rounded;
        break;
      default:
        label = value.toUpperCase();
        icon = Icons.circle;
    }
    
    return Padding(
      padding: EdgeInsets.only(bottom: _getSpacing(context, 12.0)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: _getButtonHeight(context),
        decoration: BoxDecoration(
          gradient: isDisabled ? LinearGradient(
            colors: [
              Colors.grey[900]!,
              Colors.grey[800]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : isSelected ? LinearGradient(
            colors: [
              color.withOpacity(0.8), 
              color,
              _getStatusSecondaryColor(value),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : LinearGradient(
            colors: [
              Colors.grey[800]!,
              Colors.grey[700]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : () => setState(() => _status = value),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: _getSpacing(context, 16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(_getSpacing(context, 6)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isSelected ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isDisabled ? Colors.grey[600] : Colors.white,
                      size: _getFontSize(context, 20),
                    ),
                  ),
                  SizedBox(width: _getSpacing(context, 12)),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: _getSpacing(context, 4)),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isDisabled ? Colors.grey[600] : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: _getFontSize(context, 14),
                          letterSpacing: 0.5,
                        ),
                        softWrap: true,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentlySoldOrReserved = 
        widget.ticket.status == 'sold' || widget.ticket.status == 'reserved';
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 480;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 20,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isSmallScreen ? screenWidth * 0.95 : 450,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: KeyboardDismissible(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(_getSpacing(context, 28)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header mejorado con efecto glassmorphism
                    Container(
                      padding: EdgeInsets.all(_getSpacing(context, 20)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(_getSpacing(context, 12)),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.confirmation_number_rounded,
                                    color: Colors.white,
                                    size: _getFontSize(context, 22),
                                  ),
                                ),
                                SizedBox(width: _getSpacing(context, 16)),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ticket',
                                        style: TextStyle(
                                          fontSize: _getFontSize(context, 14),
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                      Text(
                                        '#${widget.ticket.number}',
                                        style: TextStyle(
                                          fontSize: _getFontSize(context, 24),
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: widget.onClose,
                              icon: const Icon(Icons.close_rounded),
                              splashRadius: 20,
                              iconSize: _getFontSize(context, 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: _getSpacing(context, 28)),
                    
                    if (isCurrentlySoldOrReserved && _status != 'available') ...[
                      Container(
                        padding: EdgeInsets.all(_getSpacing(context, 20)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getStatusColor(widget.ticket.status).withOpacity(0.1),
                              _getStatusColor(widget.ticket.status).withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(widget.ticket.status).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(_getSpacing(context, 8)),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(widget.ticket.status),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getStatusColor(widget.ticket.status).withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    widget.ticket.status == 'sold' 
                                        ? Icons.monetization_on_rounded 
                                        : Icons.bookmark_added_rounded,
                                    color: Colors.white,
                                    size: _getFontSize(context, 16),
                                  ),
                                ),
                                SizedBox(width: _getSpacing(context, 12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Estado Actual',
                                        style: TextStyle(
                                          fontSize: _getFontSize(context, 12),
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                      Text(
                                        widget.ticket.status == 'sold' ? 'Vendido' : 'Reservado',
                                        style: TextStyle(
                                          fontSize: _getFontSize(context, 16),
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(widget.ticket.status),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: _getSpacing(context, 20)),
                            
                            Container(
                              padding: EdgeInsets.all(_getSpacing(context, 18)),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(_getSpacing(context, 6)),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.person_rounded,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: _getFontSize(context, 18),
                                        ),
                                      ),
                                      SizedBox(width: _getSpacing(context, 12)),
                                      Text(
                                        'Información del Comprador',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: _getFontSize(context, 14),
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: _getSpacing(context, 16)),
                                  Container(
                                    padding: EdgeInsets.all(_getSpacing(context, 14)),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                          Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.ticket.buyerName ?? '',
                                          style: TextStyle(
                                            fontSize: _getFontSize(context, 16),
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          softWrap: true,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: _getSpacing(context, 8)),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone_rounded,
                                              size: _getFontSize(context, 14),
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            SizedBox(width: _getSpacing(context, 6)),
                                            Expanded(
                                              child: Text(
                                                widget.ticket.buyerContact ?? '',
                                                style: TextStyle(
                                                  fontSize: _getFontSize(context, 14),
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                ),
                                                softWrap: true,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: _getSpacing(context, 24)),
                      
                      if (widget.ticket.status == 'reserved')
                        Container(
                          height: _getButtonHeight(context),
                          margin: EdgeInsets.only(bottom: _getSpacing(context, 16)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFE53E3E),
                                const Color(0xFFFF6B6B),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE53E3E).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => setState(() => _status = 'sold'),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: _getSpacing(context, 20)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(_getSpacing(context, 6)),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.monetization_on_rounded, 
                                        color: Colors.white,
                                        size: _getFontSize(context, 18),
                                      ),
                                    ),
                                    SizedBox(width: _getSpacing(context, 12)),
                                    Text(
                                      'Convertir a Vendido',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: _getFontSize(context, 14),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      Container(
                        height: _getButtonHeight(context),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            width: 2,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.surface,
                              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _status = 'available';
                                _nameCtrl.clear();
                                _contactCtrl.clear();
                              });
                              final updatedTicket = widget.ticket.copyWith(
                                status: 'available',
                                buyerName: null,
                                buyerContact: null,
                              );
                              widget.onSubmit(updatedTicket);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: _getSpacing(context, 20)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cancel_rounded,
                                    size: _getFontSize(context, 18),
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  SizedBox(width: _getSpacing(context, 12)),
                                  Text(
                                    'Cancelar Venta/Reserva',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: _getFontSize(context, 14),
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: EdgeInsets.all(_getSpacing(context, 20)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(_getSpacing(context, 8)),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.tune_rounded,
                                    color: Colors.white,
                                    size: _getFontSize(context, 18),
                                  ),
                                ),
                                SizedBox(width: _getSpacing(context, 12)),
                                Text(
                                  'Configurar Estado',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: _getFontSize(context, 16),
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: _getSpacing(context, 16)),
                            
                            // Mensaje informativo cuando la rifa está expirada
                            if (widget.raffle?.status == 'expired') ...[
                              Container(
                                padding: EdgeInsets.all(_getSpacing(context, 12)),
                                margin: EdgeInsets.only(bottom: _getSpacing(context, 16)),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.orange,
                                      size: _getFontSize(context, 20),
                                    ),
                                    SizedBox(width: _getSpacing(context, 12)),
                                    Expanded(
                                      child: Text(
                                        'Esta rifa ha finalizado. Solo se pueden liberar tickets, no vender ni reservar.',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: _getFontSize(context, 13),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            _statusButton(context, 'sold', const Color(0xFFE53E3E)),
                            _statusButton(context, 'reserved', const Color(0xFFFF8C00)),
                            _statusButton(context, 'available', const Color(0xFF38A169)),
                          ],
                        ),
                      ),
                    ],
                    
                    SizedBox(height: _getSpacing(context, 24)),
                    
                    if (_status != 'available') ...[
                      Container(
                        padding: EdgeInsets.all(_getSpacing(context, 20)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(_getSpacing(context, 8)),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.secondary,
                                          Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.person_add_rounded,
                                      color: Colors.white,
                                      size: _getFontSize(context, 18),
                                    ),
                                  ),
                                  SizedBox(width: _getSpacing(context, 12)),
                                  Expanded(
                                    child: Text(
                                      'Configurar Comprador',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: _getFontSize(context, 16),
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: _getSpacing(context, 20)),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _nameCtrl,
                                  style: TextStyle(fontSize: _getFontSize(context, 14)),
                                  decoration: InputDecoration(
                                    labelText: 'Nombre del comprador',
                                    labelStyle: TextStyle(
                                      fontSize: _getFontSize(context, 12),
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    prefixIcon: Container(
                                      margin: EdgeInsets.all(_getSpacing(context, 8)),
                                      padding: EdgeInsets.all(_getSpacing(context, 6)),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: _getFontSize(context, 18),
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    errorText: _errors['name'],
                                    errorStyle: TextStyle(fontSize: _getFontSize(context, 11)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: _getSpacing(context, 20),
                                      vertical: _getSpacing(context, 16),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: _getSpacing(context, 16)),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _contactCtrl,
                                  style: TextStyle(fontSize: _getFontSize(context, 14)),
                                  decoration: InputDecoration(
                                    labelText: 'Información de contacto',
                                    labelStyle: TextStyle(
                                      fontSize: _getFontSize(context, 12),
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    prefixIcon: Container(
                                      margin: EdgeInsets.all(_getSpacing(context, 8)),
                                      padding: EdgeInsets.all(_getSpacing(context, 6)),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.phone_rounded,
                                        size: _getFontSize(context, 18),
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    errorText: _errors['contact'],
                                    errorStyle: TextStyle(fontSize: _getFontSize(context, 11)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: _getSpacing(context, 20),
                                      vertical: _getSpacing(context, 16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    SizedBox(height: _getSpacing(context, 32)),
                    
                    Container(
                      height: _getButtonHeight(context) + 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(_status),
                            _getStatusSecondaryColor(_status),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(_status).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.isSubmitting ? null : _save,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: _getSpacing(context, 24)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.isSubmitting)
                                  Container(
                                    width: _getFontSize(context, 18),
                                    height: _getFontSize(context, 18),
                                    margin: EdgeInsets.only(right: _getSpacing(context, 12)),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  Container(
                                    padding: EdgeInsets.all(_getSpacing(context, 6)),
                                    margin: EdgeInsets.only(right: _getSpacing(context, 12)),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _status == 'available'
                                          ? Icons.check_circle_rounded
                                          : _status == 'sold'
                                              ? Icons.monetization_on_rounded
                                              : Icons.bookmark_added_rounded,
                                      color: Colors.white,
                                      size: _getFontSize(context, 20),
                                    ),
                                  ),
                                Text(
                                  _getButtonText(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: _getFontSize(context, 16),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}