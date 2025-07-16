import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:raffle/features/raffles/domain/entities/ticket.dart';
import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/features/raffles/presentation/bloc/details/raffle_details_bloc.dart';
import 'package:raffle/features/raffles/presentation/bloc/details/raffle_details_event.dart';
import 'package:raffle/features/raffles/presentation/bloc/details/raffle_details_state.dart';
import 'dart:math' as math;
import 'package:raffle/core/theme/app_colors.dart';

class TicketGrid extends StatefulWidget {
  final List<Ticket> tickets;
  final Function(Ticket) onTap;
  final Raffle raffle;
  final bool showRandomButton;
  final Function(int)? onPageChanged;

  const TicketGrid({
    super.key,
    required this.tickets,
    required this.onTap,
    required this.raffle,
    this.showRandomButton = false,
    this.onPageChanged,
  });

  @override
  State<TicketGrid> createState() => _TicketGridState();
}

class _TicketGridState extends State<TicketGrid> {
  static const int itemsPerPage = 100;
  int _currentPage = 0;

  int get totalPages => (widget.tickets.length / itemsPerPage).ceil();
  List<Ticket> get currentPageTickets {
    final start = _currentPage * itemsPerPage;
    final end = math.min(start + itemsPerPage, widget.tickets.length);
    return widget.tickets.sublist(start, end);
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    widget.onPageChanged?.call(page);
  }

  String _formatNumber(int number) {
    if (widget.raffle.gameType == 'lottery') {
      return number.toString().padLeft(widget.raffle.digitCount, '0');
    }
    return number.toString();
  }

  Color _getTicketColor(String status) {
    switch (status) {
      case 'sold':
        return AppColors.statusSold.withOpacity(0.3);
      case 'reserved':
        return AppColors.statusReserved.withOpacity(0.3);
      case 'available':
        return AppColors.statusAvailable.withOpacity(0.3);
      default:
        return AppColors.textSecondary.withOpacity(0.3);
    }
  }

