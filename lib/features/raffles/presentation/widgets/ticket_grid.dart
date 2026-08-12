import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:raffle/features/raffles/domain/entities/ticket.dart';
import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/features/raffles/presentation/bloc/details/raffle_details_bloc.dart';
import 'package:raffle/features/raffles/presentation/bloc/details/raffle_details_event.dart';
import 'package:raffle/features/raffles/presentation/bloc/details/raffle_details_state.dart';
import 'dart:math' as math;
import 'package:raffle/core/pagination/paged.dart';
import 'package:raffle/core/theme/app_colors.dart';

class TicketGrid extends StatefulWidget {
  /// Página de boletos que se está mostrando. La trae el bloc con
  /// `LIMIT/OFFSET`: el grid nunca tiene los diez mil boletos en memoria.
  final Paged<Ticket> page;

  final Function(Ticket) onTap;
  final Raffle raffle;
  final bool showRandomButton;
  final Function(int)? onPageChanged;

  const TicketGrid({
    super.key,
    required this.page,
    required this.onTap,
    required this.raffle,
    this.showRandomButton = false,
    this.onPageChanged,
  });

  @override
  State<TicketGrid> createState() => _TicketGridState();
}

class _TicketGridState extends State<TicketGrid> {
  int get itemsPerPage => widget.page.pageSize;
  int get totalPages => widget.page.totalPages;
  int get _page => widget.page.page;
  List<Ticket> get currentPageTickets => widget.page.items;

  /// La paginación la lleva el bloc: aquí solo se avisa de la página pedida.
  void _onPageChanged(int page) {
    if (totalPages == 0) return;
    widget.onPageChanged?.call(page.clamp(0, totalPages - 1));
  }

  String _formatNumber(int number) => _formatNumberFor(widget.raffle, number);

  /// El formato depende de `gameType` y `digitCount`, así que se toma de la
  /// rifa que se está pintando y no de la que llegó por parámetro: durante un
  /// sorteo el widget conserva una copia vieja mientras el bloc ya tiene la
  /// nueva, y comparar contra la vieja dejaba al ganador sin resaltar.
  String _formatNumberFor(Raffle raffle, int number) {
    if (raffle.gameType == 'lottery') {
      return number.toString().padLeft(raffle.digitCount, '0');
    }
    return number.toString();
  }

  Color _getTicketColor(String status) {
    switch (status) {
      case 'sold':
        return AppColors.statusSold.withValues(alpha: 0.3);
      case 'reserved':
        return AppColors.statusReserved.withValues(alpha: 0.3);
      case 'available':
        return AppColors.statusAvailable.withValues(alpha: 0.3);
      default:
        return AppColors.textSecondary.withValues(alpha: 0.3);
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

  /// Sortea un boleto y pide confirmación antes de fijarlo como ganador.
  ///
  /// El sorteo lo hace la base entre todos los boletos disponibles de la rifa,
  /// no entre los de la página cargada.
  Future<void> _selectRandomTicket(BuildContext context, Raffle raffle) async {
    // El bloc se resuelve **antes** de abrir el diálogo, y el resultado se
    // devuelve por `Navigator.pop`. `showDialog` monta en el Navigator raíz,
    // así que el context del diálogo no desciende del `BlocProvider` de esta
    // ruta: buscarlo desde dentro devolvía otro bloc, sin rifa cargada, que
    // descartaba el evento en silencio.
    final bloc = context.read<RaffleDetailsBloc>();
    final messenger = ScaffoldMessenger.of(context);

    final selectedTicket = await bloc.pickWinningTicket();
    if (!mounted) return;

    if (selectedTicket == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No hay boletos para sortear')),
      );
      return;
    }

    if (!context.mounted) return;

    final winningNumber = _formatNumberFor(raffle, selectedTicket.number);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Número Ganador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Deseas establecer este número como el ganador?'),
            const SizedBox(height: 16),
            Text(
              winningNumber,
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
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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

    if (confirmed != true) return;

    bloc.add(SetWinningNumber(
      raffleId: raffle.id!,
      winningNumber: winningNumber,
    ));
  }

  Future<void> _showWinningNumberDialog(
      BuildContext context, Raffle raffle) async {
    final bloc = context.read<RaffleDetailsBloc>();

    final reset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Número Ganador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('El número ganador es:'),
            const SizedBox(height: 16),
            Text(
              raffle.winningNumber!,
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
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cerrar'),
          ),
          // Sin condicionar al estado: sortear en la app deja la rifa en
          // `expired`, que es justo el caso en el que hace falta reiniciar.
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reiniciar Sorteo'),
          ),
        ],
      ),
    );

    if (reset != true) return;

    bloc.add(ResetDraw(raffle.id!));
  }

  Widget _buildPagination() {
    // Con una sola página no hay nada que paginar, y con cero un
    // `DropdownButton` cuyo `value` no está entre sus items dispara una
    // assertion de Flutter.
    if (totalPages <= 1) return const SizedBox.shrink();

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
                    'Página ${_page + 1} de $totalPages',
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
                              _page > 0 ? () => _onPageChanged(0) : null,
                          icon: const Icon(Icons.first_page),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      IconButton(
                        onPressed: _page > 0
                            ? () => _onPageChanged(_page - 1)
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
                            value: _page,
                            isDense: true,
                            isExpanded: true,
                            items: List.generate(totalPages, (index) {
                              final start = index * itemsPerPage + 1;
                              final end = math.min(
                                  (index + 1) * itemsPerPage, widget.page.total);
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
                        onPressed: _page < totalPages - 1
                            ? () => _onPageChanged(_page + 1)
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
                          onPressed: _page < totalPages - 1
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
                final number = _formatNumberFor(currentRaffle, ticket.number);
                final isWinner = currentRaffle.winningNumber == number;
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
                                color: Colors.amber.shade200.withValues(alpha: 0.5),
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
                                number,
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
                  if (currentRaffle.hasWinner) ...[
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

    if (raffle.hasWinner) {
      return ElevatedButton.icon(
        onPressed: () => _showWinningNumberDialog(context, raffle),
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
        onPressed: () => _selectRandomTicket(context, raffle),
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
