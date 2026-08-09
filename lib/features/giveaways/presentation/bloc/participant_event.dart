part of 'participant_bloc.dart';

abstract class ParticipantEvent extends Equatable {
  const ParticipantEvent();

  @override
  List<Object?> get props => [];
}

class LoadParticipants extends ParticipantEvent {
  final int giveawayId;
  const LoadParticipants({required this.giveawayId});

  @override
  List<Object?> get props => [giveawayId];
}

class AddParticipantEvent extends ParticipantEvent {
  final int giveawayId;
  final String name;
  final String contact;

  const AddParticipantEvent({
    required this.giveawayId,
    required this.name,
    required this.contact,
  });

  @override
  List<Object?> get props => [giveawayId, name, contact];
}

class UpdateParticipantEvent extends ParticipantEvent {
  final Participant participant;
  final int giveawayId;

  const UpdateParticipantEvent({
    required this.participant,
    required this.giveawayId,
  });

  @override
  List<Object?> get props => [participant, giveawayId];
}

class DeleteParticipantEvent extends ParticipantEvent {
  final int participantId;
  final int giveawayId;

  const DeleteParticipantEvent({
    required this.participantId,
    required this.giveawayId,
  });

  @override
  List<Object?> get props => [participantId, giveawayId];
}

class DeleteParticipantsByGiveawayEvent extends ParticipantEvent {
  final int giveawayId;

  const DeleteParticipantsByGiveawayEvent({required this.giveawayId});

  @override
  List<Object?> get props => [giveawayId];
}

class PreselectParticipantsEvent extends ParticipantEvent {
  final int giveawayId;
  final int count;

  const PreselectParticipantsEvent({
    required this.giveawayId,
    required this.count,
  });

  @override
  List<Object?> get props => [giveawayId, count];
}

class DrawWinnerEvent extends ParticipantEvent {
  final int giveawayId;

  const DrawWinnerEvent({required this.giveawayId});

  @override
  List<Object?> get props => [giveawayId];
}

/// Deshace el sorteo sin tocar la lista de participantes.
class ResetGiveawayDrawEvent extends ParticipantEvent {
  final int giveawayId;

  const ResetGiveawayDrawEvent({required this.giveawayId});

  @override
  List<Object?> get props => [giveawayId];
}
