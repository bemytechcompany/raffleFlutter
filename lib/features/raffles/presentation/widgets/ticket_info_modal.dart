import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:raffle/features/raffles/domain/entities/ticket.dart';
import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'ticket_export_widget.dart';

class TicketInfoModal extends StatefulWidget {
  const TicketInfoModal({
    super.key,
    required this.ticket,
    required this.raffle,
    required this.onClose,
    required this.onEdit,
  });
  final Ticket? ticket;
  final Raffle raffle;
  final VoidCallback onClose;
  final Function(Ticket) onEdit;

  @override
  State<TicketInfoModal> createState() => _TicketInfoModalState();
}

class _TicketInfoModalState extends State<TicketInfoModal> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late String _status;
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _status = widget.ticket?.status ?? 'available';
    
    // Inicializar los controladores de texto de forma segura para iOS
    _nameCtrl.text = widget.ticket?.buyerName ?? '';
    _contactCtrl.text = widget.ticket?.buyerContact ?? '';
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
    
    // Asegurar que los datos se establezcan correctamente en iOS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Debug para iOS
        if (kDebugMode) {
          print('🎫 TicketInfoModal - Ticket data:');
          print('  Status: ${widget.ticket?.status}');
          print('  Buyer Name: ${widget.ticket?.buyerName}');
          print('  Buyer Contact: ${widget.ticket?.buyerContact}');
          print('  Platform: ${defaultTargetPlatform}');
        }
        
        setState(() {
          _nameCtrl.text = widget.ticket?.buyerName ?? '';
          _contactCtrl.text = widget.ticket?.buyerContact ?? '';
        });
      }
    });
  }

  @override
  void didUpdateWidget(TicketInfoModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar los datos si el ticket cambió
    if (oldWidget.ticket != widget.ticket) {
      setState(() {
        _status = widget.ticket?.status ?? 'available';
        _nameCtrl.text = widget.ticket?.buyerName ?? '';
        _contactCtrl.text = widget.ticket?.buyerContact ?? '';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _nameCtrl.dispose();
    _contactCtrl.dispose();
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

  void _save() {
    if (_validate()) {
      final updatedTicket = widget.ticket!.copyWith(
        status: _status,
        buyerName: _status == 'available' ? null : _nameCtrl.text.trim(),
        buyerContact: _status == 'available' ? null : _contactCtrl.text.trim(),
      );
      widget.onEdit(updatedTicket);
      widget.onClose();
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

  Widget _buildStatusButton(String value, String label, IconData icon, Color color) {
    final isSelected = _status == value;
    final isRaffleExpired = widget.raffle.status == 'expired';
    final isDisabled = isRaffleExpired && (value == 'sold' || value == 'reserved');
    
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

  Widget _buildEditTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_getSpacing(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Estado del ticket
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
                      'Estado del Ticket',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: _getFontSize(context, 16),
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _getSpacing(context, 16)),
                
                // Mensaje informativo cuando la rifa está expirada
                if (widget.raffle.status == 'expired') ...[
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
                
                _buildStatusButton('available', 'DISPONIBLE', Icons.check_circle_rounded, const Color(0xFF38A169)),
                _buildStatusButton('reserved', 'RESERVADO', Icons.bookmark_added_rounded, const Color(0xFFFF8C00)),
                _buildStatusButton('sold', 'VENDIDO', Icons.monetization_on_rounded, const Color(0xFFE53E3E)),
              ],
            ),
          ),
          
          if (_status != 'available') ...[
            SizedBox(height: _getSpacing(context, 24)),
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
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _getSpacing(context, 20)),
                  
                  // Campo Nombre
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      key: ValueKey('name_${widget.ticket?.number}_${widget.ticket?.buyerName}'),
                      controller: _nameCtrl,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getFontSize(context, 14),
                      ),
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
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
                        fillColor: Colors.grey[800],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: _getSpacing(context, 20),
                          vertical: _getSpacing(context, 16),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: _getSpacing(context, 16)),
                  
                  // Campo Contacto
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      key: ValueKey('contact_${widget.ticket?.number}_${widget.ticket?.buyerContact}'),
                      controller: _contactCtrl,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getFontSize(context, 14),
                      ),
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
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
                        fillColor: Colors.grey[800],
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
          ],
          
          SizedBox(height: _getSpacing(context, 32)),
          
          // Botón Guardar
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
                onTap: _save,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: _getSpacing(context, 24)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ticket == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 480;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: _getSpacing(context, 16), 
          vertical: _getSpacing(context, 24)
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          constraints: BoxConstraints(
            maxWidth: isSmallScreen ? screenWidth * 0.95 : 500,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1e1e1e),
                const Color(0xFF1e1e1e).withOpacity(0.95),
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
          child: Column(
            children: [
              // Header con efecto glassmorphism
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
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
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
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  '#${widget.ticket!.number}',
                                  style: TextStyle(
                                    fontSize: _getFontSize(context, 24),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        iconSize: _getFontSize(context, 20),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tab Bar mejorado
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[850]!,
                      Colors.grey[800]!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: _getFontSize(context, 14),
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: _getFontSize(context, 14),
                  ),
                  tabs: [
                    Tab(
                      icon: Container(
                        padding: EdgeInsets.all(_getSpacing(context, 6)),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.visibility_rounded,
                          size: _getFontSize(context, 18),
                        ),
                      ),
                      text: 'Vista Previa',
                    ),
                    Tab(
                      icon: Container(
                        padding: EdgeInsets.all(_getSpacing(context, 6)),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: _getFontSize(context, 18),
                        ),
                      ),
                      text: 'Estado del Ticket',
                    ),
                  ],
                ),
              ),
              
              // Tab Views
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Vista Previa
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1e1e1e),
                              Colors.grey[900]!.withOpacity(0.8),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(_getSpacing(context, 20)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(1),
                            child: TicketExportWidget(
                              ticket: widget.ticket!,
                              raffle: widget.raffle,
                            ),
                          ),
                        ),
                      ),
                      
                      // Tab 2: Estado del Ticket
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1e1e1e),
                              Colors.grey[900]!.withOpacity(0.8),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: _buildEditTab(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