  Color _getTicketBorderColor(String status) {
    switch (status) {
      case 'sold':
        return AppColors.statusSold;
      case 'reserved':
        return AppColors.statusReserved;
      case 'available':
        return AppColors.statusAvailable;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getTicketTextColor(String status) {
    switch (status) {
      case 'sold':
        return Colors.white; 
      case 'reserved':
        return Colors.white; 
      case 'available':
        return Colors.white; 
      default:
        return Colors.black;
    }
  }

  void _selectRandomTicket(BuildContext context) {
    final availableTickets =
        widget.tickets.where((t) => t.status == 'available').toList();
    if (availableTickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay números disponibles')),
      );
      return;
    }

    final random = math.Random();
    final selectedTicket =
        availableTickets[random.nextInt(availableTickets.length)];

    // Mostrar diálogo de confirmación
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Número Ganador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Deseas establecer este número como el ganador?'),
            const SizedBox(height: 16),
            Text(
              _formatNumber(selectedTicket.number),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
                      ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<RaffleDetailsBloc>().add(
                      SetWinningNumber(
                        raffleId: widget.raffle.id!,
                        winningNumber: _formatNumber(selectedTicket.number),
                      ),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonGreenBackground,
                foregroundColor: AppColors.buttonGreenForeground,
                side: const BorderSide(color: AppColors.buttonGreenBorder),
              ),
              child: const Text('Confirmar'),
            ),
        ],
      ),
    );
  }

  void _showWinningNumberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Número Ganador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('El número ganador es:'),
            const SizedBox(height: 16),
            Text(
              widget.raffle.winningNumber!,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (widget.raffle.status != 'expired')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<RaffleDetailsBloc>().add(
                      SetWinningNumber(
                        raffleId: widget.raffle.id!,
                        winningNumber: '',
                      ),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Reiniciar Sorteo'),
            ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 400;
              final is4Digits = widget.raffle.digitCount >= 4;

              return Column(
                children: [
                  // Indicador de página actual
                  Text(
                    'Página ${_currentPage + 1} de $totalPages',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Controles de navegación
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isSmallScreen)
                        IconButton(
                          onPressed:
                              _currentPage > 0 ? () => _onPageChanged(0) : null,
                          icon: const Icon(Icons.first_page),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      IconButton(
                        onPressed: _currentPage > 0
                            ? () => _onPageChanged(_currentPage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      // Selector de página con diseño adaptativo
                      Container(
                        constraints: BoxConstraints(
                          maxWidth:
                              is4Digits ? 150 : (isSmallScreen ? 200 : 300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _currentPage,
                            isDense: true,
                            isExpanded: true,
                            items: List.generate(totalPages, (index) {
                              final start = index * itemsPerPage + 1;
                              final end = math.min((index + 1) * itemsPerPage,
                                  widget.tickets.length);
                              return DropdownMenuItem(
                                alignment: Alignment.center,
                                value: index,
                                child: Text(
                                  'Boletos ${_formatNumber(start)}-${_formatNumber(end)}',
                                  style: TextStyle(
                                    fontSize: is4Digits ? 12 : 14,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            }),
                            onChanged: (value) {
                              if (value != null) {
                                _onPageChanged(value);
                              }
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _currentPage < totalPages - 1
                            ? () => _onPageChanged(_currentPage + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      if (!isSmallScreen)
                        IconButton(
                          onPressed: _currentPage < totalPages - 1
                              ? () => _onPageChanged(totalPages - 1)
                              : null,
                          icon: const Icon(Icons.last_page),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botón de acción (aleatorio o ver ganador)
        Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: BlocBuilder<RaffleDetailsBloc, RaffleDetailsState>(
            builder: (context, state) {
              if (state is RaffleDetailsLoaded) {
                final updatedRaffle = state.raffle;
                return _buildActionButton(updatedRaffle);
              }
              return _buildActionButton(widget.raffle);
            },
          ),
        ),

        // Grid de tickets
        BlocBuilder<RaffleDetailsBloc, RaffleDetailsState>(
          builder: (context, state) {
            final currentRaffle =
                state is RaffleDetailsLoaded ? state.raffle : widget.raffle;
            final currentTickets =
                state is RaffleDetailsLoaded ? state.tickets : widget.tickets;

            // Ajustar el número de columnas según la cantidad de dígitos
            final crossAxisCount = currentRaffle.gameType == 'lottery'
                ? (currentRaffle.digitCount >= 4 ? 5 : 10)
                : 10;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: currentRaffle.digitCount >= 4 ? 1.5 : 0.8,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: currentPageTickets.length,
              itemBuilder: (context, index) {
                final ticket = currentPageTickets[index];
                final isWinner =
                    currentRaffle.winningNumber == _formatNumber(ticket.number);
                final is4Digits = currentRaffle.digitCount >= 4;

                return InkWell(
                  onTap: () => widget.onTap(ticket),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isWinner
                          ? Colors.amber.shade200
                          : _getTicketColor(ticket.status),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isWinner
                            ? Colors.amber.shade700
                            : _getTicketBorderColor(ticket.status),
                        width: isWinner ? 2 : 1,
                      ),
                      boxShadow: isWinner
                          ? [
                              BoxShadow(
                                color: Colors.amber.shade200.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: is4Digits ? 8 : 4,
                              ),
                              child: Text(
                                _formatNumber(ticket.number),
                                style: TextStyle(
                                  fontSize: _getTicketFontSize(
                                      currentRaffle.digitCount),
                                  fontWeight:
                                      isWinner || ticket.status != 'available'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color: isWinner 
                                      ? Colors.black87 // Contraste con el dorado del ganador
                                      : _getTicketTextColor(ticket.status),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 8),

        // Paginación inferior
        _buildPagination(),

        // Leyenda
        BlocBuilder<RaffleDetailsBloc, RaffleDetailsState>(
          builder: (context, state) {
            final currentRaffle =
                state is RaffleDetailsLoaded ? state.raffle : widget.raffle;

            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Disponible', AppColors.statusAvailable),
                  const SizedBox(width: 16),
                  _buildLegendItem('Reservado', AppColors.statusReserved),
                  const SizedBox(width: 16),
                  _buildLegendItem('Vendido', AppColors.statusSold),
                  if (currentRaffle.winningNumber != null &&
                      currentRaffle.winningNumber!.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    _buildLegendItem('Ganador', AppColors.awardGold),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton([Raffle? currentRaffle]) {
    final raffle = currentRaffle ?? widget.raffle;

    if (raffle.winningNumber != null && raffle.winningNumber!.isNotEmpty) {
      return ElevatedButton.icon(
        onPressed: () => _showWinningNumberDialog(context),
        icon: const Icon(Icons.emoji_events),
        label: const Text('Ver Número Ganador'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonGreenBackground,
          foregroundColor: AppColors.buttonGreenForeground,
          side: const BorderSide(color: AppColors.buttonGreenBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      );
    }

    if (widget.showRandomButton && raffle.gameType == 'app') {
      return ElevatedButton.icon(
        onPressed: () => _selectRandomTicket(context),
        icon: const Icon(Icons.shuffle),
        label: const Text('Seleccionar Número Ganador'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  double _getTicketFontSize(int digitCount) {
    switch (digitCount) {
      case 4:
        return 20;
      case 3:
        return 16;
      default:
        return 14;
    }
  }
}
