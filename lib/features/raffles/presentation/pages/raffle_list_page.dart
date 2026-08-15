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
import 'package:raffle/core/pagination/paged.dart';
import 'package:raffle/features/raffles/domain/entities/raffle_summary.dart';

import '../../../../core/theme/app_colors.dart';

class RaffleListPage extends StatefulWidget {
  const RaffleListPage({super.key});

  @override
  State<RaffleListPage> createState() => _RaffleListPageState();
}

class _RaffleListPageState extends State<RaffleListPage> {
  final TextEditingController _searchController = TextEditingController();

  /// El filtrado, el orden y la paginación los resuelve SQLite; aquí solo se
  /// pinta lo que llega en el estado.
  ///
  /// Se guarda únicamente el filtro de estado, porque el chip necesita saber
  /// cuál está marcado antes de que llegue la respuesta.
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<RaffleBloc>().add(const LoadRaffles());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page, int totalPages) {
    if (totalPages == 0) return;
    context
        .read<RaffleBloc>()
        .add(ChangeRafflePage(page.clamp(0, totalPages - 1)));
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
            // El bloc aplica un pequeño retardo antes de consultar, para no
            // lanzar una query por cada tecla.
            onChanged: (value) =>
                context.read<RaffleBloc>().add(SearchRaffles(value)),
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
        final status = selected ? value : 'all';
        setState(() => _statusFilter = status);
        context.read<RaffleBloc>().add(FilterRafflesByStatus(status));
      },
      backgroundColor: Colors.grey[200],
      checkmarkColor: AppColors.buttonGreenForeground,
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.buttonGreenBackground; // fondo verde activo si está seleccionado
        }
        return Colors.white; // fondo blanco para no seleccionados
      }),
    );
  }

  /// Controles de paginación para la página recibida.
  ///
  /// Recibe la página por parámetro en vez de leerla de un campo: así no hay
  /// copia del estado del bloc que pueda quedar desincronizada.
  Widget _buildPagination(Paged<RaffleSummary> pageData) {
    final totalPages = pageData.totalPages;
    final page = pageData.page;
    final itemsPerPage = pageData.pageSize;

    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          // Indicador de página actual
          Text(
            'Página ${page + 1} de $totalPages (${pageData.total} rifas)',
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
                          page > 0 ? () => _onPageChanged(0, totalPages) : null,
                      icon: const Icon(Icons.first_page),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  IconButton(
                    onPressed: page > 0
                        ? () => _onPageChanged(page - 1, totalPages)
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
                        value: page,
                        isDense: true,
                        isExpanded: true,
                        items: List.generate(totalPages, (index) {
                          final start = index * itemsPerPage + 1;
                          final end = math.min((index + 1) * itemsPerPage,
                              pageData.total);
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
                            _onPageChanged(value, totalPages);
                          }
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: page < totalPages - 1
                        ? () => _onPageChanged(page + 1, totalPages)
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
                      onPressed: page < totalPages - 1
                          ? () => _onPageChanged(totalPages - 1, totalPages)
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
      context.read<RaffleBloc>().add(const LoadRaffles());
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
                  // La página ya viene filtrada y paginada desde SQL.
                  final pageData = state.page;
                  final isFiltered = state.isFiltered;

                  if (pageData.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isFiltered
                                ? Icons.search_off
                                : Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isFiltered
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
                      _buildPagination(pageData),

                      // Lista de rifas paginada
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: pageData.items.length,
                          itemBuilder: (context, index) {
                            final summary = pageData.items[index];
                            final raffle = summary.raffle;
                            // Contadores ya calculados por SQLite: la lista no
                            // carga ni un boleto.
                            final percent =
                                summary.soldRatio + summary.reservedRatio;

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
                                                        .withValues(alpha: 0.2),
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
                                                // Se resuelve el bloc antes de
                                                // navegar: después del await el
                                                // context puede estar muerto.
                                                final bloc =
                                                    context.read<RaffleBloc>();
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        BlocProvider.value(
                                                      value: bloc,
                                                      child: RaffleEditPage(
                                                          raffle: raffle),
                                                    ),
                                                  ),
                                                );
                                                bloc.add(const LoadRaffles());
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
                      _buildPagination(pageData),
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
        // Las pestañas conviven en un IndexedStack, así que hay más de un FAB
        // montado a la vez. Sin un tag propio compartirían el Hero por defecto
        // y la animación de navegación reventaría con una assertion.
        heroTag: 'raffles-fab',
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

          // `bloc` se capturó antes de navegar, así que no hace falta volver
          // a tocar el context.
          bloc.add(const LoadRaffles());
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
