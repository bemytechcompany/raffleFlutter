import '../entities/participant.dart';

abstract class ParticipantRepository {
  Future<int> addParticipant({
    required int giveawayId,
    required String name,
    required String contact,
  });

  Future<List<Participant>> getParticipants(int giveawayId);

  Future<void> updateParticipant(Participant participant);

  Future<void> deleteParticipant(int participantId);

  Future<void> deleteParticipantsByGiveaway(int giveawayId);

  Future<void> preselectParticipants(
      {required int giveawayId, required int count});

  Future<Participant?> drawWinner(int giveawayId);

  /// Borra ganadores, premios y preselección, y devuelve el sorteo a pendiente.
  /// Los participantes se conservan.
  Future<void> resetDraw(int giveawayId);
}
