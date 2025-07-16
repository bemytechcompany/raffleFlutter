import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:raffle/features/raffles/domain/entities/ticket.dart';
import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/features/raffles/presentation/bloc/details/raffle_details_bloc.dart';
import 'package:raffle/features/raffles/presentation/bloc/details/raffle_details_event.dart';
import 'package:raffle/features/raffles/presentation/bloc/details/raffle_details_state.dart';
import 'package:raffle/features/raffles/presentation/bloc/raffle_bloc.dart';
import 'package:raffle/features/raffles/presentation/bloc/raffle_event.dart'
    as raffle_events;
import 'package:raffle/features/raffles/presentation/widgets/status_modal.dart';
import 'package:raffle/features/raffles/presentation/widgets/ticket_info_modal.dart';
import 'package:raffle/features/raffles/presentation/widgets/ticket_modal.dart';
import 'package:raffle/features/raffles/presentation/widgets/ticket_grid.dart';
import 'package:raffle/features/raffles/presentation/widgets/financial_summary.dart';
import 'package:raffle/features/raffles/presentation/pages/raffle_edit_page.dart';
import 'package:raffle/features/raffles/presentation/pages/raffle_share_page.dart';
import 'package:raffle/features/raffles/presentation/widgets/buyers_summary.dart';
import 'package:raffle/features/raffles/presentation/pages/buyers_list_page.dart';
import 'package:raffle/core/theme/app_colors.dart';
import 'dart:io';

class RaffleDetailsPage extends StatefulWidget {
  final int raffleId;

  const RaffleDetailsPage({super.key, required this.raffleId});

  @override
  State<RaffleDetailsPage> createState() => _RaffleDetailsPageState();
}

class _RaffleDetailsPageState extends State<RaffleDetailsPage> {
  bool showStatusModal = false;
  bool showDeleteConfirm = false;
  Raffle? raffle;
  int currentPage = 0;
  late ScrollController _scrollController;
  late ValueNotifier<double> _scrollOffset;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollOffset = ValueNotifier<double>(0.0);
    _scrollController.addListener(_onScroll);
    context.read<RaffleDetailsBloc>().add(LoadRaffleDetails(widget.raffleId));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  void _onScroll() {
    _scrollOffset.value = _scrollController.offset;
  }

  void _handleStatusChange(String newStatus) {
    context.read<RaffleDetailsBloc>().add(
          ChangeRaffleStatus(
            raffleId: widget.raffleId,
            newStatus: newStatus,
          ),
        );
    setState(() => showStatusModal = false);
  }

  void _handleTicketUpdate(Ticket ticket) {
    context.read<RaffleDetailsBloc>().add(EditTicket(ticket));
  }

  void _handleDeleteRaffle() {
    context.read<RaffleDetailsBloc>().add(DeleteRaffle(widget.raffleId));
    Navigator.of(context).pop(); // vuelve a la lista
  }

  void _openTicketInfoModal(Ticket ticket) {
    if (raffle == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => TicketInfoModal(
        ticket: ticket,
        raffle: raffle!,
        onClose: () => Navigator.of(context).pop(),
        onEdit: (updatedTicket) {
          _handleTicketUpdate(updatedTicket);
        },
      ),
    );
  }

