import 'package:equatable/equatable.dart';

import 'package:raffle/core/pagination/paged.dart';
import 'package:raffle/features/raffles/domain/entities/raffle_summary.dart';

abstract class RaffleState extends Equatable {
  const RaffleState();

  @override
  List<Object?> get props => [];
}

class RaffleInitial extends RaffleState {}

class RaffleLoading extends RaffleState {}

class RaffleLoaded extends RaffleState {
  /// Página actual, con los contadores ya resueltos por SQLite.
  final Paged<RaffleSummary> page;

  /// Filtros con los que se pidió esta página, para que la interfaz los
  /// refleje y el bloc pueda repetirlos al cambiar de página.
  final String search;
  final String status;

  const RaffleLoaded({
    required this.page,
    required this.search,
    required this.status,
  });

  /// Hay filtros activos, así que una lista vacía significa "sin resultados" y
  /// no "todavía no has creado ninguna rifa".
  bool get isFiltered => search.isNotEmpty || status != 'all';

  @override
  List<Object?> get props => [page, search, status];
}

class RaffleError extends RaffleState {
  final String message;

  const RaffleError({required this.message});

  @override
  List<Object> get props => [message];
}
