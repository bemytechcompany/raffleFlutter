import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:raffle/features/raffles/presentation/bloc/raffle_bloc.dart';
import 'package:raffle/features/raffles/presentation/bloc/raffle_event.dart';
import 'package:raffle/features/raffles/presentation/bloc/raffle_state.dart';
import 'package:raffle/features/raffles/presentation/bloc/details/raffle_details_bloc.dart';
import 'package:raffle/features/raffles/presentation/pages/raffle_create_page.dart';
import 'package:raffle/features/raffles/presentation/pages/raffle_details_page.dart';
import 'package:raffle/features/raffles/presentation/pages/raffle_edit_page.dart';
import 'package:raffle/features/raffles/domain/entities/raffle.dart';

import '../../../../core/theme/app_colors.dart';

class RaffleListPage extends StatefulWidget {
  const RaffleListPage({super.key});

  @override
  State<RaffleListPage> createState() => _RaffleListPageState();
}

class _RaffleListPageState extends State<RaffleListPage> {
  static const int itemsPerPage = 20;
  int _currentPage = 0;
  String _searchQuery = '';
  String _statusFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  List<Raffle> _filteredRaffles = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<RaffleBloc>().add(LoadRaffles());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRaffles(List<Raffle> allRaffles) {
    _filteredRaffles = allRaffles.where((raffle) {
      // Filtro de búsqueda
      final matchesSearch = _searchQuery.isEmpty ||
          raffle.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          raffle.lotteryNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      // Filtro de estado
      final matchesStatus =
          _statusFilter == 'all' || raffle.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    // Resetear a la primera página cuando se cambia el filtro
    _currentPage = 0;
  }

  int get totalPages => (_filteredRaffles.length / itemsPerPage).ceil();

  List<Raffle> get currentPageRaffles {
    final start = _currentPage * itemsPerPage;
    final end = math.min(start + itemsPerPage, _filteredRaffles.length);
    return _filteredRaffles.sublist(start, end);
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre o número de lotería...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          // Filtros por estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todas', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Activa', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Inactiva', 'inactive'),
                const SizedBox(width: 8),
                _buildFilterChip('Expirada', 'expired'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.buttonGreenForeground : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = selected ? value : 'all';
        });
      },
      backgroundColor: Colors.grey[200],
      checkmarkColor: AppColors.buttonGreenForeground,
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.buttonGreenBackground; // fondo verde activo si está seleccionado
        }
        return Colors.white; // fondo blanco para no seleccionados
      }),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          // Indicador de página actual
          Text(
            'Página ${_currentPage + 1} de $totalPages (${_filteredRaffles.length} rifas)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Controles de navegación
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 400;

              return Row(
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
                  // Selector de página
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: isSmallScreen ? 200 : 300,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _currentPage,
                        isDense: true,
                        isExpanded: true,
                        items: List.generate(totalPages, (index) {
                          final start = index * itemsPerPage + 1;
                          final end = math.min((index + 1) * itemsPerPage,
                              _filteredRaffles.length);
                          return DropdownMenuItem(
                            alignment: Alignment.center,
                            value: index,
                            child: Text(
                              'Rifas $start-$end',
                              style: const TextStyle(
                                fontSize: 14,
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
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToDetails(int raffleId) async {
    final bloc = context.read<RaffleBloc>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: bloc),
            BlocProvider(
              create: (_) => RaffleDetailsBloc(bloc.repository),
            ),
          ],
          child: RaffleDetailsPage(raffleId: raffleId),
        ),
      ),
    );
    if (mounted) {
      context.read<RaffleBloc>().add(LoadRaffles());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          _buildSearchAndFilters(),

          // Lista de rifas
          Expanded(
            child: BlocBuilder<RaffleBloc, RaffleState>(
              builder: (context, state) {
                if (state is RaffleLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is RaffleLoaded) {
                  // Filtrar las rifas cada vez que cambia el estado
                  _filterRaffles(state.raffles);

                  if (_filteredRaffles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty || _statusFilter != 'all'
                                ? Icons.search_off
                                : Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _statusFilter != 'all'
                                ? 'No se encontraron rifas con los criterios de búsqueda.'
                                : 'No hay rifas creadas.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Paginación superior
                      _buildPagination(),

                      // Lista de rifas paginada
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: currentPageRaffles.length,
                          itemBuilder: (context, index) {
                            final raffle = currentPageRaffles[index];
                            final tickets = raffle.tickets ?? [];
                            final soldCount = tickets
                                .where((t) =>
                                    t.status == 'sold' ||
                                    t.status == 'reserved')
                                .length;
                            final percent = raffle.totalTickets == 0
                                ? 0.0
                                : soldCount / raffle.totalTickets;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () => _navigateToDetails(raffle.id!),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Contenedor de imagen y estado
                                          SizedBox(
                                            width: 60,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                raffle.imagePath != null &&
                                                        raffle.imagePath!
                                                            .isNotEmpty
                                                    ? ClipOval(
                                                        child: Image.file(
                                                          File(raffle
                                                              .imagePath!),
                                                          width: 44,
                                                          height: 44,
                                                          fit: BoxFit.cover,
                                                          cacheWidth: 100,
                                                          cacheHeight: 100,
                                                        ),
                                                      )
                                                    : CircleAvatar(
                                                        radius: 22,
                                                        backgroundColor:
                                                            Colors.deepPurple,
                                                        child: Text(
                                                          raffle.name
                                                              .substring(0, 1)
                                                              .toUpperCase(),
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                        ),
                                                      ),
                                                const SizedBox(height: 12),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                            raffle.status)
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    border: Border.all(
                                                      color: _getStatusColor(
                                                          raffle.status),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _getStatusDisplayName(
                                                        raffle.status),
                                                    style: TextStyle(
                                                      color: _getStatusColor(
                                                          raffle.status),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Contenido de información
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  raffle.name,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                    'Lotería #${raffle.lotteryNumber}'),
                                                const SizedBox(height: 6),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child:
                                                      LinearProgressIndicator(
                                                    value: percent,
                                                    minHeight: 6,
                                                    backgroundColor:
                                                        Colors.grey[300],
                                                    valueColor:
                                                        const AlwaysStoppedAnimation(
                                                            Color(0xFF00C853)),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                    '${(percent * 100).toStringAsFixed(1)}% vendido',
                                                    style: const TextStyle(
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (value) async {
                                          switch (value) {
                                            case 'edit':
                                              if (raffle.status != 'expired') {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        BlocProvider.value(
                                                      value: context
                                                          .read<RaffleBloc>(),
                                                      child: RaffleEditPage(
                                                          raffle: raffle),
                                                    ),
                                                  ),
                                                );
                                                if (mounted) {
                                                  context
                                                      .read<RaffleBloc>()
                                                      .add(LoadRaffles());
                                                }
                                              }
                                              break;
                                            case 'active':
                                              context.read<RaffleBloc>().add(
                                                    UpdateRaffleStatusEvent(
                                                      raffleId: raffle.id!,
                                                      newStatus: 'active',
                                                    ),
                                                  );
                                              break;
                                            case 'inactive':
                                              context.read<RaffleBloc>().add(
                                                    UpdateRaffleStatusEvent(
                                                      raffleId: raffle.id!,
                                                      newStatus: 'inactive',
                                                    ),
                                                  );
                                              break;
                                            case 'expired':
                                              context.read<RaffleBloc>().add(
                                                    UpdateRaffleStatusEvent(
                                                      raffleId: raffle.id!,
                                                      newStatus: 'expired',
                                                    ),
                                                  );
                                              break;
                                          }
                                        },
                                        itemBuilder: (BuildContext context) => [
                                          if (raffle.status != 'expired')
                                            const PopupMenuItem<String>(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit),
                                                  SizedBox(width: 8),
                                                  Text('Editar'),
                                                ],
                                              ),
                                            ),
                                          const PopupMenuDivider(),
                                          const PopupMenuItem<String>(
                                            value: 'active',
                                            child: Row(
                                              children: [
                                                Icon(Icons.check_circle_outline,
                                                    color: AppColors.success),
                                                SizedBox(width: 8),
                                                Text('Activar'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'inactive',
                                            child: Row(
                                              children: [
                                                Icon(Icons.pause_circle_outline,
                                                    color: Colors.orange),
                                                SizedBox(width: 8),
                                                Text('Pausar'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'expired',
                                            child: Row(
                                              children: [
                                                Icon(Icons.cancel_outlined,
                                                    color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Expirar'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Paginación inferior
                      _buildPagination(),
                    ],
                  );
                } else if (state is RaffleError) {
                  return Center(child: Text(state.message));
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: AppColors.buttonGreenForeground,
        backgroundColor: AppColors.buttonGreenBackground,
        onPressed: () async {
          final bloc = context.read<RaffleBloc>();

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: const RaffleCreatePage(),
              ),
            ),
          );

          if (mounted) {
            context.read<RaffleBloc>().add(LoadRaffles());
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.raffleActive;
      case 'inactive':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'active':
        return 'Activa';
      case 'inactive':
        return 'Inactiva';
      case 'expired':
        return 'Expirada';
      default:
        return status;
    }
  }
}