  void _openEditModal(Ticket ticket) {
    if (raffle == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TicketModal(
        ticket: ticket,
        raffle: raffle!,
        onSubmit: (updatedTicket) {
          Navigator.of(context).pop(); // Cerrar el modal
          _handleTicketUpdate(updatedTicket);
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _openShareModal() {
    if (raffle == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RaffleSharePage(
          raffle: raffle!,
          tickets:
              (context.read<RaffleDetailsBloc>().state as RaffleDetailsLoaded)
                  .tickets,
          currentPage: currentPage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: BlocBuilder<RaffleDetailsBloc, RaffleDetailsState>(
        builder: (context, state) {
          if (state is RaffleDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RaffleDetailsLoaded) {
            raffle = state.raffle;
            final tickets = state.tickets;

            return Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(), // Más fluido en iOS
                  child: Column(
                    children: [
                      Container(
                        height: 280,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          image: raffle!.imagePath != null
                              ? DecorationImage(
                                  image: FileImage(File(raffle!.imagePath!)),
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                )
                              : null,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.blackWithOpacity(0.4),
                                AppColors.blackWithOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    raffle!.name,
                                    style: TextStyle(
                                      color: AppColors.text,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(0, 2),
                                          blurRadius: 4,
                                          color: AppColors.blackWithOpacity(0.38),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Mostrar número ganador si existe
                                  if (raffle!.winningNumber != null && raffle!.winningNumber!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.awardGold.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.awardGold.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.emoji_events,
                                            color: Colors.black87,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Ganador: ${raffle!.winningNumber}',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            FinancialSummary(
                              raffle: raffle!,
                              tickets: tickets,
                            ),
                            BuyersSummary(
                              tickets: tickets,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BuyersListPage(
                                      raffle: raffle!,
                                      tickets: tickets,
                                    ),
                                  ),
                                );
                              },
                            ),
                            TicketGrid(
                              tickets: tickets,
                              raffle: raffle!,
                              onTap: _openTicketInfoModal,
                              showRandomButton: raffle!.status == 'active',
                              onPageChanged: (page) =>
                                  setState(() => currentPage = page),
                            ),
                            const SizedBox(height: 60)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // AppBar animado que se superpone
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ValueListenableBuilder<double>(
                    valueListenable: _scrollOffset,
                    builder: (context, offset, child) {
                      final double opacity = (offset / 150).clamp(0.0, 1.0);
                      final double elevation = opacity * 4;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(opacity),
                          boxShadow: elevation > 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: elevation,
                                    offset: Offset(0, elevation / 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: SafeArea(
                          child: Container(
                            height: kToolbarHeight,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  color: AppColors.text,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                Expanded(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: opacity > 0.5 ? 1.0 : 0.0,
                                    child: Text(
                                      raffle?.name ?? '',
                                      style: const TextStyle(
                                        color: AppColors.text,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (raffle?.status != 'expired') ...[
                                      IconButton(
                                        icon: const Icon(Icons.share),
                                        color: AppColors.text,
                                        onPressed: _openShareModal,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        color: AppColors.text,
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  BlocProvider.value(
                                                value:
                                                    context.read<RaffleBloc>(),
                                                child: RaffleEditPage(
                                                    raffle: raffle!),
                                              ),
                                            ),
                                          );
                                          if (mounted) {
                                            context
                                                .read<RaffleDetailsBloc>()
                                                .add(
                                                  LoadRaffleDetails(
                                                      widget.raffleId),
                                                );
                                          }
                                        },
                                      ),
                                    ],
                                    IconButton(
                                      icon: const Icon(Icons.sync_alt),
                                      color: AppColors.text,
                                      onPressed: () => setState(
                                          () => showStatusModal = true),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (raffle!.status == 'expired')
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => setState(() => showDeleteConfirm = true),
                      icon: const Icon(Icons.delete, color: AppColors.text),
                      label: const Text(
                        'Delete Raffle',
                        style: TextStyle(color: AppColors.text),
                      ),
                    ),
                  ),
                if (showStatusModal)
                  StatusModal(
                    currentStatus: raffle!.status,
                    onSelect: _handleStatusChange,
                    onClose: () => setState(() => showStatusModal = false),
                  ),
                if (showDeleteConfirm)
                  AlertDialog(
                    backgroundColor: AppColors.backgroundModal,
                    title: const Text(
                      'Confirm Deletion',
                      style: TextStyle(color: AppColors.text),
                    ),
                    content: const Text(
                      'Are you sure you want to delete this raffle?',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            setState(() => showDeleteConfirm = false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _handleDeleteRaffle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: AppColors.text),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          }

          if (state is RaffleDetailsError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          return const Center(
            child: Text(
              'Something went wrong',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        },
      ),
    );
  }
}
