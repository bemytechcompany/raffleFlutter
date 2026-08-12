part of 'participant_bloc.dart';

abstract class ParticipantState extends Equatable {
  const ParticipantState();

  @override
  List<Object?> get props => [];
}

class ParticipantInitial extends ParticipantState {}

class ParticipantLoading extends ParticipantState {}

class ParticipantLoaded extends ParticipantState {
  final List<Participant> participants;

  const ParticipantLoaded(this.participants);

  @override
  List<Object?> get props => [participants];
}

/// Se acaba de sortear un ganador.
///
/// Extiende [ParticipantLoaded] y trae la lista ya actualizada: así los
/// `BlocBuilder` siguen pintando la lista sin parpadear y los `BlocListener`
/// pueden reaccionar al ganador. Antes era un estado suelto que se emitía y
/// acto seguido quedaba reemplazado por una recarga.
class WinnerSelected extends ParticipantLoaded {
  final Participant winner;

  const WinnerSelected(this.winner, super.participants);

  @override
  List<Object?> get props => [winner, participants];
}

class ParticipantError extends ParticipantState {
  final String message;

  const ParticipantError(this.message);

  @override
  List<Object?> get props => [message];
}
