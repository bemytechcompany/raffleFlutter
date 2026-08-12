part of 'trash_bloc.dart';

abstract class TrashEvent extends Equatable {
  const TrashEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrash extends TrashEvent {
  /// Página a mostrar. Sin valor conserva la actual.
  final int? page;

  const LoadTrash({this.page});

  @override
  List<Object?> get props => [page];
}

/// Saca la rifa de la papelera y la devuelve al listado.
class RestoreRaffleFromTrash extends TrashEvent {
  final int raffleId;

  const RestoreRaffleFromTrash(this.raffleId);

  @override
  List<Object?> get props => [raffleId];
}

/// Borrado definitivo de una rifa y sus boletos.
class DeleteRaffleForever extends TrashEvent {
  final int raffleId;

  const DeleteRaffleForever(this.raffleId);

  @override
  List<Object?> get props => [raffleId];
}

/// Borrado definitivo de todo lo que haya en la papelera.
class EmptyTrash extends TrashEvent {}

/// Limpia lo que lleve demasiado tiempo en la papelera.
///
/// Se dispara al arrancar la app para que no crezca sin límite.
class PurgeExpiredTrash extends TrashEvent {}
