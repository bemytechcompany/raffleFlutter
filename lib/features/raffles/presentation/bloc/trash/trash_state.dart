part of 'trash_bloc.dart';

abstract class TrashState extends Equatable {
  const TrashState();

  @override
  List<Object?> get props => [];
}

class TrashLoading extends TrashState {}

class TrashLoaded extends TrashState {
  final Paged<RaffleSummary> page;

  const TrashLoaded(this.page);

  List<RaffleSummary> get summaries => page.items;

  @override
  List<Object?> get props => [page];
}

class TrashError extends TrashState {
  final String message;

  const TrashError(this.message);

  @override
  List<Object?> get props => [message];
}
