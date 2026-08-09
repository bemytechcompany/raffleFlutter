import '../entities/participant.dart';
import '../repositories/participant_repository.dart';

class ParticipantUseCases {
  final ParticipantRepository repository;

  ParticipantUseCases(this.repository);

  Future<int> addParticipant({
    required int giveawayId,
    required String name,
    required String contact,
  }) {
    return repository.addParticipant(
      giveawayId: giveawayId,
      name: name,
      contact: contact,
    );
  }

  Future<List<Participant>> getParticipants(int giveawayId) {
    return repository.getParticipants(giveawayId);
  }

  Future<void> updateParticipant(Participant participant) {
    return repository.updateParticipant(participant);
  }

  Future<void> deleteParticipant(int id) {
    return repository.deleteParticipant(id);
  }

  Future<void> deleteParticipantsByGiveaway(int giveawayId) {
    return repository.deleteParticipantsByGiveaway(giveawayId);
  }

  Future<void> preselectParticipants({
    required int giveawayId,
    required int count,
  }) {
    return repository.preselectParticipants(
      giveawayId: giveawayId,
      count: count,
    );
  }

  Future<Participant?> drawWinner(int giveawayId) {
    return repository.drawWinner(giveawayId);
  }

  Future<void> resetDraw(int giveawayId) {
    return repository.resetDraw(giveawayId);
  }
}
